import DrawryCore
import SwiftUI

struct PhotoViewer: View {
  let model: AppModel
  let media: [Media]
  @State private var index: Int
  @State private var playing: Media?
  @Environment(\.dismiss) private var dismiss
  init(model: AppModel, media: [Media], initial: Int) {
    self.model = model
    self.media = media
    _index = State(initialValue: initial)
  }
  var body: some View {
    VStack {
      HStack {
        Button("닫기") { dismiss() }.frame(minHeight: 44)
        Spacer()
        Text("\(index+1) / \(media.count)")
      }.padding(.horizontal, 20)
      TabView(selection: $index) {
        ForEach(Array(media.enumerated()), id: \.element.id) { i, item in
          PhotoViewerPage(model: model, media: item, play: { playing = item }).tag(i)
        }
      }.tabViewStyle(.page(indexDisplayMode: .never))
      Text("두 손가락으로 확대 · 좌우로 넘기기").font(.footnote).padding()
    }.background(.black).foregroundStyle(.white).tint(.white)
      .sheet(item: $playing) { item in VideoView(model: model, media: item) }
  }
}
private struct PhotoViewerPage: View {
  let model: AppModel
  let media: Media
  let play: () -> Void
  @State private var image: UIImage?
  @State private var failed = false
  var body: some View {
    VStack {
      if let image {
        InkCanvas(
          image: image,
          geometry: InkGeometry(
            width: image.size.width, height: image.size.height, turns: 0, square: false)
        ).frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if failed {
        Text("사진을 열지 못했습니다.")
      } else {
        ProgressView().tint(.white)
      }
      if media.kind == "video" { Button("영상 재생", action: play).frame(minHeight: 44) }
    }.task {
      do {
        image = try await model.media?.image(media, full: true)
        failed = image == nil
      } catch { failed = true }
    }
  }
}
