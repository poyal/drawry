import DrawryCore
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
  @Bindable var model: AppModel
  @State private var password = ""
  @State private var recovery = ""
  @State private var recoveryCode: String?
  @State private var importing = false
  @State private var erase = false
  @State private var usage = ""
  private var grace: Binding<Int> {
    Binding(
      get: { model.preferences.graceSeconds },
      set: {
        var p = model.preferences
        p.graceSeconds = $0
        model.setPreferences(p)
      })
  }
  var body: some View {
    Form {
      Section {
        Picker(
          "기록 보기 방식",
          selection: Binding(
            get: { model.preferences.layout },
            set: {
              var p = model.preferences
              p.layout = $0
              model.setPreferences(p)
            })
        ) {
          Text("카드").tag(1)
          Text("2열").tag(2)
          Text("3열").tag(3)
        }
      } header: {
        Text("화면")
      } footer: {
        Text("기록 탭에 일기를 표시하는 방식을 선택하세요.")
      }
      Section("개인정보와 보안") {
        Toggle(
          "앱 잠금",
          isOn: Binding(
            get: { model.preferences.lockEnabled },
            set: { enabled in
              model.authenticate {
                var p = model.preferences
                p.lockEnabled = enabled
                model.setPreferences(p)
              }
            }))
        Picker("다시 잠그기", selection: grace) {
          Text("즉시").tag(0)
          Text("30초").tag(30)
          Text("1분").tag(60)
          Text("5분").tag(300)
          Text("15분").tag(900)
          Text("30분").tag(1800)
        }
        Text("기록은 기기에 암호화해 보관합니다. 계정·서버·분석 SDK를 사용하지 않으며, 공유와 백업은 직접 실행할 때만 앱 밖으로 전달됩니다.").font(
          .footnote)
      }
      Section("저장 공간") { Text(usage.isEmpty ? "계산 중…" : usage) }
      Section("암호화 백업·복원") {
        SecureField("백업 암호 (8자 이상)", text: $password).textContentType(.newPassword)
        TextField("복구 키 (암호 대신 사용)", text: $recovery).textInputAutocapitalization(.never)
          .autocorrectionDisabled()
        Button("백업 저장") {
          model.run(cancellable: true) {
            model.sharedFile = try await model.vault?.export(password: password)
          }
        }.disabled(password.count < 8)
        Button("백업 열기") { importing = true }.disabled(password.isEmpty && recovery.isEmpty)
        Button("복구 키 보기") {
          model.authenticate { model.run { recoveryCode = try await model.vault?.recoveryCode() } }
        }
        Text("iOS·Android Drawry 네이티브 앱 사이에서 복원할 수 있습니다. Flutter 앱의 이전 백업은 지원하지 않습니다.").font(
          .footnote
        ).foregroundStyle(.secondary)
      }
      Section("휴지통 · 30일 보관") {
        let deleted = model.diaries.filter { $0.deletedAt != nil }
        if deleted.isEmpty { Text("휴지통이 비어 있습니다.").foregroundStyle(.secondary) }
        ForEach(deleted) { diary in
          NavigationLink(value: diary.id) {
            VStack(alignment: .leading) {
              Text(diary.headline.isEmpty ? diary.entryDate : diary.headline)
              Text(
                "\(Date(timeIntervalSince1970:Double(diary.deletedAt!)/1000+30*86400).formatted(date:.abbreviated,time:.omitted)) 삭제 예정"
              ).font(.caption).foregroundStyle(.secondary)
            }
          }
        }
      }
      Section {
        Button("모든 데이터 삭제", role: .destructive) { erase = true }
        Text("Drawry 2.0.0")
        NavigationLink("오픈소스 고지") {
          ScrollView {
            Text(
              ["SQLCipher", "Apache-2.0", "NanumPenScript-OFL"].compactMap { name in
                Bundle.main.url(forResource: name, withExtension: "txt").flatMap {
                  try? String(contentsOf: $0, encoding: .utf8)
                }
              }.joined(separator: "\n\n")
            ).padding()
          }.navigationTitle("오픈소스")
        }
      }
    }.notebookScreen().navigationTitle("설정")
      .navigationDestination(for: String.self) { id in DetailView(model: model, id: id) }
      .fileImporter(isPresented: $importing, allowedContentTypes: [.data, .item]) { result in
        switch result {
        case .success(let url): model.inspect(url, password: password, recovery: recovery)
        case .failure(let error): model.error = error.localizedDescription
        }
      }
      .confirmationDialog("모든 기록을 삭제할까요?", isPresented: $erase, titleVisibility: .visible) {
        Button("인증 후 전체 삭제", role: .destructive) { model.erase() }
      } message: {
        Text("일기·미디어·초안·설정과 기기의 암호화 키를 삭제합니다. 외부 백업은 삭제되지 않습니다. 되돌릴 수 없습니다.")
      }
      .alert(
        "백업 복구 키",
        isPresented: Binding(get: { recoveryCode != nil }, set: { if !$0 { recoveryCode = nil } })
      ) {
        Button("복사") {
          UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: recoveryCode ?? ""]],
            options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(60)])
        }
        Button("닫기", role: .cancel) { recoveryCode = nil }
      } message: {
        Text("이 키를 별도로 안전하게 보관하세요.\n\n\(recoveryCode ?? "")")
      }
      .task(id: model.diaries.map { "\($0.id)-\($0.updatedAt)" }.joined()) {
        await calculateUsage()
      }
  }
  private func calculateUsage() async {
    guard let directory = await model.vault?.mediaDirectory else { return }
    let values = await Task.detached { () -> (Int64, Int64, Int64) in
      var original: Int64 = 0
      var rendered: Int64 = 0
      var thumb: Int64 = 0
      for url
        in (try? FileManager.default.contentsOfDirectory(
          at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
      {
        let size = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        if url.lastPathComponent.contains("thumb") {
          thumb += size
        } else if url.lastPathComponent.contains("render") {
          rendered += size
        } else {
          original += size
        }
      }
      return (original, rendered, thumb)
    }.value
    usage =
      "원본 \(values.0/1024/1024)MB · 편집본 \(values.1/1024/1024)MB · 미리 보기 \(values.2/1024/1024)MB"
  }
}
struct ShareOptionsView: View {
  @Bindable var model: AppModel
  let diary: Diary
  @Environment(\.dismiss) private var dismiss
  @State private var preferences = Preferences()
  @State private var preview: URL?
  @State private var image: UIImage?
  @State private var sharing = false
  var body: some View {
    NavigationStack {
      Form {
        Section("포함할 항목") {
          ForEach(
            [
              ("headline", "한 줄"), ("body", "본문"), ("date", "날짜"), ("mood", "기분"),
              ("weather", "날씨"),
            ], id: \.0
          ) { key, label in
            Toggle(
              label,
              isOn: Binding(
                get: { preferences.shareFields.contains(key) },
                set: { enabled in
                  if enabled {
                    preferences.shareFields.append(key)
                  } else {
                    preferences.shareFields.removeAll { $0 == key }
                  }
                  invalidate()
                }))
          }
        }
        Section {
          Picker("비율", selection: $preferences.shareRatio) {
            Text("4:5").tag("4:5")
            Text("1:1").tag("1:1")
            Text("9:16").tag("9:16")
          }.onChange(of: preferences.shareRatio) { _, _ in invalidate() }
          Picker("테마", selection: $preferences.shareTheme) {
            Text("밝게").tag("light")
            Text("어둡게").tag("dark")
          }.onChange(of: preferences.shareTheme) { _, _ in invalidate() }
          Toggle("Drawry 워터마크", isOn: $preferences.watermark).onChange(of: preferences.watermark) {
            _, _ in invalidate()
          }
        }
        if let image { Section("공유 결과") { Image(uiImage: image).resizable().scaledToFit() } }
        Section {
          Button(preview == nil ? "미리 보기" : "이미지 공유") {
            if preview == nil {
              model.run {
                preview = try await model.media?.share(diary, preferences: preferences)
                if let preview { image = try MediaStore.decode(preview, maximum: 800) }
              }
            } else {
              model.run {
                try await model.vault?.preferences(preferences)
                try await model.refresh()
                sharing = true
              }
            }
          }
        }
      }.notebookScreen().navigationTitle("공유 이미지").toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("닫기") {
            invalidate()
            dismiss()
          }
        }
      }
    }.onAppear { preferences = model.preferences }
      .sheet(isPresented: $sharing) {
        if let preview {
          ShareSheet(file: preview) {
            invalidate()
            sharing = false
            dismiss()
          }
        }
      }
      .overlay { if model.busy { BusyView() } }
  }
  private func invalidate() {
    if let preview { try? FileManager.default.removeItem(at: preview) }
    preview = nil
    image = nil
  }
}
