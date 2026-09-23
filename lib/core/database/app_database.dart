import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/secure_key_port.dart';

part 'app_database.g.dart';

@DataClassName('DiaryRow')
class Diaries extends Table {
  TextColumn get id => text()();
  TextColumn get entryDate => text()();
  IntColumn get entryTimeMinutes => integer()();
  IntColumn get utcOffsetMinutes => integer()();
  TextColumn get headline => text().nullable()();
  TextColumn get body => text().nullable()();
  TextColumn get mood => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get companionsJson => text().withDefault(const Constant('[]'))();
  IntColumn get createdAtEpoch => integer()();
  IntColumn get updatedAtEpoch => integer()();
  IntColumn get deletedAtEpoch => integer().nullable()();
  IntColumn get purgeAtEpoch => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MediaRow')
class MediaEntries extends Table {
  TextColumn get id => text()();
  TextColumn get diaryId =>
      text().references(Diaries, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();
  TextColumn get kind => text()();
  TextColumn get mimeType => text()();
  TextColumn get encryptedPath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get renderedPath => text().nullable()();
  TextColumn get mediaKeyBase64 => text()();
  IntColumn get byteLength => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationMillis => integer().nullable()();
  IntColumn get representativeMillis => integer().nullable()();
  TextColumn get editHistoryJson => text().nullable()();
  IntColumn get editVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('WeatherRow')
class WeatherEntries extends Table {
  TextColumn get diaryId =>
      text().references(Diaries, #id, onDelete: KeyAction.cascade)();
  TextColumn get condition => text().nullable()();
  RealColumn get temperature => real().nullable()();
  RealColumn get minimumTemperature => real().nullable()();
  RealColumn get maximumTemperature => real().nullable()();
  BoolColumn get precipitation => boolean().nullable()();
  IntColumn get displayMask => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {diaryId};
}

@DataClassName('DraftRow')
class DraftEntries extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  IntColumn get updatedAtEpoch => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SettingRow')
class SettingEntries extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Diaries, MediaEntries, WeatherEntries, DraftEntries, SettingEntries],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA secure_delete = ON');
    },
  );

  Stream<List<DiaryRow>> watchActiveDiaries() =>
      (select(diaries)
            ..where((row) => row.deletedAtEpoch.isNull())
            ..orderBy([
              (row) => OrderingTerm.desc(row.entryDate),
              (row) => OrderingTerm.desc(row.entryTimeMinutes),
            ]))
          .watch();

  Stream<List<DiaryRow>> watchTrash() =>
      (select(diaries)
            ..where((row) => row.deletedAtEpoch.isNotNull())
            ..orderBy([(row) => OrderingTerm.desc(row.deletedAtEpoch)]))
          .watch();

  Future<List<MediaRow>> mediaForDiary(String diaryId) =>
      (select(mediaEntries)
            ..where((row) => row.diaryId.equals(diaryId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<WeatherRow?> weatherForDiary(String diaryId) => (select(
    weatherEntries,
  )..where((row) => row.diaryId.equals(diaryId))).getSingleOrNull();

  Future<DraftRow?> draftById(String id) => (select(
    draftEntries,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<void> putDraft(String id, String payloadJson) =>
      into(draftEntries).insertOnConflictUpdate(
        DraftEntriesCompanion.insert(
          id: id,
          payloadJson: payloadJson,
          updatedAtEpoch: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<void> deleteDraft(String id) =>
      (delete(draftEntries)..where((row) => row.id.equals(id))).go();

  Future<Map<String, Object?>> exportSnapshot() async => {
    'schemaVersion': schemaVersion,
    'diaries': [for (final row in await select(diaries).get()) row.toJson()],
    'media': [for (final row in await select(mediaEntries).get()) row.toJson()],
    'weather': [
      for (final row in await select(weatherEntries).get()) row.toJson(),
    ],
    'settings': [
      for (final row in await select(settingEntries).get()) row.toJson(),
    ],
  };

  Future<void> restoreSnapshot(
    Map<String, dynamic> snapshot, {
    required bool replaceExisting,
  }) async {
    final version = snapshot['schemaVersion'] as int?;
    if (version != schemaVersion) {
      throw FormatException('지원하지 않는 백업 스키마입니다: $version');
    }

    List<Map<String, dynamic>> rows(String key) =>
        (snapshot[key] as List<dynamic>? ?? const [])
            .map((row) => (row as Map<String, dynamic>))
            .toList(growable: false);

    await transaction(() async {
      if (replaceExisting) {
        await delete(mediaEntries).go();
        await delete(weatherEntries).go();
        await delete(diaries).go();
        await delete(settingEntries).go();
      }
      for (final json in rows('diaries')) {
        await into(diaries).insertOnConflictUpdate(DiaryRow.fromJson(json));
      }
      for (final json in rows('media')) {
        await into(
          mediaEntries,
        ).insertOnConflictUpdate(MediaRow.fromJson(json));
      }
      for (final json in rows('weather')) {
        await into(
          weatherEntries,
        ).insertOnConflictUpdate(WeatherRow.fromJson(json));
      }
      if (replaceExisting) {
        for (final json in rows('settings')) {
          await into(
            settingEntries,
          ).insertOnConflictUpdate(SettingRow.fromJson(json));
        }
      }
    });
  }

  Future<void> putSetting(String key, Object? value) =>
      into(settingEntries).insertOnConflictUpdate(
        SettingEntriesCompanion.insert(key: key, valueJson: jsonEncode(value)),
      );

  Future<T?> readSetting<T>(String key) async {
    final row = await (select(
      settingEntries,
    )..where((row) => row.key.equals(key))).getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.valueJson) as T?;
  }
}

Future<AppDatabase> openEncryptedDatabase(SecureKeyPort keyPort) async {
  final support = await getApplicationSupportDirectory();
  final databaseDirectory = Directory(p.join(support.path, 'secure'));
  await databaseDirectory.create(recursive: true);
  final file = File(p.join(databaseDirectory.path, 'drawry.db'));
  final key = await keyPort.getOrCreateDatabaseKey();
  final hex = _hex(key);

  return AppDatabase(
    NativeDatabase.createInBackground(
      file,
      setup: (database) {
        database.execute('PRAGMA key = "x\'$hex\'";');
        final cipher = database.select('PRAGMA cipher_version;');
        if (cipher.isEmpty) {
          throw StateError('Encrypted SQLite backend is unavailable.');
        }
        database.execute('PRAGMA cipher_memory_security = ON;');
        database.execute('PRAGMA foreign_keys = ON;');
        database.execute('PRAGMA secure_delete = ON;');
        database.execute('PRAGMA journal_mode = WAL;');
      },
    ),
  );
}

String _hex(Uint8List bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
