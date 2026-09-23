import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/media/media_storage.dart';
import '../domain/diary.dart';

abstract interface class DiaryRepository {
  Stream<List<Diary>> watchActive();

  Stream<List<Diary>> watchTrash();

  Future<Diary?> getById(String id);

  Future<String> save(DiaryDraft draft);

  Future<void> moveToTrash(String id);

  Future<void> restore(String id);

  Future<void> deletePermanently(String id);

  Future<int> purgeExpired();
}

final class DriftDiaryRepository implements DiaryRepository {
  DriftDiaryRepository(this._database, this._mediaStorage, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final MediaStorage _mediaStorage;
  final Uuid _uuid;

  @override
  Stream<List<Diary>> watchActive() =>
      _database.watchActiveDiaries().asyncMap(_hydrateMany);

  @override
  Stream<List<Diary>> watchTrash() =>
      _database.watchTrash().asyncMap(_hydrateMany);

  Future<List<Diary>> _hydrateMany(List<DiaryRow> rows) =>
      Future.wait(rows.map(_hydrate));

  @override
  Future<Diary?> getById(String id) async {
    final row = await (_database.select(
      _database.diaries,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    return row == null ? null : _hydrate(row);
  }

  Future<Diary> _hydrate(DiaryRow row) async {
    final mediaRows = await _database.mediaForDiary(row.id);
    final weather = await _database.weatherForDiary(row.id);
    return Diary(
      id: row.id,
      entryDate: DateTime.parse(row.entryDate),
      entryTime: Duration(minutes: row.entryTimeMinutes),
      utcOffsetMinutes: row.utcOffsetMinutes,
      headline: row.headline,
      body: row.body,
      mood: row.mood,
      tags: _stringList(row.tagsJson),
      companions: _stringList(row.companionsJson),
      media: mediaRows.map(_mediaFromRow).toList(growable: false),
      weather: weather == null ? null : _weatherFromRow(weather),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtEpoch,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtEpoch,
        isUtc: true,
      ),
      deletedAt: row.deletedAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.deletedAtEpoch!,
              isUtc: true,
            ),
      purgeAt: row.purgeAtEpoch == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.purgeAtEpoch!, isUtc: true),
    );
  }

  @override
  Future<String> save(DiaryDraft draft) async {
    if (draft.media.isEmpty) throw ArgumentError('미디어가 한 개 이상 필요합니다.');
    _validateMedia(draft.media);
    final now = DateTime.now().toUtc();
    final id = draft.id ?? _uuid.v4();
    final existing = draft.id == null ? null : await getById(id);
    final local = draft.entryDateTime;
    final date = DateTime(local.year, local.month, local.day);
    final timeMinutes = local.hour * 60 + local.minute;

    await _database.transaction(() async {
      await _database
          .into(_database.diaries)
          .insertOnConflictUpdate(
            DiariesCompanion.insert(
              id: id,
              entryDate: _dateText(date),
              entryTimeMinutes: timeMinutes,
              utcOffsetMinutes: local.timeZoneOffset.inMinutes,
              headline: Value(_clean(draft.headline)),
              body: Value(_clean(draft.body)),
              mood: Value(_clean(draft.mood)),
              tagsJson: Value(jsonEncode(_normalizedList(draft.tags))),
              companionsJson: Value(
                jsonEncode(_normalizedList(draft.companions)),
              ),
              createdAtEpoch:
                  existing?.createdAt.millisecondsSinceEpoch ??
                  now.millisecondsSinceEpoch,
              updatedAtEpoch: now.millisecondsSinceEpoch,
            ),
          );
      await (_database.delete(
        _database.mediaEntries,
      )..where((row) => row.diaryId.equals(id))).go();
      for (var index = 0; index < draft.media.length; index++) {
        await _database
            .into(_database.mediaEntries)
            .insert(_mediaCompanion(id, draft.media[index], index));
      }
      await (_database.delete(
        _database.weatherEntries,
      )..where((row) => row.diaryId.equals(id))).go();
      final weather = draft.weather;
      if (weather != null && !weather.isEmpty) {
        await _database
            .into(_database.weatherEntries)
            .insert(
              WeatherEntriesCompanion.insert(
                diaryId: id,
                condition: Value(weather.condition?.name),
                temperature: Value(weather.temperature),
                minimumTemperature: Value(weather.minimumTemperature),
                maximumTemperature: Value(weather.maximumTemperature),
                precipitation: Value(weather.precipitation),
                displayMask: Value(weather.displayMask),
              ),
            );
      }
    });

    if (existing != null) {
      final retained = draft.media.map((media) => media.id).toSet();
      for (final old in existing.media) {
        if (!retained.contains(old.id)) await _mediaStorage.deleteMedia(old);
      }
    }
    return id;
  }

  @override
  Future<void> moveToTrash(String id) async {
    final now = DateTime.now().toUtc();
    await (_database.update(
      _database.diaries,
    )..where((row) => row.id.equals(id))).write(
      DiariesCompanion(
        deletedAtEpoch: Value(now.millisecondsSinceEpoch),
        purgeAtEpoch: Value(
          now.add(const Duration(days: 30)).millisecondsSinceEpoch,
        ),
        updatedAtEpoch: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> restore(String id) async {
    await (_database.update(
      _database.diaries,
    )..where((row) => row.id.equals(id))).write(
      DiariesCompanion(
        deletedAtEpoch: const Value(null),
        purgeAtEpoch: const Value(null),
        updatedAtEpoch: Value(DateTime.now().toUtc().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> deletePermanently(String id) async {
    final diary = await getById(id);
    if (diary == null) return;
    await (_database.delete(
      _database.diaries,
    )..where((row) => row.id.equals(id))).go();
    for (final media in diary.media) {
      await _mediaStorage.deleteMedia(media);
    }
  }

  @override
  Future<int> purgeExpired() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final rows = await (_database.select(
      _database.diaries,
    )..where((row) => row.purgeAtEpoch.isSmallerOrEqualValue(now))).get();
    for (final row in rows) {
      await deletePermanently(row.id);
    }
    return rows.length;
  }

  MediaEntriesCompanion _mediaCompanion(
    String diaryId,
    DiaryMedia media,
    int sortOrder,
  ) => MediaEntriesCompanion.insert(
    id: media.id,
    diaryId: diaryId,
    sortOrder: sortOrder,
    kind: media.kind.name,
    mimeType: media.mimeType,
    encryptedPath: media.encryptedPath,
    thumbnailPath: Value(media.thumbnailPath),
    renderedPath: Value(media.renderedPath),
    mediaKeyBase64: base64UrlEncode(media.key),
    byteLength: media.byteLength,
    width: Value(media.width),
    height: Value(media.height),
    durationMillis: Value(media.duration?.inMilliseconds),
    representativeMillis: Value(media.representativeFrame?.inMilliseconds),
    editHistoryJson: Value(media.editHistoryJson),
  );

  DiaryMedia _mediaFromRow(MediaRow row) => DiaryMedia(
    id: row.id,
    kind: DiaryMediaKind.values.byName(row.kind),
    mimeType: row.mimeType,
    encryptedPath: row.encryptedPath,
    thumbnailPath: row.thumbnailPath,
    renderedPath: row.renderedPath,
    key: Uint8List.fromList(base64Url.decode(row.mediaKeyBase64)),
    byteLength: row.byteLength,
    width: row.width,
    height: row.height,
    duration: row.durationMillis == null
        ? null
        : Duration(milliseconds: row.durationMillis!),
    representativeFrame: row.representativeMillis == null
        ? null
        : Duration(milliseconds: row.representativeMillis!),
    editHistoryJson: row.editHistoryJson,
  );

  WeatherEntry _weatherFromRow(WeatherRow row) => WeatherEntry(
    condition: row.condition == null
        ? null
        : WeatherCondition.values.byName(row.condition!),
    temperature: row.temperature,
    minimumTemperature: row.minimumTemperature,
    maximumTemperature: row.maximumTemperature,
    precipitation: row.precipitation,
    displayMask: row.displayMask,
  );

  void _validateMedia(List<DiaryMedia> media) {
    const limits = MediaLimits();
    if (media.length > limits.maxItems) {
      throw ArgumentError('미디어는 최대 ${limits.maxItems}개까지 추가할 수 있습니다.');
    }
    final videos = media.where((item) => item.kind == DiaryMediaKind.video);
    if (videos.length > limits.maxVideos) {
      throw ArgumentError('영상은 최대 ${limits.maxVideos}개까지 추가할 수 있습니다.');
    }
    final videoDuration = videos.fold<Duration>(
      Duration.zero,
      (total, item) => total + (item.duration ?? Duration.zero),
    );
    if (videoDuration > limits.maxCombinedVideoDuration) {
      throw ArgumentError('영상 총길이는 60초 이하여야 합니다.');
    }
    final totalBytes = media.fold<int>(
      0,
      (total, item) => total + item.byteLength,
    );
    if (totalBytes > limits.maxImportBytes) {
      throw ArgumentError('미디어 전체 용량은 300MB 이하여야 합니다.');
    }
  }

  String? _clean(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? null : clean;
  }

  List<String> _normalizedList(List<String> values) => values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false);

  List<String> _stringList(String source) =>
      (jsonDecode(source) as List<dynamic>).cast<String>();

  String _dateText(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
