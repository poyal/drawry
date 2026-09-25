import AVFoundation
import CoreImage
import DrawryCore
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

actor MediaStore {
  private var viewingAllowed = true
  func allowViewing() { viewingAllowed = true }
  let vault: Vault
  init(vault: Vault) { self.vault = vault }
  func importFile(_ source: URL, video: Bool, preserve: Bool) async throws -> Media {
    let fm = FileManager.default
    let directory = await vault.mediaDirectory
    let cache = await vault.cache
    let size = try source.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    guard size > 0, size <= 300 * 1024 * 1024 else { throw VaultError.mediaLimit }
    let free =
      (try fm.attributesOfFileSystem(forPath: directory.path)[.systemFreeSize] as? NSNumber)?
      .int64Value ?? 0
    guard free > Int64(size) * 2 + 32 * 1024 * 1024 else { throw VaultError.insufficientSpace }
    var media = Media()
    media.kind = video ? "video" : "image"
    media.mimeType =
      video || preserve
      ? (UTType(filenameExtension: source.pathExtension)?.preferredMIMEType
        ?? (video ? "video/quicktime" : "image/jpeg")) : "image/jpeg"
    let key = try ChunkCipher.random(32)
    media.key = key.base64EncodedString()
    media.byteLength = Int64(size)
    let image: UIImage
    if video {
      let asset = AVURLAsset(url: source)
      let duration = try await asset.load(.duration)
      media.durationMillis = Int64(CMTimeGetSeconds(duration) * 1000)
      guard (1...30_000).contains(media.durationMillis) else { throw VaultError.mediaLimit }
      image = try frameImage(source, millis: 0)
    } else {
      image = try Self.decode(source, maximum: 2560)
    }
    media.original = "\(media.id).\(video ? "mov" : preserve ? "source" : "jpg").dry"
    media.thumbnail = "\(media.id).thumb.dry"
    let plain = cache.appendingPathComponent("\(media.id).jpg")
    let thumb = cache.appendingPathComponent("\(media.id).thumb.jpg")
    var success = false
    defer {
      try? fm.removeItem(at: plain)
      try? fm.removeItem(at: thumb)
      if !success {
        for name in media.files { try? fm.removeItem(at: directory.appendingPathComponent(name)) }
      }
    }
    if !video && !preserve {
      try Self.jpeg(image).write(to: plain, options: [.atomic, .completeFileProtection])
    }
    try Self.jpeg(Self.scale(image, maximum: 480)).write(
      to: thumb, options: [.atomic, .completeFileProtection])
    try ChunkCipher.encrypt(
      source: video || preserve ? source : plain,
      destination: directory.appendingPathComponent(media.original), key: key,
      context: media.original)
    try ChunkCipher.encrypt(
      source: thumb, destination: directory.appendingPathComponent(media.thumbnail), key: key,
      context: media.thumbnail)
    success = true
    return media
  }
  func clearFile(_ media: Media, thumbnail: Bool = false, original: Bool = false) async throws
    -> URL
  {
    let name =
      thumbnail ? media.thumbnail : original ? media.original : media.rendered ?? media.original
    let directory = await vault.mediaDirectory
    let cache = await vault.cache.appendingPathComponent("view")
    guard viewingAllowed else { throw VaultError.authentication }
    try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
    let url = cache.appendingPathComponent(String(name.dropLast(4)))
    if !FileManager.default.fileExists(atPath: url.path) {
      guard let key = Data(base64Encoded: media.key) else { throw VaultError.invalidData }
      try ChunkCipher.decrypt(
        source: directory.appendingPathComponent(name), destination: url, key: key, context: name)
      try FileManager.default.setAttributes(
        [.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
    }
    return url
  }
  func image(_ media: Media, full: Bool = false) async throws -> UIImage {
    try Self.decode(
      await clearFile(media, thumbnail: !full || media.kind == "video"), maximum: full ? 1600 : 480)
  }
  func edit(_ media: Media, recipe: EditRecipe) async throws -> Media {
    let source = try await clearFile(media, original: true)
    let image = try Self.render(Self.decode(source, maximum: 2560), recipe: recipe)
    return try await saveRendered(media, image: image, recipe: recipe)
  }
  func frame(_ media: Media, millis: Int64) async throws -> Media {
    let source = try await clearFile(media, original: true)
    var result = try await saveRendered(
      media, image: frameImage(source, millis: millis), recipe: media.edit)
    result.representativeMillis = millis
    return result
  }
  private func frameImage(_ url: URL, millis: Int64) throws -> UIImage {
    let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 2560, height: 2560)
    return UIImage(
      cgImage: try generator.copyCGImage(
        at: CMTime(value: millis, timescale: 1000), actualTime: nil))
  }
  func previewFrame(_ media: Media, millis: Int64) async throws -> UIImage {
    let url = try await clearFile(media, original: true)
    return Self.scale(try frameImage(url, millis: millis), maximum: 720)
  }
  private func saveRendered(_ media: Media, image: UIImage, recipe: EditRecipe) async throws
    -> Media
  {
    let id = UUID().uuidString.lowercased()
    let directory = await vault.mediaDirectory
    let cache = await vault.cache
    let plain = cache.appendingPathComponent("\(id).jpg")
    let thumb = cache.appendingPathComponent("\(id).thumb.jpg")
    var updated = media
    updated.rendered = "\(id).render.jpg.dry"
    updated.thumbnail = "\(id).thumb.dry"
    updated.edit = recipe
    guard let key = Data(base64Encoded: media.key) else { throw VaultError.invalidData }
    var success = false
    defer {
      try? FileManager.default.removeItem(at: plain)
      try? FileManager.default.removeItem(at: thumb)
      if !success {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(updated.rendered!))
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(updated.thumbnail))
      }
    }
    try Self.jpeg(image).write(to: plain, options: .completeFileProtection)
    try Self.jpeg(Self.scale(image, maximum: 480)).write(
      to: thumb, options: .completeFileProtection)
    try ChunkCipher.encrypt(
      source: plain, destination: directory.appendingPathComponent(updated.rendered!), key: key,
      context: updated.rendered!)
    try ChunkCipher.encrypt(
      source: thumb, destination: directory.appendingPathComponent(updated.thumbnail), key: key,
      context: updated.thumbnail)
    success = true
    return updated
  }
  func share(_ diary: Diary, preferences: Preferences) async throws -> URL {
    guard let media = diary.media.first else { throw VaultError.invalidData }
    let source = try await clearFile(
      media, thumbnail: media.kind == "video" && media.rendered == nil)
    let photo = try Self.decode(source, maximum: 1600)
    let height: CGFloat =
      preferences.shareRatio == "1:1" ? 1080 : preferences.shareRatio == "9:16" ? 1920 : 1350
    let dark = preferences.shareTheme == "dark"
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    let image = UIGraphicsImageRenderer(size: CGSize(width: 1080, height: height), format: format)
      .image { ctx in
        (dark
          ? InkDrawing.color("#211E1B")
          : InkDrawing.color("#F7F3EA")).setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 1080, height: height))
        (dark ? InkDrawing.color("#292521") : InkDrawing.color("#FFFCF5")).setFill()
        UIBezierPath(
          roundedRect: CGRect(x: 24, y: 24, width: 1032, height: height - 48), cornerRadius: 16
        ).fill()
        let imageRect = CGRect(x: 48, y: 48, width: 984, height: height * 0.62 - 64)
        let ratio = min(imageRect.width / photo.size.width, imageRect.height / photo.size.height)
        ctx.cgContext.saveGState()
        ctx.cgContext.clip(to: imageRect)
        photo.draw(
          in: CGRect(
            x: imageRect.midX - photo.size.width * ratio / 2,
            y: imageRect.midY - photo.size.height * ratio / 2, width: photo.size.width * ratio,
            height: photo.size.height * ratio))
        ctx.cgContext.restoreGState()
        var lines: [String] = []
        for field in preferences.shareFields {
          switch field {
          case "headline": lines.append(diary.headline)
          case "body": lines.append(diary.body)
          case "date": lines.append(diary.entryDate)
          case "mood": lines.append(diary.mood)
          case "weather":
            lines.append(
              diary.weather.condition + (diary.weather.temperature.map { " \($0)°C" } ?? ""))
          default: break
          }
        }
        let attributes: [NSAttributedString.Key: Any] = [
          .font: UIFont.systemFont(ofSize: 34),
          .foregroundColor: dark ? UIColor.white : UIColor.darkGray,
        ]
        (lines.filter { !$0.isEmpty }.joined(separator: "\n") as NSString).draw(
          in: CGRect(x: 40, y: height * 0.62 + 24, width: 1000, height: height * 0.38 - 100),
          withAttributes: attributes)
        if preferences.watermark {
          ("Drawry" as NSString).draw(
            at: CGPoint(x: 40, y: height - 60), withAttributes: attributes)
        }
      }
    let output = await vault.cache.appendingPathComponent("Drawry-share-\(UUID().uuidString).jpg")
    try Self.jpeg(image).write(to: output, options: .completeFileProtection)
    return output
  }
  func clearViewing() async {
    viewingAllowed = false
    try? FileManager.default.removeItem(at: await vault.cache.appendingPathComponent("view"))
  }
  nonisolated static func decode(_ url: URL, maximum: Int) throws -> UIImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maximum,
        ] as CFDictionary)
    else { throw VaultError.unsupported }
    return UIImage(cgImage: image)
  }
  nonisolated static func jpeg(_ image: UIImage) throws -> Data {
    guard let data = image.jpegData(compressionQuality: 0.9) else { throw VaultError.unsupported }
    return data
  }
  nonisolated static func scale(_ image: UIImage, maximum: CGFloat) -> UIImage {
    let factor = min(1, maximum / max(image.size.width, image.size.height))
    let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }
  nonisolated static func render(_ source: UIImage, recipe: EditRecipe) throws -> UIImage {
    try recipe.validateInk()
    let rotatedSize =
      recipe.quarterTurns % 2 == 0
      ? source.size : CGSize(width: source.size.height, height: source.size.width)
    let side = min(rotatedSize.width, rotatedSize.height)
    let size = recipe.squareCrop ? CGSize(width: side, height: side) : rotatedSize
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    let base = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
      ctx.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
      ctx.cgContext.rotate(by: CGFloat(recipe.quarterTurns)*.pi / 2)
      source.draw(
        in: CGRect(
          x: -source.size.width / 2, y: -source.size.height / 2, width: source.size.width,
          height: source.size.height))
    }
    var filtered = base
    if recipe.filter != "original", let ci = CIImage(image: base),
      let filter = CIFilter(name: "CIColorMatrix")
    {
      filter.setValue(ci, forKey: kCIInputImageKey)
      if recipe.filter == "mono" {
        for key in ["inputRVector", "inputGVector", "inputBVector"] {
          filter.setValue(CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0), forKey: key)
        }
      } else {
        filter.setValue(
          CIVector(x: recipe.filter == "warm" ? 1.1 : 0.9, y: 0, z: 0, w: 0), forKey: "inputRVector"
        )
        filter.setValue(
          CIVector(x: 0, y: 0, z: recipe.filter == "warm" ? 0.9 : 1.1, w: 0), forKey: "inputBVector"
        )
      }
      if let output = filter.outputImage,
        let cg = CIContext().createCGImage(output, from: output.extent)
      {
        filtered = UIImage(cgImage: cg)
      }
    }
    return UIGraphicsImageRenderer(size: size, format: format).image { context in
      filtered.draw(in: CGRect(origin: .zero, size: size))
      InkDrawing.draw(
        recipe.strokes, in: context.cgContext,
        geometry: InkGeometry(
          width: source.size.width, height: source.size.height, turns: recipe.quarterTurns,
          square: recipe.squareCrop), size: size)
      for item in recipe.overlays {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black
        shadow.shadowBlurRadius = 3
        shadow.shadowOffset = CGSize(width: 0, height: 2)
        let attrs: [NSAttributedString.Key: Any] = [
          .font: UIFont.systemFont(ofSize: CGFloat(item.size) * size.width),
          .foregroundColor: UIColor.white, .shadow: shadow,
        ]
        let text = item.text as NSString
        let bounds = text.size(withAttributes: attrs)
        text.draw(
          at: CGPoint(
            x: CGFloat(item.x) * size.width - bounds.width / 2,
            y: CGFloat(item.y) * size.height - bounds.height), withAttributes: attrs)
      }
    }
  }
}
