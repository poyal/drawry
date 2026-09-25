import Foundation

public struct Weather: Codable, Equatable, Sendable {
  public var condition = ""
  public var temperature: Double?
  public var minimum: Double?
  public var maximum: Double?
  public var precipitation = false
  public var displayMask = 1
  public init() {}
}

public struct Overlay: Codable, Equatable, Identifiable, Sendable {
  public var id = UUID().uuidString.lowercased()
  public var text = ""
  public var x = 0.5
  public var y = 0.5
  public var size = 0.07
  public var color = "#FFFFFF"
  public init(text: String, x: Double = 0.5, y: Double = 0.5) {
    self.text = text
    self.x = x
    self.y = y
  }
}

public struct EditRecipe: Codable, Equatable, Sendable {
  public var version = 1
  public var quarterTurns = 0
  public var squareCrop = false
  public var filter = "original"
  public var overlays: [Overlay] = []
  public var strokes: [InkStroke] = []
  public init() {}
  enum CodingKeys: String, CodingKey {
    case version, quarterTurns, squareCrop, filter, overlays, strokes
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    version = try c.decode(Int.self, forKey: .version)
    quarterTurns = try c.decode(Int.self, forKey: .quarterTurns)
    squareCrop = try c.decode(Bool.self, forKey: .squareCrop)
    filter = try c.decode(String.self, forKey: .filter)
    overlays = try c.decode([Overlay].self, forKey: .overlays)
    strokes = try c.decodeIfPresent([InkStroke].self, forKey: .strokes) ?? []
  }
}

public struct Media: Codable, Equatable, Identifiable, Sendable {
  public var id = UUID().uuidString.lowercased()
  public var kind = "image"
  public var mimeType = "image/jpeg"
  public var key = ""
  public var original = ""
  public var thumbnail = ""
  public var rendered: String?
  public var byteLength: Int64 = 0
  public var durationMillis: Int64 = 0
  public var representativeMillis: Int64 = 0
  public var edit = EditRecipe()
  public init() {}
  public var files: [String] { [original, thumbnail] + (rendered.map { [$0] } ?? []) }
}

public struct Diary: Codable, Equatable, Identifiable, Sendable {
  public var id = UUID().uuidString.lowercased()
  public var entryDate: String
  public var entryTimeMinutes: Int
  public var utcOffsetMinutes: Int
  public var headline = ""
  public var body = ""
  public var mood = ""
  public var tags: [String] = []
  public var companions: [String] = []
  public var weather = Weather()
  public var media: [Media] = []
  public var createdAt: Int64
  public var updatedAt: Int64
  public var deletedAt: Int64?
  public init(now: Date = Date()) {
    let components = Calendar.current.dateComponents(
      [.year, .month, .day, .hour, .minute], from: now)
    entryDate = String(
      format: "%04d-%02d-%02d", components.year!, components.month!, components.day!)
    entryTimeMinutes = components.hour! * 60 + components.minute!
    utcOffsetMinutes = TimeZone.current.secondsFromGMT(for: now) / 60
    createdAt = Int64(now.timeIntervalSince1970 * 1000)
    updatedAt = createdAt
  }
  public func validate(allowEmpty: Bool = false) throws {
    guard UUID(uuidString: id) != nil,
      entryDate.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil,
      (0..<1440).contains(entryTimeMinutes), (-840...840).contains(utcOffsetMinutes),
      allowEmpty || !media.isEmpty, media.count <= 10,
      Set(media.map(\.id)).count == media.count
    else { throw VaultError.invalidData }
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.isLenient = false
    guard let date = formatter.date(from: entryDate), formatter.string(from: date) == entryDate,
      media.allSatisfy({ (0...300 * 1024 * 1024).contains($0.byteLength) }),
      (0...253_402_300_799_999).contains(createdAt), (0...253_402_300_799_999).contains(updatedAt),
      deletedAt == nil || (0...253_402_300_799_999).contains(deletedAt!)
    else { throw VaultError.invalidData }
    let videos = media.filter { $0.kind == "video" }
    guard videos.count <= 3, videos.allSatisfy({ (1...30_000).contains($0.durationMillis) }),
      videos.reduce(Int64(0), { $0 + $1.durationMillis }) <= 60_000,
      media.reduce(Int64(0), { $0 + $1.byteLength }) <= 300 * 1024 * 1024
    else { throw VaultError.mediaLimit }
    for item in media {
      guard UUID(uuidString: item.id) != nil, ["image", "video"].contains(item.kind),
        Data(base64Encoded: item.key)?.count == 32, item.byteLength >= 0,
        item.files.allSatisfy(Self.safeFilename), (1...2).contains(item.edit.version),
        item.representativeMillis >= 0,
        item.kind != "video" || item.representativeMillis < item.durationMillis,
        (0...3).contains(item.edit.quarterTurns),
        ["original", "mono", "warm", "cool"].contains(item.edit.filter),
        item.edit.overlays.count <= 100,
        item.edit.overlays.allSatisfy({
          (0...1).contains($0.x) && (0...1).contains($0.y) && (0.01...0.5).contains($0.size)
        })
      else { throw VaultError.invalidData }
      try item.edit.validateInk()
    }
  }
  public static func safeFilename(_ name: String) -> Bool {
    name.range(of: #"^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$"#, options: .regularExpression) != nil
      && !name.contains("..")
  }
}

public struct Preferences: Codable, Equatable, Sendable {
  public var onboarded = false
  public var layout = 1
  public var lockEnabled = false
  public var graceSeconds = 0
  public var shareRatio = "4:5"
  public var shareTheme = "light"
  public var shareFields = ["headline", "body", "date", "mood", "weather"]
  public var watermark = true
  public init() {}
  public func validate() throws {
    guard (1...3).contains(layout), [0, 30, 60, 300, 900, 1800].contains(graceSeconds),
      ["4:5", "1:1", "9:16"].contains(shareRatio), ["light", "dark"].contains(shareTheme),
      Set(shareFields).count == shareFields.count,
      shareFields.allSatisfy({ ["headline", "body", "date", "mood", "weather"].contains($0) })
    else { throw VaultError.invalidData }
  }
}

public struct Snapshot: Codable, Sendable {
  public var version = 2
  public var createdAt = Int64(Date().timeIntervalSince1970 * 1000)
  public var diaries: [Diary]
  public var preferences: Preferences
  public init(diaries: [Diary], preferences: Preferences) {
    self.diaries = diaries
    self.preferences = preferences
  }
  public func validate() throws {
    guard version == 2, diaries.count <= 100_000, Set(diaries.map(\.id)).count == diaries.count
    else { throw VaultError.invalidData }
    try preferences.validate()
    for diary in diaries { try diary.validate() }
    let files = diaries.flatMap { $0.media.flatMap(\.files) }
    guard Set(files).count == files.count else { throw VaultError.invalidData }
  }
}

public enum VaultError: Error, LocalizedError {
  case invalidData, authentication, mediaLimit, unsupported, insufficientSpace
  public var errorDescription: String? {
    switch self {
    case .invalidData: return "파일 또는 기록 형식이 올바르지 않습니다."
    case .authentication: return "암호·복구 키가 올바르지 않거나 파일이 손상되었습니다."
    case .mediaLimit: return "미디어는 10개·300MB, 영상은 3개·각 30초·합계 60초까지 가능합니다."
    case .unsupported: return "지원하지 않는 파일 또는 버전입니다."
    case .insufficientSpace: return "저장 공간이 부족합니다."
    }
  }
}
