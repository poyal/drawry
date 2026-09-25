import XCTest

@testable import DrawryCore

final class CoreTests: XCTestCase {
  func testInkLegacyAndGeometry() throws {
    let json = Data(
      #"{"version":1,"quarterTurns":0,"squareCrop":false,"filter":"original","overlays":[]}"#.utf8)
    XCTAssertTrue(try JSONDecoder().decode(EditRecipe.self, from: json).strokes.isEmpty)
    var recipe = EditRecipe()
    recipe.version = 2
    recipe.strokes = [InkStroke(points: [InkPoint(x: 0.25, y: 0.25), InkPoint(x: 0.75, y: 0.75)])]
    try recipe.validateInk()
    XCTAssertEqual(
      try JSONDecoder().decode(EditRecipe.self, from: JSONEncoder().encode(recipe)), recipe)
    for turns in 0...3 {
      for square in [false, true] {
        let g = InkGeometry(width: 400, height: 300, turns: turns, square: square)
        let p = InkPoint(x: 0.3, y: 0.3)
        let q = g.unproject(g.project(InkPoint(x: 0.3, y: 0.3)))
        XCTAssertEqual(p.x, q.x, accuracy: 1e-9)
        XCTAssertEqual(p.y, q.y, accuracy: 1e-9)
      }
    }
    recipe.version = 1
    XCTAssertThrowsError(try recipe.validateInk())
    recipe.version = 2
    recipe.strokes[0].width = Double.nan
    XCTAssertThrowsError(try recipe.validateInk())
  }
  func temporary() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    addTeardownBlock { try? FileManager.default.removeItem(at: url) }
    return url
  }
  func testChunkAuthenticationAndCleanup() throws {
    let dir = try temporary()
    let key = Data(repeating: 7, count: 32)
    let plain = dir.appendingPathComponent("plain")
    let encrypted = dir.appendingPathComponent("cipher")
    let restored = dir.appendingPathComponent("restored")
    let bytes = Data(repeating: 23, count: ChunkCipher.chunkSize + 137)
    try bytes.write(to: plain)
    try ChunkCipher.encrypt(source: plain, destination: encrypted, key: key, context: "test")
    try ChunkCipher.decrypt(source: encrypted, destination: restored, key: key, context: "test")
    XCTAssertEqual(try Data(contentsOf: restored), bytes)
    XCTAssertThrowsError(
      try ChunkCipher.decrypt(source: encrypted, destination: restored, key: key, context: "wrong"))
    XCTAssertFalse(FileManager.default.fileExists(atPath: restored.path))
    var corrupt = try Data(contentsOf: encrypted)
    corrupt.removeLast(16)
    try corrupt.write(to: encrypted)
    XCTAssertThrowsError(
      try ChunkCipher.decrypt(source: encrypted, destination: restored, key: key, context: "test"))
    XCTAssertFalse(FileManager.default.fileExists(atPath: restored.path))
  }
  func testBackupPasswordRecoveryAndTamper() throws {
    let dir = try temporary()
    let mediaDir = dir.appendingPathComponent("media")
    try FileManager.default.createDirectory(at: mediaDir, withIntermediateDirectories: true)
    var media = Media()
    media.key = Data(repeating: 9, count: 32).base64EncodedString()
    media.original = "\(media.id).jpg.dry"
    media.thumbnail = "\(media.id).thumb.dry"
    media.byteLength = 4
    let plain = dir.appendingPathComponent("plain")
    try Data([1, 2, 3, 4]).write(to: plain)
    for name in media.files {
      try ChunkCipher.encrypt(
        source: plain, destination: mediaDir.appendingPathComponent(name),
        key: Data(base64Encoded: media.key)!, context: name)
    }
    var diary = Diary()
    diary.media = [media]
    diary.headline = "한글 🌸"
    let backup = dir.appendingPathComponent("test.drawry")
    let recovery = Data(repeating: 8, count: 32)
    try Backup.create(
      snapshot: Snapshot(diaries: [diary], preferences: Preferences()), mediaDirectory: mediaDir,
      destination: backup, password: "테스트 암호1234", recoveryKey: recovery)
    let restored = try Backup.restore(
      source: backup, staging: dir.appendingPathComponent("restore"), password: "테스트 암호1234")
    XCTAssertEqual(restored.diaries, [diary])
    XCTAssertEqual(
      try Backup.restore(
        source: backup, staging: dir.appendingPathComponent("recovery"), recoveryKey: recovery
      ).diaries, [diary])
    XCTAssertThrowsError(
      try Backup.restore(
        source: backup, staging: dir.appendingPathComponent("bad"), password: "wrong"))
    XCTAssertFalse(FileManager.default.fileExists(atPath: dir.appendingPathComponent("bad").path))
    if let export = ProcessInfo.processInfo.environment["DRAWRY_FIXTURES"] {
      try FileManager.default.copyItem(
        at: backup, to: URL(fileURLWithPath: export).appendingPathComponent("swift.drawry"))
    }
  }
  func testReadKotlinBackup() throws {
    guard let path = ProcessInfo.processInfo.environment["DRAWRY_KOTLIN_BACKUP"] else {
      throw XCTSkip("Cross-language fixture not supplied")
    }
    let dir = try temporary()
    let snapshot = try Backup.restore(
      source: URL(fileURLWithPath: path), staging: dir.appendingPathComponent("kotlin"),
      password: "테스트 암호1234")
    XCTAssertEqual(snapshot.diaries.first?.headline, "한글 🌸")
  }
  func testLimitsAndUnsafePaths() throws {
    var diary = Diary()
    XCTAssertThrowsError(try diary.validate())
    XCTAssertNoThrow(try diary.validate(allowEmpty: true))
    XCTAssertFalse(Diary.safeFilename("../secret"))
    XCTAssertFalse(Diary.safeFilename("/tmp/file"))
    diary.entryTimeMinutes = 1440
    XCTAssertThrowsError(try diary.validate(allowEmpty: true))
  }
}
