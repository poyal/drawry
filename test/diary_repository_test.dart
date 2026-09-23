import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:drawry/core/database/app_database.dart';
import 'package:drawry/core/media/media_storage.dart';
import 'package:drawry/features/diary/data/diary_repository.dart';
import 'package:drawry/features/diary/domain/diary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DriftDiaryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftDiaryRepository(database, MediaStorage());
  });

  tearDown(() => database.close());

  test('일기를 저장하고 휴지통 이동·복원하면 30일 정책이 유지된다', () async {
    final id = await repository.save(
      DiaryDraft(
        entryDateTime: DateTime(2026, 8, 30, 21, 10),
        headline: '테스트 일기',
        tags: const ['테스트', '보안'],
        media: [
          DiaryMedia(
            id: 'media-1',
            kind: DiaryMediaKind.image,
            mimeType: 'image/jpeg',
            encryptedPath: 'media-1.media',
            thumbnailPath: 'media-1.thumb',
            key: Uint8List(32),
            byteLength: 1200,
            width: 100,
            height: 100,
          ),
        ],
      ),
    );

    final saved = await repository.getById(id);
    expect(saved?.headline, '테스트 일기');
    expect(saved?.tags, ['테스트', '보안']);
    expect(saved?.media, hasLength(1));

    final beforeTrash = DateTime.now().toUtc();
    await repository.moveToTrash(id);
    final trashed = await repository.getById(id);
    expect(trashed?.isDeleted, isTrue);
    expect(trashed!.purgeAt!.difference(beforeTrash).inDays, anyOf(29, 30));

    await repository.restore(id);
    final restored = await repository.getById(id);
    expect(restored?.isDeleted, isFalse);
    expect(restored?.purgeAt, isNull);
  });

  test('데이터베이스 스냅샷을 교체 복원한다', () async {
    final id = await repository.save(
      DiaryDraft(
        entryDateTime: DateTime(2025, 1, 2),
        media: [
          DiaryMedia(
            id: 'media-2',
            kind: DiaryMediaKind.image,
            mimeType: 'image/png',
            encryptedPath: 'media-2.media',
            key: Uint8List(32),
            byteLength: 10,
          ),
        ],
      ),
    );
    final snapshot = await database.exportSnapshot();
    await repository.moveToTrash(id);

    await database.restoreSnapshot(snapshot, replaceExisting: true);

    final restored = await repository.getById(id);
    expect(restored, isNotNull);
    expect(restored?.isDeleted, isFalse);
    expect(restored?.media.single.encryptedPath, 'media-2.media');
  });
}
