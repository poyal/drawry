import DrawryCore
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct LibraryPicker: UIViewControllerRepresentable {
  let completion: ([(URL, Bool)], String?) -> Void
  func makeUIViewController(context: Context) -> PHPickerViewController {
    var config = PHPickerConfiguration()
    config.selectionLimit = 10
    config.filter = .any(of: [.images, .videos])
    config.preferredAssetRepresentationMode = .current
    let controller = PHPickerViewController(configuration: config)
    controller.delegate = context.coordinator
    return controller
  }
  func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}
  func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
  final class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let completion: ([(URL, Bool)], String?) -> Void
    init(completion: @escaping ([(URL, Bool)], String?) -> Void) { self.completion = completion }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      Task { @MainActor in
        var files: [(URL, Bool)] = []
        var totalBytes = 0
        do {
          for result in results {
            let video = result.itemProvider.hasItemConformingToTypeIdentifier(
              UTType.movie.identifier)
            let type = video ? UTType.movie.identifier : UTType.image.identifier
            let url: URL = try await withCheckedThrowingContinuation { continuation in
              result.itemProvider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
                do {
                  guard let url else { throw error ?? VaultError.unsupported }
                  let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                  guard bytes > 0, bytes <= 300 * 1024 * 1024 else { throw VaultError.mediaLimit }
                  let target = FileManager.default.temporaryDirectory.appendingPathComponent(
                    "picker-\(UUID().uuidString).\(url.pathExtension)")
                  try FileManager.default.copyItem(at: url, to: target)
                  try FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.complete], ofItemAtPath: target.path)
                  continuation.resume(returning: target)
                } catch { continuation.resume(throwing: error) }
              }
            }
            files.append((url, video))
            totalBytes += (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            guard totalBytes <= 300 * 1024 * 1024 else { throw VaultError.mediaLimit }
          }
          completion(files, nil)
        } catch {
          for (url, _) in files { try? FileManager.default.removeItem(at: url) }
          completion([], error.localizedDescription)
        }
      }
    }
  }
}
struct CameraPicker: UIViewControllerRepresentable {
  let completion: (URL?, Bool, String?) -> Void
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let controller = UIImagePickerController()
    controller.sourceType = .camera
    controller.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
    controller.videoMaximumDuration = 30
    controller.videoQuality = .typeHigh
    controller.delegate = context.coordinator
    return controller
  }
  func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
  func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
  {
    let completion: (URL?, Bool, String?) -> Void
    init(completion: @escaping (URL?, Bool, String?) -> Void) { self.completion = completion }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      completion(nil, false, nil)
    }
    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      do {
        if let video = info[.mediaURL] as? URL {
          let target = FileManager.default.temporaryDirectory.appendingPathComponent(
            "camera-\(UUID().uuidString).mov")
          try FileManager.default.copyItem(at: video, to: target)
          completion(target, true, nil)
        } else if let image = info[.originalImage] as? UIImage {
          let target = FileManager.default.temporaryDirectory.appendingPathComponent(
            "camera-\(UUID().uuidString).jpg")
          try MediaStore.jpeg(image).write(to: target, options: .completeFileProtection)
          completion(target, false, nil)
        } else {
          throw VaultError.unsupported
        }
      } catch { completion(nil, false, error.localizedDescription) }
    }
  }
}
struct ShareSheet: UIViewControllerRepresentable {
  let file: URL
  let completion: () -> Void
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: [file], applicationActivities: nil)
    controller.completionWithItemsHandler = { _, _, _, _ in completion() }
    return controller
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// A window-level cover also hides sheets and alerts in app-switcher snapshots.
struct PrivacyWindowCover: UIViewRepresentable {
  func makeUIView(context: Context) -> GuardView { GuardView() }
  func updateUIView(_ view: GuardView, context: Context) {}
  final class GuardView: UIView {
    private var cover: UIView?
    override init(frame: CGRect) {
      super.init(frame: frame)
      NotificationCenter.default.addObserver(
        self, selector: #selector(hideContent), name: UIApplication.willResignActiveNotification,
        object: nil)
      NotificationCenter.default.addObserver(
        self, selector: #selector(showContent), name: UIApplication.didBecomeActiveNotification,
        object: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    deinit { NotificationCenter.default.removeObserver(self) }
    @objc private func hideContent() {
      guard let window, cover == nil else { return }
      let view = UIView(frame: window.bounds)
      view.backgroundColor = .systemBackground
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      let label = UILabel(frame: view.bounds)
      label.text = "Drawry 🔒"
      label.textAlignment = .center
      label.font = .preferredFont(forTextStyle: .title1)
      label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.addSubview(label)
      window.addSubview(view)
      cover = view
    }
    @objc private func showContent() {
      cover?.removeFromSuperview()
      cover = nil
    }
  }
}
