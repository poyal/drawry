import SwiftUI
import UIKit

enum Sketch {
  static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(
      UIColor { traits in
        let v = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(
          red: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255,
          blue: CGFloat(v & 255) / 255, alpha: 1)
      })
  }
  static let background = adaptive(0xF7F3EA, 0x211E1B)
  static let paper = adaptive(0xFFFCF5, 0x292521)
  static let ink = adaptive(0x302C29, 0xF3EDE2)
  static let secondary = adaptive(0x6E655D, 0xC6BEB1)
  static let accent = adaptive(0x78658F, 0xD2BDD9)
  static let line = adaptive(0xDED5C7, 0x4A4239)
  static func heading(_ size: CGFloat = 32) -> Font {
    .custom("NanumPen-Regular", size: size, relativeTo: .title)
  }
}
struct NotebookScreen: ViewModifier {
  func body(content: Content) -> some View {
    content.scrollContentBackground(.hidden).background(Sketch.background)
      .foregroundStyle(Sketch.ink).tint(Sketch.accent)
      .toolbarBackground(Sketch.background, for: .navigationBar, .tabBar)
      .toolbarBackground(.visible, for: .navigationBar, .tabBar)
  }
}
extension View { func notebookScreen() -> some View { modifier(NotebookScreen()) } }
struct PaperCard<Content: View>: View {
  let content: Content
  init(@ViewBuilder content: () -> Content) { self.content = content() }
  var body: some View {
    content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
      .background(Sketch.paper, in: RoundedRectangle(cornerRadius: 12))
      .overlay(RoundedRectangle(cornerRadius: 12).stroke(Sketch.line, lineWidth: 1))
  }
}
struct NotebookMark: View {
  var body: some View {
    Canvas { ctx, size in
      let w = size.width
      let h = size.height
      let rect = CGRect(x: w * 0.14, y: h * 0.10, width: w * 0.69, height: h * 0.78)
      let page = Path(roundedRect: rect, cornerRadius: w * 0.05)
      ctx.fill(page, with: .color(Sketch.paper))
      ctx.stroke(page, with: .color(Sketch.accent), lineWidth: 2)
      var line = Path()
      line.move(to: CGPoint(x: w * 0.26, y: h * 0.10))
      line.addLine(to: CGPoint(x: w * 0.26, y: h * 0.88))
      ctx.stroke(line, with: .color(Sketch.accent), lineWidth: 2)
      let sun = Path(ellipseIn: CGRect(x: w * 0.59, y: h * 0.28, width: w * 0.11, height: h * 0.11))
      ctx.fill(sun, with: .color(Sketch.accent.opacity(0.55)))
      var hill = Path()
      hill.move(to: CGPoint(x: w * 0.35, y: h * 0.60))
      hill.addLines([
        CGPoint(x: w * 0.49, y: h * 0.44), CGPoint(x: w * 0.58, y: h * 0.54),
        CGPoint(x: w * 0.72, y: h * 0.42),
      ])
      ctx.stroke(hill, with: .color(Sketch.accent), lineWidth: 2)
    }.frame(width: 128, height: 128).accessibilityHidden(true)
  }
}
struct PaperTape: View {
  var body: some View {
    Rectangle().fill(Sketch.accent.opacity(0.18)).frame(width: 48, height: 12)
      .rotationEffect(.degrees(-3)).accessibilityHidden(true).allowsHitTesting(false)
  }
}
struct EmptyNotebook: View {
  let title: String
  let message: String
  var action: (() -> Void)?
  var body: some View {
    VStack(spacing: 16) {
      NotebookMark()
      Text(title).font(Sketch.heading()).multilineTextAlignment(.center)
      Text(message).font(.body).foregroundStyle(Sketch.secondary).multilineTextAlignment(.center)
      if let action {
        Button("첫 페이지 채우기", action: action).buttonStyle(.borderedProminent).frame(minHeight: 44)
      }
    }.frame(maxWidth: .infinity).padding(.vertical, 40)
  }
}
