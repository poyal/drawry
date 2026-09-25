import DrawryCore
import Foundation
import SQLCipher
import Security

final class SecureKeys {
  private let service = "com.poyal.drawry.native.v2"
  func get(_ name: String, databaseExists: Bool = false) throws -> Data {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
      kSecAttrAccount as String: name,
    ]
    var read = query
    read[kSecReturnData as String] = true
    var result: CFTypeRef?
    let status = SecItemCopyMatching(read as CFDictionary, &result)
    if status == errSecSuccess, let data = result as? Data, data.count == 32 { return data }
    guard status == errSecItemNotFound, !databaseExists else { throw VaultError.authentication }
    let key = try ChunkCipher.random(32)
    var insert = query
    insert[kSecValueData as String] = key
    insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else {
      throw VaultError.authentication
    }
    return key
  }
  func destroy() throws {
    let status = SecItemDelete(
      [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
        as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw VaultError.authentication
    }
  }
}

actor Vault {
  let root: URL
  let cache: URL
  let keys = SecureKeys()
  private var database: OpaquePointer?
  private var generation = "media-initial"
  var mediaDirectory: URL { root.appendingPathComponent(generation) }
  init() throws {
    let fm = FileManager.default
    root = try fm.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("native-v2")
    cache = fm.temporaryDirectory.appendingPathComponent("drawry-private")
    for url in try fm.contentsOfDirectory(
      at: fm.temporaryDirectory, includingPropertiesForKeys: nil)
    where url.lastPathComponent.hasPrefix("picker-") || url.lastPathComponent.hasPrefix("camera-") {
      try? fm.removeItem(at: url)
    }
    try fm.createDirectory(at: root, withIntermediateDirectories: true)
    try? fm.removeItem(at: cache)
    try fm.createDirectory(at: cache, withIntermediateDirectories: true)
    var excluded = root
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try excluded.setResourceValues(values)
    try fm.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: root.path)
    let db = root.appendingPathComponent("drawry.db")
    let key = try keys.get("database", databaseExists: fm.fileExists(atPath: db.path))
    guard sqlite3_open(db.path, &database) == SQLITE_OK else { throw VaultError.invalidData }
    let hex = key.map { String(format: "%02x", $0) }.joined()
    guard
      sqlite3_exec(
        database,
        "PRAGMA key = \"x'\(hex)'\"; PRAGMA cipher_memory_security=ON; PRAGMA secure_delete=ON; PRAGMA journal_mode=WAL; CREATE TABLE IF NOT EXISTS records (id TEXT PRIMARY KEY, kind TEXT NOT NULL, payload TEXT NOT NULL);",
        nil, nil, nil) == SQLITE_OK
    else {
      sqlite3_close(database)
      throw VaultError.authentication
    }
  }
  func initialize() throws {
    guard try !query("PRAGMA cipher_version").isEmpty else { throw VaultError.authentication }
    if let stored = try get("generation") {
      guard Diary.safeFilename(stored), stored.hasPrefix("media-") else {
        throw VaultError.invalidData
      }
      generation = stored
    }
    try FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
    for url in try FileManager.default.contentsOfDirectory(
      at: root, includingPropertiesForKeys: nil)
    {
      if (url.lastPathComponent.hasPrefix("media-") && url != mediaDirectory)
        || url.lastPathComponent.hasPrefix("restore-")
      {
        try? FileManager.default.removeItem(at: url)
      }
    }
    try purgeExpired()
    try collectOrphans()
  }
  private func execute(_ sql: String, _ parameters: [String] = []) throws {
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
      throw VaultError.invalidData
    }
    defer { sqlite3_finalize(statement) }
    let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    for (i, value) in parameters.enumerated() {
      sqlite3_bind_text(statement, Int32(i + 1), value, -1, transient)
    }
    guard sqlite3_step(statement) == SQLITE_DONE else { throw VaultError.invalidData }
  }
  private func query(_ sql: String, _ parameters: [String] = []) throws -> [String] {
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
      throw VaultError.invalidData
    }
    defer { sqlite3_finalize(statement) }
    let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    for (i, value) in parameters.enumerated() {
      sqlite3_bind_text(statement, Int32(i + 1), value, -1, transient)
    }
    var rows: [String] = []
    while true {
      let status = sqlite3_step(statement)
      if status == SQLITE_DONE { return rows }
      guard status == SQLITE_ROW, let text = sqlite3_column_text(statement, 0) else {
        throw VaultError.invalidData
      }
      rows.append(String(cString: text))
    }
  }
  private func get(_ id: String) throws -> String? {
    try query("SELECT payload FROM records WHERE id=?", [id]).first
  }
  private func put<T: Encodable>(_ id: String, kind: String, value: T) throws {
    let json = String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
    try execute("INSERT OR REPLACE INTO records VALUES (?,?,?)", [id, kind, json])
  }
  private func transaction(_ body: () throws -> Void) throws {
    try execute("BEGIN IMMEDIATE")
    do {
      try body()
      try execute("COMMIT")
    } catch {
      try? execute("ROLLBACK")
      throw error
    }
  }
  func diaries() throws -> [Diary] {
    try query("SELECT payload FROM records WHERE kind='diary'").map {
      try JSONDecoder().decode(Diary.self, from: Data($0.utf8))
    }
    .sorted { ($0.entryDate, $0.entryTimeMinutes) > ($1.entryDate, $1.entryTimeMinutes) }
  }
  func preferences() throws -> Preferences {
    try get("preferences").map { try JSONDecoder().decode(Preferences.self, from: Data($0.utf8)) }
      ?? Preferences()
  }
  func preferences(_ value: Preferences) throws {
    try value.validate()
    try put("preferences", kind: "setting", value: value)
  }
  func draft() throws -> Diary? {
    try get("draft").map { try JSONDecoder().decode(Diary.self, from: Data($0.utf8)) }
  }
  func draft(_ value: Diary?) throws {
    if let value {
      try value.validate(allowEmpty: true)
      try put("draft", kind: "draft", value: value)
    } else {
      try execute("DELETE FROM records WHERE id='draft'")
      try collectOrphans()
    }
  }
  func save(_ diary: Diary) throws {
    try diary.validate()
    guard
      diary.media.flatMap(\.files).allSatisfy({
        FileManager.default.fileExists(atPath: mediaDirectory.appendingPathComponent($0).path)
      })
    else { throw VaultError.invalidData }
    var updated = diary
    updated.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
    try transaction {
      try put(updated.id, kind: "diary", value: updated)
      try execute("DELETE FROM records WHERE id='draft'")
    }
    try collectOrphans()
  }
  func trash(_ diary: Diary, restore: Bool = false) throws {
    var value = diary
    value.deletedAt = restore ? nil : Int64(Date().timeIntervalSince1970 * 1000)
    value.updatedAt = Int64(Date().timeIntervalSince1970 * 1000)
    try put(value.id, kind: "diary", value: value)
  }
  func purge(_ id: String) throws {
    if try draft()?.id == id { try execute("DELETE FROM records WHERE id='draft'") }
    try execute("DELETE FROM records WHERE id=?", [id])
    try collectOrphans()
    _ = try query("PRAGMA wal_checkpoint(TRUNCATE)")
  }
  func purgeExpired() throws {
    let expired = try diaries().filter {
      ($0.deletedAt ?? Int64.max) <= Int64(Date().timeIntervalSince1970 * 1000) - 30 * 86400_000
    }
    for diary in expired { try purge(diary.id) }
  }
  func collectOrphans() throws {
    var records = try diaries()
    if let draft = try draft() { records.append(draft) }
    let keep = Set(records.flatMap { $0.media.flatMap(\.files) })
    for file in try FileManager.default.contentsOfDirectory(
      at: mediaDirectory, includingPropertiesForKeys: nil)
    where !keep.contains(file.lastPathComponent) { try? FileManager.default.removeItem(at: file) }
  }
  func export(password: String) throws -> URL {
    let url = cache.appendingPathComponent("Drawry-\(Int(Date().timeIntervalSince1970)).drawry")
    var prefs = try preferences()
    prefs.lockEnabled = false
    prefs.graceSeconds = 0
    try Backup.create(
      snapshot: Snapshot(diaries: diaries(), preferences: prefs), mediaDirectory: mediaDirectory,
      destination: url, password: password, recoveryKey: keys.get("recovery"))
    return url
  }
  func recoveryCode() throws -> String { try keys.get("recovery").base64EncodedString() }
  func inspect(source: URL, password: String?, recovery: Data?) throws -> (Snapshot, URL) {
    let stage = root.appendingPathComponent("restore-\(UUID().uuidString)")
    return (
      try Backup.restore(source: source, staging: stage, password: password, recoveryKey: recovery),
      stage
    )
  }
  func restore(snapshot: Snapshot, stage: URL, replace: Bool) throws {
    let old = mediaDirectory
    let fm = FileManager.default
    let existing = replace ? [] : try diaries()
    let ids = Set(existing.map(\.id))
    let incoming = snapshot.diaries.filter { !ids.contains($0.id) }
    let all = existing + incoming
    try Snapshot(diaries: all, preferences: snapshot.preferences).validate()
    let name = "media-\(UUID().uuidString)"
    let next = root.appendingPathComponent(name)
    try fm.createDirectory(at: next, withIntermediateDirectories: true)
    var committed = false
    defer {
      if !committed { try? fm.removeItem(at: next) }
      try? fm.removeItem(at: stage)
    }
    for file in existing.flatMap({ $0.media.flatMap(\.files) }) {
      try fm.copyItem(at: old.appendingPathComponent(file), to: next.appendingPathComponent(file))
    }
    for file in incoming.flatMap({ $0.media.flatMap(\.files) }) {
      try fm.copyItem(at: stage.appendingPathComponent(file), to: next.appendingPathComponent(file))
    }
    let current = try preferences()
    var prefs = replace ? snapshot.preferences : current
    prefs.onboarded = true
    prefs.lockEnabled = current.lockEnabled
    prefs.graceSeconds = current.graceSeconds
    try transaction {
      try execute("DELETE FROM records WHERE kind IN ('diary','draft')")
      for diary in all { try put(diary.id, kind: "diary", value: diary) }
      try execute("INSERT OR REPLACE INTO records VALUES ('generation','setting',?)", [name])
      try preferences(prefs)
    }
    committed = true
    generation = name
    try? fm.removeItem(at: old)
    try purgeExpired()
  }
  func clearCache() {
    for file
      in (try? FileManager.default.contentsOfDirectory(at: cache, includingPropertiesForKeys: nil))
      ?? []
    { try? FileManager.default.removeItem(at: file) }
  }
  func erase() throws {
    sqlite3_close(database)
    database = nil
    try keys.destroy()
    try FileManager.default.removeItem(at: root)
    clearCache()
  }
}
