import DrawryCore
import SwiftUI
import UIKit

struct InkCanvas: UIViewRepresentable {
  let image: UIImage
  let geometry: InkGeometry
  var recipe = EditRecipe()
  var mode = "view"
  var color = "#302C29"
  var width = 0.006
  var onStroke: (InkStroke) -> Void = { _ in }
  var onErase: (String) -> Void = { _ in }
  var onPosition: (InkPoint) -> Void = { _ in }
  var onLimit: () -> Void = {}
  func makeUIView(context: Context) -> InkCanvasUIView { InkCanvasUIView() }
  func updateUIView(_ view: InkCanvasUIView, context: Context) {
    if view.geometry?.turns != geometry.turns || view.geometry?.width != geometry.width
      || view.geometry?.height != geometry.height
    {
      view.resetViewport()
    }
    view.image = image
    view.geometry = geometry
    view.recipe = recipe
    view.mode = mode
    view.inkColor = color
    view.penWidth = width
    view.onStroke = onStroke
    view.onErase = onErase
    view.onPosition = onPosition
    view.onLimit = onLimit
    view.pan.minimumNumberOfTouches = mode == "view" ? 1 : 2
    view.setNeedsDisplay()
  }
}

final class InkCanvasUIView: UIView, UIGestureRecognizerDelegate {
  var image: UIImage?
  var geometry: InkGeometry?
  var recipe = EditRecipe()
  var mode = "view", inkColor = "#302C29"
  var penWidth = 0.006
  var onStroke: (InkStroke) -> Void = { _ in }
  var onErase: (String) -> Void = { _ in }
  var onPosition: (InkPoint) -> Void = { _ in }
  var onLimit: () -> Void = {}
  private var zoom: CGFloat = 1
  private var offset = CGPoint.zero
  private var imageRect = CGRect.zero
  private var active: InkStroke?
  private var limited = false
  lazy var pan = UIPanGestureRecognizer(target: self, action: #selector(panImage(_:)))
  override init(frame: CGRect) {
    super.init(frame: frame)
    isMultipleTouchEnabled = true
    clipsToBounds = true
    isOpaque = false
    accessibilityLabel = "사진 캔버스. 한 손가락으로 그리기, 두 손가락으로 확대와 이동"
    isAccessibilityElement = true
    let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchImage(_:)))
    pinch.delegate = self
    pan.delegate = self
    pan.minimumNumberOfTouches = 2
    addGestureRecognizer(pinch)
    addGestureRecognizer(pan)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  func resetViewport() {
    zoom = 1
    offset = .zero
    active = nil
  }
  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
  ) -> Bool { other.view === self }
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer === pan && mode == "view" && zoom <= 1 { return false }
    return true
  }
  @objc private func pinchImage(_ gesture: UIPinchGestureRecognizer) {
    active = nil
    zoom = min(5, max(1, zoom * gesture.scale))
    gesture.scale = 1
    if zoom == 1 { offset = .zero }
    setNeedsDisplay()
  }
  @objc private func panImage(_ gesture: UIPanGestureRecognizer) {
    active = nil
    let delta = gesture.translation(in: self)
    offset.x += delta.x
    offset.y += delta.y
    gesture.setTranslation(.zero, in: self)
    setNeedsDisplay()
  }
  override func draw(_ rect: CGRect) {
    guard let image, let g = geometry, let ctx = UIGraphicsGetCurrentContext() else { return }
    let fit = min(bounds.width / image.size.width, bounds.height / image.size.height)
    let size = CGSize(width: image.size.width * fit * zoom, height: image.size.height * fit * zoom)
    let maxX = max(0, (size.width - bounds.width) / 2)
    let maxY = max(0, (size.height - bounds.height) / 2)
    offset.x = min(maxX, max(-maxX, offset.x))
    offset.y = min(maxY, max(-maxY, offset.y))
    imageRect = CGRect(
      x: (bounds.width - size.width) / 2 + offset.x,
      y: (bounds.height - size.height) / 2 + offset.y, width: size.width, height: size.height)
    image.draw(in: imageRect)
    ctx.saveGState()
    defer { ctx.restoreGState() }
    ctx.translateBy(x: imageRect.minX, y: imageRect.minY)
    InkDrawing.draw(recipe.strokes + (active.map { [$0] } ?? []), in: ctx, geometry: g, size: size)
    ctx.clip(to: CGRect(origin: .zero, size: size))
    for item in recipe.overlays {
      let shadow = NSShadow()
      shadow.shadowColor = UIColor.black
      shadow.shadowBlurRadius = 3
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: item.size * size.width),
        .foregroundColor: InkDrawing.color(item.color), .shadow: shadow,
      ]
      let text = item.text as NSString
      let extent = text.size(withAttributes: attrs)
      text.draw(
        at: CGPoint(
          x: item.x * size.width - extent.width / 2, y: item.y * size.height - extent.height),
        withAttributes: attrs)
    }
  }
  private func point(_ p: CGPoint) -> InkPoint {
    InkPoint(
      x: min(1, max(0, (p.x - imageRect.minX) / imageRect.width)),
      y: min(1, max(0, (p.y - imageRect.minY) / imageRect.height)))
  }
  private func sample(_ p: CGPoint) {
    guard let g = geometry, !imageRect.isEmpty else { return }
    if mode == "erase" {
      if let stroke = recipe.strokes.last(where: {
        g.hits($0, point: point(p), tolerance: 12 * g.width / imageRect.width)
      }) {
        onErase(stroke.id)
      }
    } else if mode == "pen", !limited, var stroke = active {
      if recipe.strokes.reduce(0, { $0 + $1.points.count }) + stroke.points.count >= maxInkPoints {
        if !stroke.points.isEmpty { onStroke(stroke) }
        active = nil
        limited = true
        onLimit()
        return
      }
      let q = g.unproject(point(p))
      if let previous = stroke.points.last,
        hypot((q.x - previous.x) * g.sourceWidth, (q.y - previous.y) * g.sourceHeight) < g.width
          / imageRect.width
      {
        return
      }
      stroke.points.append(q)
      active = stroke
    }
    setNeedsDisplay()
  }
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard event?.allTouches?.count == 1, let touch = touches.first else {
      active = nil
      return
    }
    let p = touch.location(in: self)
    limited = false
    if mode == "pen", imageRect.contains(p) {
      if recipe.strokes.count >= maxInkStrokes
        || recipe.strokes.reduce(0, { $0 + $1.points.count }) >= maxInkPoints
      {
        limited = true
        onLimit()
        return
      }
      active = InkStroke(color: inkColor, width: penWidth)
      sample(p)
    } else if mode == "erase" {
      sample(p)
    }
  }
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard event?.allTouches?.count == 1, let touch = touches.first else {
      active = nil
      return
    }
    sample(touch.location(in: self))
  }
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let active, !active.points.isEmpty { onStroke(active) }
    if mode == "text", let p = touches.first?.location(in: self), imageRect.contains(p) {
      onPosition(point(p))
    }
    active = nil
    setNeedsDisplay()
  }
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    active = nil
    setNeedsDisplay()
  }
}
