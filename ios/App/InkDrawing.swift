import DrawryCore
import UIKit

enum InkDrawing {
  static func color(_ hex: String) -> UIColor {
    let rgb = UInt32(hex.dropFirst(), radix: 16) ?? 0x302C29
    return UIColor(
      red: CGFloat((rgb >> 16) & 255) / 255, green: CGFloat((rgb >> 8) & 255) / 255,
      blue: CGFloat(rgb & 255) / 255, alpha: 1)
  }
  static func draw(_ strokes: [InkStroke], in ctx: CGContext, geometry: InkGeometry, size: CGSize) {
    ctx.saveGState()
    defer { ctx.restoreGState() }
    ctx.clip(to: CGRect(origin: .zero, size: size))
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    for stroke in strokes where !stroke.points.isEmpty {
      let width = CGFloat(stroke.width * geometry.shortSide / geometry.width) * size.width
      let points = stroke.points.map { p -> CGPoint in
        let q = geometry.project(p)
        return CGPoint(x: q.x * size.width, y: q.y * size.height)
      }
      ctx.setStrokeColor(color(stroke.color).cgColor)
      ctx.setFillColor(color(stroke.color).cgColor)
      ctx.setLineWidth(width)
      if points.count == 1 {
        ctx.fillEllipse(
          in: CGRect(
            x: points[0].x - width / 2, y: points[0].y - width / 2, width: width, height: width))
      } else {
        ctx.beginPath()
        ctx.addLines(between: points)
        ctx.strokePath()
      }
    }
  }
}
