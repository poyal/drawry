import DrawryCore
import Foundation

// Runnable with Command Line Tools; the XCTest suite is also run on Xcode CI.
let manager = FileManager.default
let root = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try manager.createDirectory(at: root, withIntermediateDirectories: true)
defer { try? manager.removeItem(at: root) }
func expectFailure(_ operation: () throws -> Void) throws {
  do { try operation() } catch { return }
  fatalError("Expected authentication/validation failure")
}
let source = root.appendingPathComponent("plain")
let encrypted = root.appendingPathComponent("cipher")
let restored = root.appendingPathComponent("restored")
let key = Data(repeating: 7, count: 32)
let bytes = Data(repeating: 23, count: ChunkCipher.chunkSize + 137)
try bytes.write(to: source)
try ChunkCipher.encrypt(source: source, destination: encrypted, key: key, context: "test")
try ChunkCipher.decrypt(source: encrypted, destination: restored, key: key, context: "test")
let decrypted = try Data(contentsOf: restored)
precondition(decrypted == bytes)
try expectFailure {
  try ChunkCipher.decrypt(source: encrypted, destination: restored, key: key, context: "bad")
}
precondition(!manager.fileExists(atPath: restored.path))
var truncated = try Data(contentsOf: encrypted)
truncated.removeLast(16)
try truncated.write(to: encrypted)
try expectFailure {
  try ChunkCipher.decrypt(source: encrypted, destination: restored, key: key, context: "test")
}
let mediaDir = root.appendingPathComponent("media")
try manager.createDirectory(at: mediaDir, withIntermediateDirectories: true)
var media = Media()
media.key = key.base64EncodedString()
media.original = "\(media.id).jpg.dry"
media.thumbnail = "\(media.id).thumb.dry"
media.byteLength = 4
media.edit.version = 2
media.edit.strokes = [
  InkStroke(color: "#78658F", points: [InkPoint(x: 0.25, y: 0.25), InkPoint(x: 0.75, y: 0.75)])
]
try Data([1, 2, 3, 4]).write(to: source)
for file in media.files {
  try ChunkCipher.encrypt(
    source: source, destination: mediaDir.appendingPathComponent(file), key: key, context: file)
}
var diary = Diary()
diary.media = [media]
diary.headline = "한글 🌸"
let backup = root.appendingPathComponent("swift.drawry")
let recovery = Data(repeating: 8, count: 32)
try Backup.create(
  snapshot: Snapshot(diaries: [diary], preferences: Preferences()), mediaDirectory: mediaDir,
  destination: backup, password: "테스트 암호1234", recoveryKey: recovery)
let result = try Backup.restore(
  source: backup, staging: root.appendingPathComponent("password"), password: "테스트 암호1234")
precondition(result.diaries == [diary])
let recovered = try Backup.restore(
  source: backup, staging: root.appendingPathComponent("recovery"), recoveryKey: recovery)
precondition(recovered.diaries == [diary])
try expectFailure {
  _ = try Backup.restore(
    source: backup, staging: root.appendingPathComponent("bad"), password: "wrong")
}
if CommandLine.arguments.count > 1 {
  let fixtures = URL(fileURLWithPath: CommandLine.arguments[1])
  let vectorURL = fixtures.deletingLastPathComponent().appendingPathComponent("crypto-v2.json")
  let vector = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: vectorURL))
  func field(_ key: String) -> Data { Data(base64Encoded: vector[key]!)! }
  let derived = try Backup.passwordKey(vector["password"]!, salt: field("salt"))
  precondition(derived == field("derivedKey"))
  let vectorCipher = root.appendingPathComponent("vector.dry")
  let vectorPlain = root.appendingPathComponent("vector.plain")
  try field("encrypted").write(to: vectorCipher)
  try ChunkCipher.decrypt(
    source: vectorCipher, destination: vectorPlain, key: field("mediaKey"),
    context: vector["context"]!)
  let vectorResult = try Data(contentsOf: vectorPlain)
  precondition(vectorResult == field("plaintext"))
  print("Independent PBKDF2 / DRY2 golden vector verified")
  try manager.createDirectory(at: fixtures, withIntermediateDirectories: true)
  let out = fixtures.appendingPathComponent("swift.drawry")
  if manager.fileExists(atPath: out.path) { try manager.removeItem(at: out) }
  try manager.copyItem(at: backup, to: out)
  let kotlin = fixtures.appendingPathComponent("kotlin.drawry")
  if manager.fileExists(atPath: kotlin.path) {
    let cross = try Backup.restore(
      source: kotlin, staging: root.appendingPathComponent("kotlin"), password: "테스트 암호1234")
    precondition(cross.diaries.first?.headline == "한글 🌸")
    precondition(cross.diaries.first?.media.first?.edit.strokes.first?.color == "#78658F")
    precondition(
      cross.diaries.first?.media.first?.edit.strokes.first?.points
        == media.edit.strokes.first?.points)
    print("Kotlin → Swift backup verified")
  }
}
print(
  "Swift core checks passed: multi-chunk, wrong AAD, truncation, password/recovery backup, failed restore cleanup"
)

let legacyJSON = Data(
  #"{"version":1,"quarterTurns":0,"squareCrop":false,"filter":"original","overlays":[]}"#.utf8)
let legacy = try JSONDecoder().decode(EditRecipe.self, from: legacyJSON)
precondition(legacy.strokes.isEmpty)
try legacy.validateInk()
for turns in 0...3 {
  for square in [false, true] {
    let g = InkGeometry(width: 400, height: 300, turns: turns, square: square)
    for p in [InkPoint(x: 0.3, y: 0.3), InkPoint(x: 0.5, y: 0.5), InkPoint(x: 0.7, y: 0.7)] {
      let q = g.unproject(g.project(p))
      precondition(abs(p.x - q.x) < 1e-9 && abs(p.y - q.y) < 1e-9)
    }
  }
}
var invalid = media.edit
invalid.version = 1
try expectFailure { try invalid.validateInk() }
invalid = media.edit
invalid.strokes[0].points = [InkPoint(x: Double.nan, y: 0.5)]
try expectFailure { try invalid.validateInk() }
invalid = media.edit
invalid.strokes[0].points = Array(repeating: InkPoint(x: 0.5, y: 0.5), count: 20_001)
try expectFailure { try invalid.validateInk() }
let g = InkGeometry(width: 400, height: 300, turns: 0, square: false)
precondition(g.hits(media.edit.strokes[0], point: InkPoint(x: 0.5, y: 0.5), tolerance: 12))
print("Ink v1/v2, transforms, crop clipping, eraser and input bounds verified")
