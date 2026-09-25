import Foundation

public struct InkPoint: Codable, Equatable, Sendable {
  public var x: Double
  public var y: Double
  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
}
public struct InkStroke: Codable, Equatable, Identifiable, Sendable {
  public var id = UUID().uuidString.lowercased()
  public var color = "#302C29"
  public var width = 0.006
  public var points: [InkPoint] = []
  public init(color: String = "#302C29", width: Double = 0.006, points: [InkPoint] = []) {
    self.color = color
    self.width = width
    self.points = points
  }
}
public let maxInkStrokes = 256
public let maxInkPoints = 20_000
extension EditRecipe {
  public func validateInk() throws {
    guard (1...2).contains(version), version == 2 || strokes.isEmpty,
      strokes.count <= maxInkStrokes, strokes.reduce(0, { $0 + $1.points.count }) <= maxInkPoints,
      Set(strokes.map(\.id)).count == strokes.count
    else { throw VaultError.invalidData }
    for stroke in strokes {
      guard UUID(uuidString: stroke.id) != nil,
        stroke.color.range(of: #"^#[0-9A-Fa-f]{6}$"#, options: .regularExpression) != nil,
        stroke.width.isFinite, (0.001...0.05).contains(stroke.width), !stroke.points.isEmpty,
        stroke.points.allSatisfy({
          $0.x.isFinite && $0.y.isFinite && (0...1).contains($0.x) && (0...1).contains($0.y)
        })
      else { throw VaultError.invalidData }
    }
  }
}
public struct InkGeometry: Sendable {
  public let sourceWidth: Double, sourceHeight: Double, turns: Int
  public let width: Double, height: Double, shortSide: Double
  private let dx: Double, dy: Double
  public init(width w: Double, height h: Double, turns: Int, square: Bool) {
    precondition(w > 0 && h > 0 && (0...3).contains(turns))
    sourceWidth = w
    sourceHeight = h
    self.turns = turns
    shortSide = min(w, h)
    let rw = turns % 2 == 0 ? w : h
    let rh = turns % 2 == 0 ? h : w
    width = square ? min(rw, rh) : rw
    height = square ? min(rw, rh) : rh
    dx = (rw - width) / 2
    dy = (rh - height) / 2
  }
  public func project(_ p: InkPoint) -> InkPoint {
    let x = p.x * sourceWidth
    let y = p.y * sourceHeight
    let q: InkPoint
    switch turns {
    case 1: q = InkPoint(x: sourceHeight - y, y: x)
    case 2: q = InkPoint(x: sourceWidth - x, y: sourceHeight - y)
    case 3: q = InkPoint(x: y, y: sourceWidth - x)
    default: q = InkPoint(x: x, y: y)
    }
    return InkPoint(x: (q.x - dx) / width, y: (q.y - dy) / height)
  }
  public func unproject(_ p: InkPoint) -> InkPoint {
    let x = min(1, max(0, p.x)) * width + dx
    let y = min(1, max(0, p.y)) * height + dy
    let q: InkPoint
    switch turns {
    case 1: q = InkPoint(x: y, y: sourceHeight - x)
    case 2: q = InkPoint(x: sourceWidth - x, y: sourceHeight - y)
    case 3: q = InkPoint(x: sourceWidth - y, y: x)
    default: q = InkPoint(x: x, y: y)
    }
    return InkPoint(x: min(1, max(0, q.x / sourceWidth)), y: min(1, max(0, q.y / sourceHeight)))
  }
  public func hits(_ stroke: InkStroke, point: InkPoint, tolerance: Double) -> Bool {
    let pts = stroke.points.map { p -> InkPoint in
      let q = project(p)
      return InkPoint(x: q.x * width, y: q.y * height)
    }
    let p = InkPoint(x: point.x * width, y: point.y * height)
    let radius = tolerance + stroke.width * shortSide / 2
    if pts.count == 1 { return hypot(p.x - pts[0].x, p.y - pts[0].y) <= radius }
    for (a, b) in zip(pts, pts.dropFirst()) {
      let vx = b.x - a.x
      let vy = b.y - a.y
      let length = vx * vx + vy * vy
      let t = length == 0 ? 0 : min(1, max(0, ((p.x - a.x) * vx + (p.y - a.y) * vy) / length))
      if hypot(p.x - a.x - t * vx, p.y - a.y - t * vy) <= radius { return true }
    }
    return false
  }
}
