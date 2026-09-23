import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:get_video_thumbnail/get_video_thumbnail.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/diary/domain/diary.dart';
import '../crypto/chunked_cipher.dart';

final class MediaLimits {
  const MediaLimits({
    this.maxItems = 10,
    this.maxVideos = 3,
    this.maxVideoDuration = const Duration(seconds: 30),
    this.maxCombinedVideoDuration = const Duration(seconds: 60),
    this.maxImportBytes = 300 * 1024 * 1024,
  });

  final int maxItems;
  final int maxVideos;
  final Duration maxVideoDuration;
  final Duration maxCombinedVideoDuration;
  final int maxImportBytes;
}

final class MediaStorage {
  MediaStorage({ChunkedCipher? cipher, Uuid? uuid})
    : _cipher = cipher ?? ChunkedCipher(),
      _uuid = uuid ?? const Uuid();

  final ChunkedCipher _cipher;
  final Uuid _uuid;

  Future<Directory> _vaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'secure', 'media'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _cacheDirectory() async {
    final cache = await getTemporaryDirectory();
    final directory = Directory(p.join(cache.path, 'drawry-view'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<DiaryMedia> importImage(
    XFile source, {
    bool preserveOriginal = false,
  }) async {
    final sourceLength = await source.length();
    if (sourceLength > const MediaLimits().maxImportBytes) {
      throw const FormatException('이미지 파일이 300MB를 초과합니다.');
    }
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) throw const FormatException('빈 이미지입니다.');
    final result = await Isolate.run(
      () => _normalizeImage(bytes, preserveOriginal: preserveOriginal),
    );
    final id = _uuid.v4();
    final key = _cipher.generateKey();
    final vault = await _vaultDirectory();
    final temporary = await getTemporaryDirectory();
    final normalized = File(p.join(temporary.path, '$id.${result.extension}'));
    final thumbnail = File(p.join(temporary.path, '$id.thumb.jpg'));
    await normalized.writeAsBytes(result.bytes, flush: true);
    await thumbnail.writeAsBytes(result.thumbnail, flush: true);

    final encrypted = File(p.join(vault.path, '$id.media'));
    final encryptedThumbnail = File(p.join(vault.path, '$id.thumb'));
    try {
      await _cipher.encryptFile(
        source: normalized,
        destination: encrypted,
        key: key,
        fileId: id,
      );
      await _cipher.encryptFile(
        source: thumbnail,
        destination: encryptedThumbnail,
        key: key,
        fileId: '$id:thumb',
      );
    } finally {
      if (await normalized.exists()) await normalized.delete();
      if (await thumbnail.exists()) await thumbnail.delete();
    }

    return DiaryMedia(
      id: id,
      kind: DiaryMediaKind.image,
      mimeType: result.mimeType,
      encryptedPath: p.basename(encrypted.path),
      thumbnailPath: p.basename(encryptedThumbnail.path),
      key: key,
      byteLength: result.bytes.length,
      width: result.width,
      height: result.height,
    );
  }

  Future<DiaryMedia> importVideo(
    XFile source, {
    required Duration duration,
    String mimeType = 'video/mp4',
  }) async {
    if (duration > const Duration(seconds: 30)) {
      throw const FormatException('영상은 30초 이하여야 합니다.');
    }
    final sourceFile = File(source.path);
    final length = await sourceFile.length();
    if (length > 300 * 1024 * 1024) {
      throw const FormatException('영상 파일이 300MB를 초과합니다.');
    }
    final id = _uuid.v4();
    final key = _cipher.generateKey();
    final vault = await _vaultDirectory();
    final encrypted = File(p.join(vault.path, '$id.media'));
    final encryptedThumbnail = File(p.join(vault.path, '$id.thumb'));
    final thumbnailBytes = await VideoThumbnail.thumbnailData(
      video: source.path,
      maxWidth: 512,
      timeMs: 0,
      quality: 82,
    );
    if (thumbnailBytes.isEmpty) {
      throw const FormatException('영상 대표 이미지를 만들지 못했습니다.');
    }
    final temporary = await getTemporaryDirectory();
    final thumbnail = File(p.join(temporary.path, '$id.video-thumb.jpg'));
    await thumbnail.writeAsBytes(thumbnailBytes, flush: true);
    try {
      await _cipher.encryptFile(
        source: sourceFile,
        destination: encrypted,
        key: key,
        fileId: id,
      );
      await _cipher.encryptFile(
        source: thumbnail,
        destination: encryptedThumbnail,
        key: key,
        fileId: '$id:thumb',
      );
    } catch (_) {
      if (await encrypted.exists()) await encrypted.delete();
      if (await encryptedThumbnail.exists()) await encryptedThumbnail.delete();
      key.fillRange(0, key.length, 0);
      rethrow;
    } finally {
      if (await thumbnail.exists()) await thumbnail.delete();
    }
    return DiaryMedia(
      id: id,
      kind: DiaryMediaKind.video,
      mimeType: mimeType,
      encryptedPath: p.basename(encrypted.path),
      thumbnailPath: p.basename(encryptedThumbnail.path),
      key: key,
      byteLength: length,
      duration: duration,
      representativeFrame: Duration.zero,
    );
  }

  Future<DiaryMedia> updateVideoRepresentative(
    DiaryMedia media,
    Duration position,
  ) async {
    if (media.kind != DiaryMediaKind.video) {
      throw ArgumentError('영상 미디어만 대표 화면을 변경할 수 있습니다.');
    }
    final duration = media.duration ?? Duration.zero;
    if (position.isNegative || position > duration) {
      throw RangeError.range(
        position.inMilliseconds,
        0,
        duration.inMilliseconds,
        'position',
      );
    }
    final video = await materialize(media);
    final bytes = await VideoThumbnail.thumbnailData(
      video: video.path,
      maxWidth: 512,
      timeMs: position.inMilliseconds,
      quality: 82,
    );
    if (bytes.isEmpty) {
      throw const FormatException('선택한 영상 화면을 만들지 못했습니다.');
    }
    final temporary = await getTemporaryDirectory();
    final clear = File(p.join(temporary.path, '${media.id}.frame.png'));
    final encryptedTemporary = File(
      p.join(temporary.path, '${media.id}.frame.dry'),
    );
    await clear.writeAsBytes(bytes, flush: true);
    final vault = await _vaultDirectory();
    final thumbnailName = media.thumbnailPath ?? '${media.id}.thumb';
    final destination = File(p.join(vault.path, thumbnailName));
    try {
      await _cipher.encryptFile(
        source: clear,
        destination: encryptedTemporary,
        key: media.key,
        fileId: '${media.id}:thumb',
      );
      if (await destination.exists()) await destination.delete();
      await encryptedTemporary.rename(destination.path);
    } finally {
      if (await clear.exists()) await clear.delete();
      if (await encryptedTemporary.exists()) await encryptedTemporary.delete();
      final cache = await _cacheDirectory();
      final cached = File(p.join(cache.path, '${media.id}.thumb.jpg'));
      if (await cached.exists()) await cached.delete();
    }
    return media.copyWith(
      thumbnailPath: thumbnailName,
      representativeFrame: position,
    );
  }

  Future<File> materialize(DiaryMedia media, {bool thumbnail = false}) async {
    final vault = await _vaultDirectory();
    final cache = await _cacheDirectory();
    final encryptedName = thumbnail ? media.thumbnailPath : media.encryptedPath;
    if (encryptedName == null) throw StateError('썸네일이 없습니다.');
    final extension = thumbnail
        ? 'jpg'
        : media.kind == DiaryMediaKind.video
        ? 'mp4'
        : media.mimeType == 'image/png'
        ? 'png'
        : 'jpg';
    final output = File(
      p.join(cache.path, '${media.id}${thumbnail ? '.thumb' : ''}.$extension'),
    );
    if (await output.exists() && await output.length() > 0) return output;
    await _cipher.decryptFile(
      source: File(p.join(vault.path, encryptedName)),
      destination: output,
      key: media.key,
      fileId: thumbnail ? '${media.id}:thumb' : media.id,
    );
    return output;
  }

  Future<bool> containsEncrypted(DiaryMedia media) async {
    final vault = await _vaultDirectory();
    return File(p.join(vault.path, media.encryptedPath)).exists();
  }

  Future<void> deleteMedia(DiaryMedia media) async {
    final vault = await _vaultDirectory();
    final cache = await _cacheDirectory();
    final names = <String?>[
      media.encryptedPath,
      media.thumbnailPath,
      media.renderedPath,
    ];
    for (final name in names.whereType<String>()) {
      final file = File(p.join(vault.path, name));
      if (await file.exists()) await file.delete();
    }
    await for (final entity in cache.list()) {
      if (entity is File && p.basename(entity.path).startsWith(media.id)) {
        await entity.delete();
      }
    }
    media.key.fillRange(0, media.key.length, 0);
  }

  Future<void> clearMaterializedCache() async {
    final cache = await _cacheDirectory();
    if (!await cache.exists()) return;
    await for (final entity in cache.list()) {
      if (entity is File) await entity.delete();
    }
  }

  Future<void> clearTemporaryArtifacts() async {
    final temporary = await getTemporaryDirectory();
    await for (final entity in temporary.list()) {
      final name = p.basename(entity.path);
      if (entity is File &&
          name.startsWith('drawry-share-') &&
          name.endsWith('.png')) {
        await entity.delete();
      } else if (entity is Directory && name == 'drawry-backup-work') {
        await entity.delete(recursive: true);
      }
    }
  }
}

final class _NormalizedImage {
  const _NormalizedImage({
    required this.bytes,
    required this.thumbnail,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.extension,
  });

  final Uint8List bytes;
  final Uint8List thumbnail;
  final int width;
  final int height;
  final String mimeType;
  final String extension;
}

_NormalizedImage _normalizeImage(
  Uint8List input, {
  required bool preserveOriginal,
}) {
  final decoded = img.decodeImage(input);
  if (decoded == null) throw const FormatException('지원하지 않는 이미지입니다.');
  final oriented = img.bakeOrientation(decoded);
  final longest = max(oriented.width, oriented.height);
  final scale = preserveOriginal || longest <= 2560 ? 1.0 : 2560 / longest;
  final resized = scale == 1.0
      ? oriented
      : img.copyResize(
          oriented,
          width: (oriented.width * scale).round(),
          height: (oriented.height * scale).round(),
          interpolation: img.Interpolation.average,
        );
  final transparent = resized.numChannels == 4;
  final output = Uint8List.fromList(
    transparent ? img.encodePng(resized) : img.encodeJpg(resized, quality: 90),
  );
  final thumbnailImage = img.copyResize(
    resized,
    width: resized.width >= resized.height ? 512 : null,
    height: resized.height > resized.width ? 512 : null,
    interpolation: img.Interpolation.average,
  );
  return _NormalizedImage(
    bytes: output,
    thumbnail: Uint8List.fromList(img.encodeJpg(thumbnailImage, quality: 82)),
    width: resized.width,
    height: resized.height,
    mimeType: transparent ? 'image/png' : 'image/jpeg',
    extension: transparent ? 'png' : 'jpg',
  );
}
