import CryptoKit
import Foundation
import Security

/// DRY2: authenticated header, bounded records and an authenticated end record.
public enum ChunkCipher {
  public static let chunkSize = 4 * 1024 * 1024
  public static func random(_ count: Int) throws -> Data {
    var data = Data(count: count)
    guard
      data.withUnsafeMutableBytes({ SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!) })
        == errSecSuccess
    else { throw VaultError.authentication }
    return data
  }
  public static func encrypt(source: URL, destination: URL, key: Data, context: String) throws {
    let input = try FileHandle(forReadingFrom: source)
    defer { try? input.close() }
    let length = try input.seekToEnd()
    try input.seek(toOffset: 0)
    let prefix = try random(8)
    let header = Data("DRY2".utf8) + uint32(UInt32(chunkSize)) + uint64(length) + prefix
    try encrypt(
      length: length, destination: destination, key: key, context: context, header: header
    ) { count in
      try input.readExactly(count)
    }
  }
  public static func encrypt(
    length: UInt64, destination: URL, key: Data, context: String,
    header: Data? = nil, read: (Int) throws -> Data
  ) throws {
    guard key.count == 32, length < UInt64(chunkSize) * UInt64(UInt32.max) else {
      throw VaultError.invalidData
    }
    let h =
      try header ?? (Data("DRY2".utf8) + uint32(UInt32(chunkSize)) + uint64(length) + random(8))
    FileManager.default.createFile(atPath: destination.path, contents: nil)
    let output = try FileHandle(forWritingTo: destination)
    var success = false
    defer {
      try? output.close()
      if !success { try? FileManager.default.removeItem(at: destination) }
    }
    try output.write(contentsOf: h)
    var remaining = length
    var index: UInt32 = 0
    repeat {
      try Task.checkCancellation()
      let count = Int(min(UInt64(chunkSize), remaining))
      let plain = count == 0 ? Data() : try read(count)
      guard plain.count == count else { throw VaultError.invalidData }
      let nonce = try AES.GCM.Nonce(data: h.suffix(8) + uint32(index))
      let box = try AES.GCM.seal(
        plain, using: SymmetricKey(data: key), nonce: nonce,
        authenticating: h + Data(context.utf8) + uint32(index))
      try output.write(contentsOf: box.ciphertext + box.tag)
      if count == 0 { break }
      remaining -= UInt64(count)
      index += 1
    } while true
    try output.synchronize()
    success = true
  }
  public static func decrypt(source: URL, destination: URL, key: Data, context: String) throws {
    FileManager.default.createFile(atPath: destination.path, contents: nil)
    let output = try FileHandle(forWritingTo: destination)
    var success = false
    defer {
      try? output.close()
      if !success { try? FileManager.default.removeItem(at: destination) }
    }
    try decrypt(source: source, key: key, context: context) { try output.write(contentsOf: $0) }
    try output.synchronize()
    success = true
  }
  public static func decrypt(source: URL, key: Data, context: String, write: (Data) throws -> Void)
    throws
  {
    guard key.count == 32 else { throw VaultError.authentication }
    let input = try FileHandle(forReadingFrom: source)
    defer { try? input.close() }
    let h = try input.readExactly(24)
    guard h.prefix(4) == Data("DRY2".utf8), readUInt(h[4..<8]) == chunkSize else {
      throw VaultError.unsupported
    }
    var remaining = readUInt(h[8..<16])
    var index: UInt32 = 0
    guard remaining < UInt64(chunkSize) * UInt64(UInt32.max) else { throw VaultError.invalidData }
    repeat {
      try Task.checkCancellation()
      let count = Int(min(UInt64(chunkSize), remaining))
      let encrypted = try input.readExactly(count + 16)
      let box = try AES.GCM.SealedBox(
        nonce: AES.GCM.Nonce(data: h.suffix(8) + uint32(index)),
        ciphertext: encrypted.prefix(count), tag: encrypted.suffix(16))
      let plain: Data
      do {
        plain = try AES.GCM.open(
          box, using: SymmetricKey(data: key),
          authenticating: h + Data(context.utf8) + uint32(index))
      } catch { throw VaultError.authentication }
      if count == 0 { break }
      try write(plain)
      remaining -= UInt64(count)
      index += 1
    } while true
    guard try input.read(upToCount: 1)?.isEmpty != false else { throw VaultError.invalidData }
  }
  public static func uint32(_ n: UInt32) -> Data { withUnsafeBytes(of: n.bigEndian) { Data($0) } }
  public static func uint64(_ n: UInt64) -> Data { withUnsafeBytes(of: n.bigEndian) { Data($0) } }
  public static func readUInt(_ bytes: Data) -> UInt64 {
    bytes.reduce(0) { ($0 << 8) | UInt64($1) }
  }
}

extension FileHandle {
  public func readExactly(_ count: Int) throws -> Data {
    var data = Data()
    while data.count < count {
      guard let part = try read(upToCount: count - data.count), !part.isEmpty else {
        throw VaultError.invalidData
      }
      data.append(part)
    }
    return data
  }
}
