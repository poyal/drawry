import DrawryCore
import Foundation
import LocalAuthentication
import Observation

@MainActor @Observable final class AppModel {
  var vault: Vault?
  var media: MediaStore?
  var diaries: [Diary] = []
  var preferences = Preferences()
  var editor: Diary?
  var draft: Diary?
  var busy = false
  var canCancel = false
  var ready = false
  var locked = true
  var covered = false
  var error: String?
  var erased = false
  var pendingRestore: (Snapshot, URL)?
  var sharedFile: URL?
  private var autosave: Task<Void, Never>?
  private var operation: Task<Void, Never>?
  private var privacyTask: Task<Void, Never>?
  private var backgroundAt: TimeInterval?
  init() { run { try await self.open() } }
  func open() async throws {
    let vault = try Vault()
    self.vault = vault
    media = MediaStore(vault: vault)
    try await vault.initialize()
    try await refresh()
    locked = preferences.lockEnabled
    ready = true
  }
  func run(cancellable: Bool = false, _ work: @escaping @MainActor () async throws -> Void) {
    guard !busy else { return }
    busy = true
    canCancel = cancellable
    operation = Task {
      defer {
        busy = false
        canCancel = false
      }
      do { try await work() } catch is CancellationError {} catch {
        self.error = error.localizedDescription
      }
    }
  }
  func cancelOperation() { if canCancel { operation?.cancel() } }
  func refresh() async throws {
    guard let vault else { return }
    diaries = try await vault.diaries()
    preferences = try await vault.preferences()
    draft = try await vault.draft()
  }
  func setPreferences(_ value: Preferences) {
    run {
      try await self.vault?.preferences(value)
      self.preferences = value
    }
  }
  func startEditor(_ diary: Diary? = nil) { editor = diary ?? draft ?? Diary() }
  func update(_ value: Diary) {
    editor = value
    autosave?.cancel()
    autosave = Task {
      do {
        try await Task.sleep(for: .milliseconds(300))
        try Task.checkCancellation()
        try await vault?.draft(value)
        draft = value
      } catch is CancellationError {} catch { self.error = "초안을 저장하지 못했습니다." }
    }
  }
  func leaveEditor(discard: Bool) {
    run {
      self.autosave?.cancel()
      await self.autosave?.value
      try await self.vault?.draft(discard ? nil : self.editor)
      self.editor = nil
      try await self.refresh()
    }
  }
  func save() {
    run {
      self.autosave?.cancel()
      await self.autosave?.value
      guard let value = self.editor else { return }
      try await self.vault?.save(value)
      self.editor = nil
      try await self.refresh()
    }
  }
  func importFiles(_ files: [(URL, Bool)], preserve: Bool) {
    run(cancellable: true) {
      defer { for (url, _) in files { try? FileManager.default.removeItem(at: url) } }
      guard let media = self.media, let vault = self.vault else { return }
      for (url, video) in files {
        guard var value = self.editor else { return }
        guard value.media.count < 10 else { throw VaultError.mediaLimit }
        let item = try await media.importFile(url, video: video, preserve: preserve)
        value.media.append(item)
        do {
          try value.validate()
          self.autosave?.cancel()
          await self.autosave?.value
          try await vault.draft(value)
          self.editor = value
          self.draft = value
        } catch {
          for name in item.files {
            try? FileManager.default.removeItem(
              at: await vault.mediaDirectory.appendingPathComponent(name))
          }
          throw error
        }
      }
    }
  }
  func edit(_ item: Media, recipe: EditRecipe) {
    run {
      guard let media = self.media else { return }
      try await self.replaceMedia(media.edit(item, recipe: recipe))
    }
  }
  func frame(_ item: Media, millis: Int64) {
    run {
      guard let media = self.media else { return }
      try await self.replaceMedia(media.frame(item, millis: millis))
    }
  }
  private func replaceMedia(_ value: Media) async throws {
    guard var editor else { return }
    editor.media = editor.media.map { $0.id == value.id ? value : $0 }
    autosave?.cancel()
    await autosave?.value
    try await vault?.draft(editor)
    self.editor = editor
    self.draft = editor
  }
  func trash(_ diary: Diary, restore: Bool = false) {
    run {
      try await self.vault?.trash(diary, restore: restore)
      try await self.refresh()
    }
  }
  func purge(_ diary: Diary) {
    run {
      try await self.vault?.purge(diary.id)
      try await self.refresh()
    }
  }
  func authenticate(_ success: @escaping @MainActor () -> Void) {
    let context = LAContext()
    var failure: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &failure) else {
      error = "기기 설정에서 암호 또는 생체 인증을 먼저 설정해 주세요."
      return
    }
    Task {
      do {
        if try await context.evaluatePolicy(
          .deviceOwnerAuthentication, localizedReason: "나만의 Drawry 기록을 확인합니다.")
        {
          success()
        }
      } catch { self.error = error.localizedDescription }
    }
  }
  func background() {
    covered = true
    if backgroundAt == nil { backgroundAt = ProcessInfo.processInfo.systemUptime }
    privacyTask = Task {
      await media?.clearViewing()
      if let editor { try? await vault?.draft(editor) }
    }
  }
  func foreground() {
    Task {
      await privacyTask?.value
      await media?.allowViewing()
    }
    if preferences.lockEnabled, let time = backgroundAt,
      ProcessInfo.processInfo.systemUptime - time >= Double(preferences.graceSeconds)
    {
      locked = true
    }
    backgroundAt = nil
    covered = false
    if ready && !busy {
      run {
        try await self.vault?.purgeExpired()
        try await self.refresh()
      }
    }
  }
  func inspect(_ url: URL, password: String, recovery: String) {
    run(cancellable: true) {
      guard let vault = self.vault else { return }
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      self.pendingRestore = try await vault.inspect(
        source: url, password: password.isEmpty ? nil : password,
        recovery: recovery.isEmpty
          ? nil : Data(base64Encoded: recovery.trimmingCharacters(in: .whitespacesAndNewlines)))
    }
  }
  func restore(replace: Bool) {
    guard let pending = pendingRestore, !busy else { return }
    pendingRestore = nil
    run {
      try await self.vault?.restore(snapshot: pending.0, stage: pending.1, replace: replace)
      try await self.refresh()
    }
  }
  func cancelRestore() {
    if let pendingRestore { try? FileManager.default.removeItem(at: pendingRestore.1) }
    pendingRestore = nil
  }
  func erase() {
    authenticate {
      self.run {
        try await self.vault?.erase()
        self.diaries = []
        self.editor = nil
        self.draft = nil
        self.erased = true
        self.locked = false
      }
    }
  }
}
