import CommonCrypto
import CryptoKit
import Foundation

public struct BackupHeader: Codable {
  public var version: Int
  public var iterations: Int
  public var salt: String
  public var passwordWrap: String
  public var recoveryWrap: String
}
public struct BackupFile: Codable {
  public var name: String
  public var length: UInt64
  public var sha256: String
}
public struct BackupManifest: Codable {
  public var snapshot: Snapshot
  public var files: [BackupFile]
}

public enum Backup {
  public static let iterations = 210_000
  public static func passwordKey(_ password: String, salt: Data) throws -> Data {
    let bytes = Array(password.utf8)
    var result = Data(count: 32)
    let status = result.withUnsafeMutableBytes { out in
      salt.withUnsafeBytes { s in
        bytes.withUnsafeBytes { p in
          CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2), p.baseAddress!.assumingMemoryBound(to: Int8.self),
            bytes.count,
            s.baseAddress!.assumingMemoryBound(to: UInt8.self), salt.count,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
            UInt32(iterations), out.baseAddress!.assumingMemoryBound(to: UInt8.self), 32)
        }
      }
    }
    guard status == kCCSuccess else { throw VaultError.authentication }
    return result
  }
  private static func wrap(_ key: Data, with wrappingKey: Data, label: String) throws -> String {
    try AES.GCM.seal(key, using: SymmetricKey(data: wrappingKey), authenticating: Data(label.utf8))
      .combined!.base64EncodedString()
  }
  private static func unwrap(_ text: String, with key: Data, label: String) throws -> Data {
    guard let data = Data(base64Encoded: text), data.count == 60 else {
      throw VaultError.authentication
    }
    do {
      return try AES.GCM.open(
        AES.GCM.SealedBox(combined: data), using: SymmetricKey(data: key),
        authenticating: Data(label.utf8))
    } catch { throw VaultError.authentication }
  }
  public static func digest(_ url: URL) throws -> String {
    let file = try FileHandle(forReadingFrom: url)
    defer { try? file.close() }
    var hash = SHA256()
    while let data = try file.read(upToCount: 1 << 20), !data.isEmpty { hash.update(data: data) }
    return hash.finalize().map { String(format: "%02x", $0) }.joined()
  }
  public static func create(
    snapshot: Snapshot, mediaDirectory: URL, destination: URL, password: String, recoveryKey: Data
  ) throws {
    guard password.unicodeScalars.count >= 8, recoveryKey.count == 32 else {
      throw VaultError.invalidData
    }
    try snapshot.validate()
    let salt = try ChunkCipher.random(16)
    let dataKey = try ChunkCipher.random(32)
    let header = BackupHeader(
      version: 2, iterations: iterations, salt: salt.base64EncodedString(),
      passwordWrap: try wrap(
        dataKey, with: passwordKey(password, salt: salt), label: "drawry-password-v2"),
      recoveryWrap: try wrap(dataKey, with: recoveryKey, label: "drawry-recovery-v2"))
    let encodedHeader = try JSONEncoder().encode(header)
    let files = try snapshot.diaries.flatMap { $0.media.flatMap(\.files) }.sorted().map {
      name -> BackupFile in
      let url = mediaDirectory.appendingPathComponent(name)
      let length = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize!
      return BackupFile(name: name, length: UInt64(length), sha256: try digest(url))
    }
    let manifest = try JSONEncoder().encode(BackupManifest(snapshot: snapshot, files: files))
    guard manifest.count <= 32 * 1024 * 1024 else { throw VaultError.invalidData }
    let prefix = ChunkCipher.uint32(UInt32(manifest.count)) + manifest
    let reader = SegmentReader(
      prefix: prefix, files: files.map { mediaDirectory.appendingPathComponent($0.name) })
    let temporary = destination.appendingPathExtension("payload")
    defer { try? FileManager.default.removeItem(at: temporary) }
    let context = SHA256.hash(data: encodedHeader).map { String(format: "%02x", $0) }.joined()
    try ChunkCipher.encrypt(
      length: UInt64(prefix.count) + files.reduce(0) { $0 + $1.length },
      destination: temporary, key: dataKey, context: context, read: reader.read)
    FileManager.default.createFile(atPath: destination.path, contents: nil)
    let out = try FileHandle(forWritingTo: destination)
    var success = false
    defer {
      try? out.close()
      if !success { try? FileManager.default.removeItem(at: destination) }
    }
    try out.write(
      contentsOf: Data("DRBK2".utf8) + ChunkCipher.uint32(UInt32(encodedHeader.count))
        + encodedHeader)
    let input = try FileHandle(forReadingFrom: temporary)
    defer { try? input.close() }
    while let bytes = try input.read(upToCount: 1 << 20), !bytes.isEmpty {
      try out.write(contentsOf: bytes)
    }
    try out.synchronize()
    success = true
  }
  /// Returns verified metadata; writes only encrypted media into a new staging directory.
  public static func restore(
    source: URL, staging: URL, password: String? = nil, recoveryKey: Data? = nil
  ) throws -> Snapshot {
    guard !FileManager.default.fileExists(atPath: staging.path) else {
      throw VaultError.invalidData
    }
    try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
    var success = false
    defer { if !success { try? FileManager.default.removeItem(at: staging) } }
    let input = try FileHandle(forReadingFrom: source)
    defer { try? input.close() }
    guard try input.readExactly(5) == Data("DRBK2".utf8) else { throw VaultError.unsupported }
    let length = Int(ChunkCipher.readUInt(try input.readExactly(4)))
    guard (1...65536).contains(length) else { throw VaultError.invalidData }
    let bytes = try input.readExactly(length)
    let header = try JSONDecoder().decode(BackupHeader.self, from: bytes)
    guard header.version == 2, header.iterations == iterations,
      let salt = Data(base64Encoded: header.salt), salt.count == 16
    else { throw VaultError.unsupported }
    let dataKey: Data
    if let password, !password.isEmpty {
      dataKey = try unwrap(
        header.passwordWrap, with: passwordKey(password, salt: salt), label: "drawry-password-v2")
    } else if let recoveryKey, recoveryKey.count == 32 {
      dataKey = try unwrap(header.recoveryWrap, with: recoveryKey, label: "drawry-recovery-v2")
    } else {
      throw VaultError.authentication
    }
    let payload = staging.appendingPathComponent("payload.tmp")
    FileManager.default.createFile(atPath: payload.path, contents: nil)
    let output = try FileHandle(forWritingTo: payload)
    do {
      while let part = try input.read(upToCount: 1 << 20), !part.isEmpty {
        try output.write(contentsOf: part)
      }
      try output.close()
    } catch {
      try? output.close()
      throw error
    }
    let receiver = PayloadReceiver(directory: staging)
    let context = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    try ChunkCipher.decrypt(source: payload, key: dataKey, context: context, write: receiver.accept)
    let snapshot = try receiver.finish()
    try FileManager.default.removeItem(at: payload)
    // A valid archive must also contain valid media AEAD records, not merely matching checksums.
    for media in snapshot.diaries.flatMap(\.media) {
      for file in media.files {
        try ChunkCipher.decrypt(
          source: staging.appendingPathComponent(file), key: Data(base64Encoded: media.key)!,
          context: file
        ) { _ in }
      }
    }
    success = true
    return snapshot
  }
}

private final class SegmentReader {
  var prefix: Data
  var files: [URL]
  var handle: FileHandle?
  init(prefix: Data, files: [URL]) {
    self.prefix = prefix
    self.files = files
  }
  deinit { try? handle?.close() }
  func read(_ count: Int) throws -> Data {
    var result = Data()
    if !prefix.isEmpty {
      let n = min(count, prefix.count)
      result.append(prefix.prefix(n))
      prefix.removeFirst(n)
    }
    while result.count < count {
      if handle == nil {
        guard !files.isEmpty else { throw VaultError.invalidData }
        handle = try FileHandle(forReadingFrom: files.removeFirst())
      }
      let part = try handle!.read(upToCount: count - result.count) ?? Data()
      if part.isEmpty {
        try handle?.close()
        handle = nil
      } else {
        result.append(part)
      }
    }
    return result
  }
}

private final class PayloadReceiver {
  let directory: URL
  var buffer = Data()
  var manifestLength: Int?
  var manifest: BackupManifest?
  var index = 0
  var written: UInt64 = 0
  var output: FileHandle?
  init(directory: URL) { self.directory = directory }
  deinit { try? output?.close() }
  func accept(_ data: Data) throws {
    buffer.append(data)
    if manifestLength == nil, buffer.count >= 4 {
      let n = Int(ChunkCipher.readUInt(Data(buffer.prefix(4))))
      guard (1...32 * 1024 * 1024).contains(n) else { throw VaultError.invalidData }
      manifestLength = n
      buffer.removeFirst(4)
    }
    if manifest == nil, let n = manifestLength, buffer.count >= n {
      let m = try JSONDecoder().decode(BackupManifest.self, from: Data(buffer.prefix(n)))
      try m.snapshot.validate()
      let names = m.snapshot.diaries.flatMap { $0.media.flatMap(\.files) }.sorted()
      guard names == m.files.map(\.name),
        m.files.allSatisfy({ $0.length <= 512 * 1024 * 1024 && $0.length >= 40 })
      else { throw VaultError.invalidData }
      manifest = m
      buffer.removeFirst(n)
    }
    guard let manifest else { return }
    while index < manifest.files.count, !buffer.isEmpty {
      let file = manifest.files[index]
      if output == nil {
        let url = directory.appendingPathComponent(file.name)
        FileManager.default.createFile(atPath: url.path, contents: nil)
        output = try FileHandle(forWritingTo: url)
      }
      let n = Int(min(UInt64(buffer.count), file.length - written))
      try output!.write(contentsOf: buffer.prefix(n))
      buffer.removeFirst(n)
      written += UInt64(n)
      if written == file.length {
        try output?.close()
        output = nil
        guard try Backup.digest(directory.appendingPathComponent(file.name)) == file.sha256 else {
          throw VaultError.authentication
        }
        index += 1
        written = 0
      }
    }
  }
  func finish() throws -> Snapshot {
    guard let manifest, index == manifest.files.count, written == 0, buffer.isEmpty else {
      throw VaultError.invalidData
    }
    return manifest.snapshot
  }
}
