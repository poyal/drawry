import AVKit
import DrawryCore
import SwiftUI
import UniformTypeIdentifiers

@main struct DrawryApp: App {
  @State private var model = AppModel()
  @Environment(\.scenePhase) private var phase
  var body: some Scene {
    WindowGroup {
      RootView(model: model).tint(Sketch.accent)
        .background(PrivacyWindowCover())
        .onChange(of: phase) { _, value in
          if value == .background {
            model.background()
          } else if value == .active {
            model.foreground()
          }
        }
    }
  }
}

struct RootView: View {
  @Bindable var model: AppModel
  var body: some View {
    Group {
      if model.erased {
        ContentUnavailableView(
          "기록을 모두 삭제했습니다", systemImage: "checkmark.shield", description: Text("앱을 다시 실행해 새로 시작하세요.")
        )
      } else if !model.ready {
        VStack(spacing: 20) {
          ProgressView()
          Text(model.error ?? "기록을 안전하게 열고 있어요")
        }
      } else if model.locked {
        VStack(spacing: 24) {
          Image(systemName: "lock.shield").font(.system(size: 56))
          NotebookMark()
          Text("나만의 기록, Drawry").font(Sketch.heading())
          Button("잠금 해제") { model.authenticate { model.locked = false } }.buttonStyle(
            .borderedProminent)
        }
      } else if !model.preferences.onboarded {
        VStack(alignment: .leading, spacing: 24) {
          NotebookMark()
          Text("오늘을\n나만의 그림으로").font(Sketch.heading(40))
          Text("사진과 이야기는 이 기기에 암호화해 보관합니다. 계정이나 서버 전송 없이 사용할 수 있어요.")
          Text("기기를 바꾸거나 앱을 삭제하기 전에는 암호화 백업을 만들어 주세요.").foregroundStyle(.secondary)
          Button("내 기록 시작하기") {
            var p = model.preferences
            p.onboarded = true
            model.setPreferences(p)
          }.buttonStyle(.borderedProminent)
        }.padding(32)
      } else {
        TabView {
          NavigationStack { FeedView(model: model) }.tabItem {
            Label("기록", systemImage: "square.grid.2x2")
          }
          NavigationStack { CalendarView(model: model) }.tabItem {
            Label("캘린더", systemImage: "calendar")
          }
          NavigationStack { SettingsView(model: model) }.tabItem {
            Label("설정", systemImage: "gearshape")
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity).background(Sketch.background).foregroundStyle(
      Sketch.ink
    )
    .privacySensitive()
    .sheet(
      isPresented: Binding(
        get: { model.editor != nil && !model.locked },
        set: { if !$0 && !model.locked { model.leaveEditor(discard: false) } })
    ) {
      EditorView(model: model).interactiveDismissDisabled()
    }
    .sheet(
      isPresented: Binding(
        get: { model.sharedFile != nil && !model.locked },
        set: { if !$0 { model.sharedFile = nil } })
    ) {
      if let file = model.sharedFile {
        ShareSheet(file: file) {
          try? FileManager.default.removeItem(at: file)
          model.sharedFile = nil
        }
      }
    }
    .alert(
      "확인해 주세요",
      isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
    ) {
      Button("확인") { model.error = nil }
    } message: {
      Text(model.error ?? "")
    }
    .confirmationDialog(
      "백업 복원",
      isPresented: Binding(
        get: { model.pendingRestore != nil }, set: { if !$0 { model.cancelRestore() } }),
      titleVisibility: .visible
    ) {
      Button("현재 기록에 병합") { model.restore(replace: false) }
      Button("백업으로 전체 교체", role: .destructive) { model.restore(replace: true) }
      Button("취소", role: .cancel) { model.cancelRestore() }
    } message: {
      if let snapshot = model.pendingRestore?.0 {
        Text(
          "일기 \(snapshot.diaries.count)개 · 미디어 \(snapshot.diaries.reduce(0){$0+$1.media.count})개\n병합은 동일 ID의 현재 기록을 유지합니다."
        )
      }
    }
    .overlay {
      if model.busy { BusyView(cancel: model.canCancel ? { model.cancelOperation() } : nil) }
    }
  }
}
struct BusyView: View {
  var cancel: (() -> Void)? = nil
  var body: some View {
    ZStack {
      Color.black.opacity(0.2).ignoresSafeArea()
      VStack(spacing: 16) {
        ProgressView()
        Text("안전하게 처리하고 있어요")
        if let cancel { Button("취소", action: cancel) }
      }.padding(28).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
  }
}

struct MediaImage: View {
  let model: AppModel
  let media: Media
  var full = false
  var fit = false
  var natural = false
  @State private var image: UIImage?
  var body: some View {
    ZStack {
      Color.secondary.opacity(0.08)
      if let image {
        Image(uiImage: image).resizable().aspectRatio(
          contentMode: (full || fit || natural) ? .fit : .fill)
      } else {
        ProgressView()
      }
      if media.kind == "video" {
        Image(systemName: "play.circle.fill").font(.largeTitle).foregroundStyle(.white).shadow(
          radius: 4)
      }
    }.aspectRatio(
      natural ? min(1.8, max(0.65, (image?.size.width ?? 1) / (image?.size.height ?? 1))) : nil,
      contentMode: .fit
    )
    .clipped().accessibilityLabel(media.kind == "video" ? "영상" : "일기 사진")
    .task(id: "\(media.thumbnail)-\(media.rendered ?? "")-\(full)") {
      image = try? await model.media?.image(media, full: full)
    }
  }
}
struct FeedView: View {
  @Bindable var model: AppModel
  private var diaries: [Diary] { model.diaries.filter { $0.deletedAt == nil } }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text("사진으로 채우는 나만의 스케치북").font(.footnote).foregroundStyle(Sketch.secondary)
        if model.draft != nil {
          Button("✎ 작성 중인 페이지 이어 쓰기") { model.startEditor() }.buttonStyle(.bordered)
        }
        if diaries.isEmpty {
          EmptyNotebook(
            title: "아직 펼치지 않은 이야기", message: "오늘의 사진 한 장으로 시작해 보세요.",
            action: { model.startEditor() })
        } else if model.preferences.layout == 1 {
          LazyVStack(spacing: 24) {
            ForEach(diaries) { diary in SketchDiaryCard(model: model, diary: diary) }
          }
        } else {
          let count = max(2, min(3, model.preferences.layout))
          LazyVGrid(
            columns: Array(
              repeating: GridItem(.flexible(), spacing: count == 2 ? 12 : 4), count: count),
            spacing: count == 2 ? 16 : 4
          ) {
            ForEach(diaries) { diary in
              NavigationLink(value: diary.id) {
                VStack(alignment: .leading, spacing: 6) {
                  MediaImage(model: model, media: diary.media[0]).aspectRatio(
                    count == 2 ? 4.0 / 5.0 : 1, contentMode: .fit
                  )
                  .overlay(alignment: .topTrailing) {
                    if diary.media.count > 1 {
                      Image(systemName: "square.on.square").foregroundStyle(.white).padding(6)
                    }
                  }
                  .overlay(alignment: .bottomLeading) {
                    if count == 3 {
                      Text(String(diary.entryDate.suffix(5))).font(.caption2).padding(4)
                        .foregroundStyle(.white).background(.black.opacity(0.55))
                    }
                  }
                  if count == 2 {
                    Text(diary.headline.isEmpty ? "오늘의 기록" : diary.headline).font(
                      Sketch.heading(24)
                    ).lineLimit(2).padding(.horizontal, 8)
                    Text(diary.entryDate).font(.caption2).foregroundStyle(Sketch.secondary).padding(
                      .horizontal, 8
                    ).padding(.bottom, 8)
                  }
                }.background(Sketch.paper).foregroundStyle(Sketch.ink)
              }.buttonStyle(.plain)
            }
          }
        }
      }.padding(20).padding(.bottom, 80).frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
    }.navigationTitle("Drawry").navigationBarTitleDisplayMode(.inline).notebookScreen()
      .toolbar { ToolbarItem(placement: .principal) { Text("Drawry").font(Sketch.heading()) } }
      .overlay(alignment: .bottomTrailing) { WritePageButton { model.startEditor() }.padding(20) }
      .navigationDestination(for: String.self) { id in DetailView(model: model, id: id) }
  }
}
struct WritePageButton: View {
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Label("기록하기", systemImage: "pencil").padding(.horizontal, 8).frame(minHeight: 44)
    }
    .buttonStyle(.borderedProminent).buttonBorderShape(.capsule).accessibilityLabel("일기 작성")
  }
}
struct SketchDiaryCard: View {
  let model: AppModel
  let diary: Diary
  @State private var index = 0
  var body: some View {
    PaperCard {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(diary.entryDate)
          Spacer()
          Text(diary.mood)
        }.font(.caption).foregroundStyle(Sketch.secondary)
        TabView(selection: $index) {
          ForEach(Array(diary.media.enumerated()), id: \.element.id) { i, item in
            NavigationLink(value: diary.id) { MediaImage(model: model, media: item, fit: true) }
              .tag(i)
          }
        }.tabViewStyle(.page(indexDisplayMode: .never)).aspectRatio(4.0 / 5.0, contentMode: .fit)
          .overlay(alignment: .top) { PaperTape().offset(y: -8) }
          .overlay(alignment: .topTrailing) {
            if diary.media.count > 1 {
              Text("\(index+1) / \(diary.media.count)").font(.caption).padding(8).foregroundStyle(
                .white
              ).background(.black.opacity(0.6), in: Capsule()).padding(8)
            }
          }
        NavigationLink(value: diary.id) {
          VStack(alignment: .leading, spacing: 8) {
            Text(diary.headline.isEmpty ? "오늘의 한 페이지" : diary.headline).font(Sketch.heading())
            if !diary.body.isEmpty {
              Text(diary.body).lineLimit(2).foregroundStyle(Sketch.secondary)
            }
            if !weatherText(diary.weather).isEmpty {
              Text(weatherText(diary.weather)).font(.caption).foregroundStyle(Sketch.secondary)
            }
          }.foregroundStyle(Sketch.ink)
        }.buttonStyle(.plain)
      }
    }
  }
}
struct CalendarView: View {
  @Bindable var model: AppModel
  @State private var month = Date()
  @State private var selected = Date()
  private var diaries: [Diary] { model.diaries.filter { $0.deletedAt == nil } }
  private var selectedKey: String { Self.key(selected) }
  static func key(_ date: Date) -> String {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
  }
  var body: some View {
    List {
      Section {
        HStack {
          Button {
            month = Calendar.current.date(byAdding: .month, value: -1, to: month)!
          } label: {
            Image(systemName: "chevron.left")
          }
          Spacer()
          Text(month.formatted(.dateTime.year().month(.wide)))
          Spacer()
          Button {
            month = Calendar.current.date(byAdding: .month, value: 1, to: month)!
          } label: {
            Image(systemName: "chevron.right")
          }
        }.buttonStyle(.borderless)
        let start = Calendar.current.date(
          from: Calendar.current.dateComponents([.year, .month], from: month))!
        let count = Calendar.current.range(of: .day, in: .month, for: month)!.count
        let offset = (Calendar.current.component(.weekday, from: start) + 5) % 7
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
          ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) {
            Text($0).font(.caption).foregroundStyle(.secondary)
          }
          ForEach(0..<(offset + count), id: \.self) { index in
            if index < offset {
              Color.clear.frame(height: 48)
            } else {
              let date = Calendar.current.date(byAdding: .day, value: index - offset, to: start)!
              let key = Self.key(date)
              let entries = diaries.filter { $0.entryDate == key }
              let number = entries.count
              Button {
                selected = date
              } label: {
                VStack(spacing: 4) {
                  Text("\(index-offset+1)")
                  if let entry = entries.first {
                    MediaImage(model: model, media: entry.media[0]).frame(width: 26, height: 26)
                      .overlay(alignment: .bottomTrailing) {
                        if number > 1 {
                          Text("\(number)").font(.caption2).foregroundStyle(.white).background(
                            .black.opacity(0.6))
                        }
                      }
                  } else {
                    Color.clear.frame(height: 26)
                  }
                }.frame(maxWidth: .infinity).padding(.vertical, 6).background(
                  key == selectedKey ? Color.accentColor.opacity(0.18) : Color.clear,
                  in: RoundedRectangle(cornerRadius: 10))
              }.buttonStyle(.plain)
            }
          }
        }
      }
      Section(selectedKey) {
        let entries = diaries.filter { $0.entryDate == selectedKey }
        if entries.isEmpty { Text("이날의 기록이 없어요.").foregroundStyle(.secondary) }
        ForEach(entries) { diary in
          NavigationLink(value: diary.id) {
            HStack {
              MediaImage(model: model, media: diary.media[0]).frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              Text(diary.headline.isEmpty ? "오늘의 기록" : diary.headline)
            }
          }
        }
      }
    }.navigationTitle("캘린더").notebookScreen().overlay(alignment: .bottomTrailing) {
      WritePageButton { model.startEditor() }.padding(20)
    }.toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button("오늘") {
          month = Date()
          selected = Date()
        }
      }
    }
    .navigationDestination(for: String.self) { id in DetailView(model: model, id: id) }
  }
}
struct DiaryText: View {
  let diary: Diary
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(diary.headline.isEmpty ? "오늘의 기록" : diary.headline).font(Sketch.heading())
      Text(
        "\(diary.entryDate) \(String(format:"%02d:%02d",diary.entryTimeMinutes/60,diary.entryTimeMinutes%60)) \(diary.mood)"
      ).font(.subheadline).foregroundStyle(.secondary)
      if !diary.body.isEmpty { Text(diary.body) }
      if !diary.tags.isEmpty {
        Text(diary.tags.map { "#\($0)" }.joined(separator: " ")).foregroundStyle(Color.accentColor)
      }
      if !diary.companions.isEmpty { Text("함께한 사람 · \(diary.companions.joined(separator:", "))") }
      Text(weatherText(diary.weather)).font(.subheadline)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
}
func weatherText(_ weather: Weather) -> String {
  var fields: [String] = []
  if weather.displayMask & 1 != 0, !weather.condition.isEmpty { fields.append(weather.condition) }
  if weather.displayMask & 2 != 0, let n = weather.temperature { fields.append("\(n)°C") }
  if weather.displayMask & 4 != 0 {
    if let n = weather.minimum { fields.append("최저 \(n)°C") }
    if let n = weather.maximum { fields.append("최고 \(n)°C") }
  }
  if weather.displayMask & 8 != 0, weather.precipitation { fields.append("비·눈") }
  return fields.joined(separator: " · ")
}
struct DetailView: View {
  @Bindable var model: AppModel
  let id: String
  @Environment(\.dismiss) private var dismiss
  @State private var confirm = false
  @State private var sharing = false
  @State private var playing: Media?
  @State private var viewing: Int?
  var body: some View {
    Group {
      if let diary = model.diaries.first(where: { $0.id == id }) {
        ScrollView {
          VStack(spacing: 20) {
            ForEach(diary.media) { item in
              MediaImage(model: model, media: item, full: true, natural: true).frame(
                maxWidth: .infinity
              )
              .onTapGesture {
                if item.kind == "video" {
                  playing = item
                } else {
                  viewing = diary.media.firstIndex(where: { $0.id == item.id })
                }
              }
            }
            PaperCard { DiaryText(diary: diary) }
            if diary.deletedAt == nil {
              Button("이미지 공유") { sharing = true }
              Button("휴지통으로 이동", role: .destructive) { confirm = true }
            } else {
              Button("기록 복원") {
                model.trash(diary, restore: true)
                dismiss()
              }
              Button("영구 삭제", role: .destructive) { confirm = true }
            }
          }.padding()
        }.notebookScreen().navigationTitle(diary.entryDate).navigationBarTitleDisplayMode(.inline)
          .toolbar { if diary.deletedAt == nil { Button("수정") { model.startEditor(diary) } } }
          .confirmationDialog(
            diary.deletedAt == nil ? "30일 동안 휴지통에 보관합니다." : "이 기록은 되돌릴 수 없습니다.",
            isPresented: $confirm, titleVisibility: .visible
          ) {
            Button("삭제", role: .destructive) {
              if diary.deletedAt == nil { model.trash(diary) } else { model.purge(diary) }
              dismiss()
            }
          }
          .sheet(isPresented: $sharing) { ShareOptionsView(model: model, diary: diary) }
      } else {
        ContentUnavailableView("기록이 없습니다", systemImage: "book.closed")
      }
    }
    .sheet(item: $playing) { item in VideoView(model: model, media: item) }
    .fullScreenCover(
      isPresented: Binding(get: { viewing != nil }, set: { if !$0 { viewing = nil } })
    ) {
      if let index = viewing, let diary = model.diaries.first(where: { $0.id == id }) {
        PhotoViewer(model: model, media: diary.media, initial: index)
      }
    }
  }
}
struct VideoView: View {
  let model: AppModel
  let media: Media
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var phase
  @State private var player: AVPlayer?
  var body: some View {
    NavigationStack {
      VideoPlayer(player: player).navigationTitle("영상").toolbar { Button("닫기") { dismiss() } }
    }.task {
      if let url = try? await model.media?.clearFile(media, original: true) {
        player = AVPlayer(url: url)
        player?.play()
      }
    }.onChange(of: phase) { _, value in if value != .active { player?.pause() } }
      .onDisappear {
        player?.pause()
        player = nil
      }
  }
}
