import DrawryCore
import SwiftUI

struct EditorView: View {
  @Bindable var model: AppModel
  @State private var library = false
  @State private var camera = false
  @State private var preserve = false
  @State private var extras = false
  @State private var preview = false
  @State private var exit = false
  @State private var editing: Media?
  @State private var frame: Media?
  @State private var photoIndex = 0
  private var diary: Diary { model.editor ?? Diary() }
  private func field<T>(_ key: WritableKeyPath<Diary, T>) -> Binding<T> {
    Binding(
      get: { diary[keyPath: key] },
      set: {
        var d = diary
        d[keyPath: key] = $0
        model.update(d)
      })
  }
  private var date: Binding<Date> {
    Binding(
      get: {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: diary.entryDate) ?? Date()
      },
      set: {
        var d = diary
        d.entryDate = CalendarView.key($0)
        model.update(d)
      })
  }
  private var time: Binding<Date> {
    Binding(
      get: {
        Calendar.current.date(
          bySettingHour: diary.entryTimeMinutes / 60, minute: diary.entryTimeMinutes % 60,
          second: 0, of: Date())!
      },
      set: {
        let c = Calendar.current.dateComponents([.hour, .minute], from: $0)
        var d = diary
        d.entryTimeMinutes = c.hour! * 60 + c.minute!
        model.update(d)
      })
  }
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          if diary.media.isEmpty { NotebookMark().frame(maxWidth: .infinity) }
          Text(diary.media.isEmpty ? "사진을 붙여 주세요" : "오늘의 장면").font(Sketch.heading())
          HStack {
            Button("보관함") { library = true }.buttonStyle(.borderedProminent)
            Button("촬영") {
              if UIImagePickerController.isSourceTypeAvailable(.camera) {
                camera = true
              } else {
                model.error = "이 기기에서는 카메라를 사용할 수 없습니다."
              }
            }.buttonStyle(.bordered)
          }.frame(minHeight: 44)
          Text(
            "사진과 영상 \(diary.media.count)/10 · \(diary.media.reduce(0){$0+$1.byteLength}/1024/1024)MB / 300MB"
          ).font(.caption).foregroundStyle(Sketch.secondary)
          DisclosureGroup("사진 가져오기 옵션") { Toggle("사진 원본 보관", isOn: $preserve) }
          if !diary.media.isEmpty { mediaStrip }
          PaperCard {
            VStack(alignment: .leading, spacing: 16) {
              TextField("오늘의 한 줄 (선택)", text: field(\.headline)).font(Sketch.heading(28)).frame(
                minHeight: 44)
              Divider()
              TextField("오늘은 어떤 하루였나요?", text: field(\.body), axis: .vertical).lineLimit(5...20)
            }
          }
          DisclosureGroup("날짜 · 기분 · 날씨 더하기", isExpanded: $extras) {
            VStack(alignment: .leading, spacing: 16) {
              DatePicker("날짜", selection: date, displayedComponents: .date)
              DatePicker("시간", selection: time, displayedComponents: .hourAndMinute)
              TextField("기분", text: field(\.mood)).textFieldStyle(.roundedBorder)
              HStack {
                ForEach(["😊", "🥰", "😌", "😢", "😤"], id: \.self) { emoji in
                  Button(emoji) {
                    var d = diary
                    d.mood = emoji
                    model.update(d)
                  }.frame(minWidth: 44, minHeight: 44)
                }
              }
              TokenField(title: "태그 (쉼표로 구분)", values: field(\.tags))
              TokenField(title: "함께한 사람 (쉼표로 구분)", values: field(\.companions))
              WeatherEditor(weather: field(\.weather))
            }.padding(.top, 12)
          }
          Button("페이지 미리 보기") { preview = true }.disabled(diary.media.isEmpty).frame(minHeight: 44)
          Text("변경 사항은 암호화된 초안으로 자동 저장됩니다.").font(.footnote).foregroundStyle(Sketch.secondary)
          Text("영상은 3개·각 30초·합계 60초까지 담을 수 있어요.").font(.footnote).foregroundStyle(Sketch.secondary)
        }.padding(20).frame(maxWidth: 720).frame(maxWidth: .infinity)
      }.notebookScreen().navigationTitle("오늘의 한 페이지").navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("닫기") { exit = true } }
          ToolbarItem(placement: .confirmationAction) {
            Button("저장") { model.save() }.disabled(diary.media.isEmpty)
          }
        }
        .confirmationDialog("작성 중인 기록", isPresented: $exit, titleVisibility: .visible) {
          Button("초안 보관") { model.leaveEditor(discard: false) }
          Button("초안 폐기", role: .destructive) { model.leaveEditor(discard: true) }
        }
        .sheet(isPresented: $library) {
          LibraryPicker { files, error in
            library = false
            if let error {
              model.error = error
            } else if !files.isEmpty {
              model.importFiles(files, preserve: preserve)
            }
          }
        }
        .sheet(isPresented: $camera) {
          CameraPicker { url, video, error in
            camera = false
            if let error {
              model.error = error
            } else if let url {
              model.importFiles([(url, video)], preserve: preserve)
            }
          }.ignoresSafeArea()
        }
        .sheet(item: $editing) { item in ImageEditorView(model: model, media: item) }
        .sheet(item: $frame) { item in FramePickerView(model: model, media: item) }
        .sheet(isPresented: $preview) {
          NavigationStack {
            ScrollView {
              VStack(spacing: 16) {
                ForEach(diary.media) {
                  MediaImage(model: model, media: $0, full: true, natural: true)
                }
                PaperCard { DiaryText(diary: diary) }
              }.padding(20)
            }.notebookScreen().navigationTitle("미리 보기").toolbar {
              ToolbarItem(placement: .cancellationAction) { Button("수정") { preview = false } }
              ToolbarItem(placement: .confirmationAction) {
                Button("암호화 저장") {
                  preview = false
                  model.save()
                }
              }
            }
          }
        }
    }.overlay {
      if model.busy { BusyView(cancel: model.canCancel ? { model.cancelOperation() } : nil) }
    }
    .alert(
      "확인해 주세요",
      isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
    ) {
      Button("확인") { model.error = nil }
    } message: {
      Text(model.error ?? "")
    }
    .onChange(of: diary.media.map(\.id)) { _, _ in
      photoIndex = min(photoIndex, max(0, diary.media.count - 1))
    }
  }
  private var mediaStrip: some View {
    let index = min(photoIndex, diary.media.count - 1)
    let item = diary.media[index]
    return PaperCard {
      VStack(alignment: .leading, spacing: 8) {
        TabView(selection: $photoIndex) {
          ForEach(Array(diary.media.enumerated()), id: \.element.id) { offset, media in
            MediaImage(model: model, media: media, full: true, fit: true)
              .frame(height: 280).tag(offset)
          }
        }.tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 280)
        Text("\(index + 1) / \(diary.media.count) · 옆으로 넘겨 보세요")
          .font(.caption).foregroundStyle(Sketch.secondary)
        if diary.media.count > 1 {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(Array(diary.media.enumerated()), id: \.element.id) { offset, media in
                Button {
                  withAnimation { photoIndex = offset }
                } label: {
                  MediaImage(model: model, media: media).frame(width: 52, height: 52).clipped()
                    .overlay(
                      RoundedRectangle(cornerRadius: 4)
                        .stroke(
                          index == offset ? Sketch.accent : Sketch.line,
                          lineWidth: index == offset ? 2 : 1))
                }.buttonStyle(.plain).accessibilityLabel("\(offset + 1)번째 사진 선택")
              }
            }
          }
        }
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 24) {
            Button(item.kind == "video" ? "대표 프레임" : "꾸미기") {
              if item.kind == "video" { frame = item } else { editing = item }
            }
            Button("앞으로") {
              var d = diary
              d.media.swapAt(index, index - 1)
              photoIndex = index - 1
              model.update(d)
            }.disabled(index == 0)
            Button("제거", role: .destructive) {
              var d = diary
              d.media.removeAll { $0.id == item.id }
              photoIndex = min(index, max(0, d.media.count - 1))
              model.update(d)
            }
          }.buttonStyle(.borderless).frame(minHeight: 44)
        }
      }
    }
  }
}
struct TokenField: View {
  let title: String
  @Binding var values: [String]
  @State private var text = ""
  var body: some View {
    TextField(title, text: $text).onAppear { text = values.joined(separator: ", ") }.onChange(
      of: text
    ) { _, value in
      values = value.split(separator: ",").map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      }.filter { !$0.isEmpty }
    }
  }
}
struct WeatherEditor: View {
  @Binding var weather: Weather
  var body: some View {
    TextField("날씨", text: $weather.condition)
    HStack {
      Text("기온")
      TextField("선택", value: $weather.temperature, format: .number).keyboardType(
        .numbersAndPunctuation)
      Text("°C")
    }
    HStack {
      Text("최저")
      TextField("선택", value: $weather.minimum, format: .number).keyboardType(.numbersAndPunctuation)
      Text("최고")
      TextField("선택", value: $weather.maximum, format: .number).keyboardType(.numbersAndPunctuation)
    }
    Toggle("비 또는 눈", isOn: $weather.precipitation)
    ForEach([(1, "날씨 상태"), (2, "기온"), (4, "최저·최고"), (8, "강수")], id: \.0) { mask, label in
      Toggle(
        "\(label) 표시",
        isOn: Binding(
          get: { weather.displayMask & mask != 0 },
          set: { if $0 { weather.displayMask |= mask } else { weather.displayMask &= ~mask } }))
    }
  }
}
struct ImageEditorView: View {
  let model: AppModel
  let media: Media
  @Environment(\.dismiss) private var dismiss
  @State private var recipe = EditRecipe()
  @State private var undo: [EditRecipe] = []
  @State private var redo: [EditRecipe] = []
  @State private var tool = "사진"
  @State private var erasing = false
  @State private var inkColor = "#302C29"
  @State private var penWidth = 0.006
  @State private var text = ""
  @State private var selected: String?
  @State private var original: UIImage?
  @State private var preview: UIImage?
  @State private var renderedRecipe: EditRecipe?
  @State private var notice: String?
  private func change(_ next: EditRecipe) {
    guard next != recipe else { return }
    undo.append(recipe)
    if undo.count > 100 { undo.removeFirst() }
    redo = []
    recipe = next
  }
  private func add(_ value: String) {
    guard recipe.overlays.count < 100 else {
      notice = "텍스트·스티커는 100개까지 넣을 수 있어요."
      return
    }
    var next = recipe
    let overlay = Overlay(text: value)
    next.overlays.append(overlay)
    selected = overlay.id
    change(next)
  }
  var body: some View {
    NavigationStack {
      VStack(spacing: 8) {
        if let original, let preview {
          InkCanvas(
            image: preview,
            geometry: InkGeometry(
              width: original.size.width, height: original.size.height, turns: recipe.quarterTurns,
              square: recipe.squareCrop),
            recipe: recipe,
            mode: tool == "낙서" ? (erasing ? "erase" : "pen") : (tool == "글자" ? "text" : "view"),
            color: inkColor, width: penWidth,
            onStroke: { stroke in
              var next = recipe
              next.version = 2
              next.strokes.append(stroke)
              change(next)
            },
            onErase: { id in
              var next = recipe
              next.strokes.removeAll { $0.id == id }
              change(next)
            },
            onPosition: { p in
              if let i = recipe.overlays.firstIndex(where: { $0.id == selected }) {
                var next = recipe
                next.overlays[i].x = p.x
                next.overlays[i].y = p.y
                change(next)
              }
            },
            onLimit: { notice = "사진 한 장에 256획·20,000점까지 그릴 수 있어요. 획을 지우고 이어 그려 주세요." }
          )
          .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.horizontal, 16)
        } else {
          ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        HStack {
          Button("실행 취소") {
            redo.append(recipe)
            recipe = undo.removeLast()
          }.disabled(undo.isEmpty)
          Spacer()
          Button("다시 실행") {
            undo.append(recipe)
            recipe = redo.removeLast()
          }.disabled(redo.isEmpty)
        }.buttonStyle(.borderless).frame(minHeight: 44).padding(.horizontal, 20)
        Divider()
        Picker("편집 도구", selection: $tool) {
          ForEach(["사진", "필터", "글자", "낙서"], id: \.self) { Text($0).tag($0) }
        }.pickerStyle(.segmented).padding(.horizontal, 20)
        ScrollView { controls.padding(.horizontal, 20).padding(.vertical, 8) }.frame(height: 220)
      }.navigationTitle("사진 꾸미기").navigationBarTitleDisplayMode(.inline).notebookScreen()
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
          ToolbarItem(placement: .confirmationAction) {
            Button("적용") {
              model.edit(media, recipe: recipe)
              dismiss()
            }.disabled(preview == nil)
          }
        }
    }
    .task {
      recipe = media.edit
      do {
        guard let url = try await model.media?.clearFile(media, original: true) else { return }
        original = try MediaStore.decode(url, maximum: 1200)
        render()
      } catch { notice = "사진을 열지 못했습니다. 다시 시도해 주세요." }
    }
    .onChange(of: recipe) { _, _ in render() }
    .alert("사진 꾸미기", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } }))
    {
      Button("확인") { notice = nil }
    } message: {
      Text(notice ?? "")
    }
  }
  @ViewBuilder private var controls: some View {
    switch tool {
    case "사진":
      VStack(spacing: 12) {
        HStack {
          Button("90° 회전") {
            var next = recipe
            next.quarterTurns = (next.quarterTurns + 1) % 4
            change(next)
          }
          Spacer()
          Toggle(
            "정사각 자르기",
            isOn: Binding(
              get: { recipe.squareCrop },
              set: {
                var next = recipe
                next.squareCrop = $0
                change(next)
              }))
        }
        Text("두 손가락으로 사진을 확대하고 이동할 수 있어요.").font(.footnote).foregroundStyle(Sketch.secondary)
      }
    case "필터":
      Picker(
        "필터",
        selection: Binding(
          get: { recipe.filter },
          set: {
            var next = recipe
            next.filter = $0
            change(next)
          })
      ) {
        Text("원본").tag("original")
        Text("흑백").tag("mono")
        Text("따뜻하게").tag("warm")
        Text("차갑게").tag("cool")
      }.pickerStyle(.segmented)
    case "낙서": inkControls
    default: textControls
    }
  }
  private var inkControls: some View {
    VStack(spacing: 12) {
      Picker("낙서 도구", selection: $erasing) {
        Text("펜").tag(false)
        Text("획 지우개").tag(true)
      }.pickerStyle(.segmented)
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
        ForEach(
          Array(
            zip(
              ["#302C29", "#FFFFFF", "#78658F", "#C54C4C", "#E9B949", "#44795A"],
              ["검정", "흰색", "보라", "빨강", "노랑", "초록"])), id: \.0
        ) { hex, name in
          Button {
            inkColor = hex
            erasing = false
          } label: {
            Circle().fill(Color(uiColor: InkDrawing.color(hex))).frame(width: 26, height: 26)
              .overlay(
                Circle().stroke(
                  inkColor == hex ? Sketch.accent : Sketch.line, lineWidth: inkColor == hex ? 3 : 1)
              )
              .frame(minWidth: 44, minHeight: 44)
          }.accessibilityLabel(name).accessibilityAddTraits(inkColor == hex ? .isSelected : [])
        }
      }
      Picker("펜 굵기", selection: $penWidth) {
        Text("가는 선").tag(0.003)
        Text("중간 선").tag(0.006)
        Text("굵은 선").tag(0.012)
      }.pickerStyle(.segmented)
      Text("한 손가락으로 그리기 · 두 손가락으로 확대/이동").font(.footnote).foregroundStyle(Sketch.secondary)
    }
  }
  private var textControls: some View {
    VStack(spacing: 12) {
      HStack {
        TextField("텍스트·이모지", text: $text).textFieldStyle(.roundedBorder)
        Button("추가") {
          if !text.isEmpty {
            add(text)
            text = ""
          }
        }
      }
      HStack {
        ForEach(["🌸", "❤️", "✨"], id: \.self) { value in
          Button(value) { add(value) }.frame(minWidth: 44, minHeight: 44)
        }
      }
      Text("항목을 고른 뒤 사진을 눌러 위치를 정하세요.").font(.footnote).foregroundStyle(Sketch.secondary)
      ScrollView(.horizontal) {
        HStack {
          ForEach(recipe.overlays) { item in
            Button(item.text) { selected = item.id }.buttonStyle(.bordered)
          }
        }
      }
      if let i = recipe.overlays.firstIndex(where: { $0.id == selected }) {
        Slider(
          value: Binding(
            get: { recipe.overlays[i].size },
            set: {
              var next = recipe
              next.overlays[i].size = $0
              change(next)
            }), in: 0.03...0.3)
        Button("선택한 글자 삭제", role: .destructive) {
          var next = recipe
          next.overlays.removeAll { $0.id == selected }
          change(next)
          selected = nil
        }
      }
    }
  }
  private func render() {
    guard let original else { return }
    var base = recipe
    base.strokes = []
    base.overlays = []
    guard base != renderedRecipe else { return }
    preview = try? MediaStore.render(original, recipe: base)
    renderedRecipe = base
  }
}
struct FramePickerView: View {
  let model: AppModel
  let media: Media
  @Environment(\.dismiss) private var dismiss
  @State private var seconds = 0.0
  @State private var preview: UIImage?
  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        if let preview {
          Image(uiImage: preview).resizable().scaledToFit().frame(height: 300)
        } else {
          ProgressView().frame(height: 300)
        }
        Text("\(seconds,specifier:"%.1f")초")
        Slider(value: $seconds, in: 0...max(0.01, Double(media.durationMillis) / 1000 - 0.05))
      }.padding().navigationTitle("영상 대표 화면").toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button("선택") {
            model.frame(media, millis: Int64(seconds * 1000))
            dismiss()
          }
        }
      }
    }.onAppear { seconds = Double(media.representativeMillis) / 1000 }
      .task(id: seconds) {
        do {
          try await Task.sleep(for: .milliseconds(120))
          preview = try await model.media?.previewFrame(media, millis: Int64(seconds * 1000))
        } catch {}
      }
  }
}
