import 'dart:typed_data';

import 'package:drawry/features/diary/data/diary_draft_codec.dart';
import 'package:drawry/features/diary/domain/diary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypted database draft payload preserves editor state', () {
    final snapshot = DiaryDraftSnapshot(
      draft: DiaryDraft(
        id: 'diary-1',
        entryDateTime: DateTime(2026, 8, 30, 12, 34),
        headline: '오늘',
        body: '기록',
        mood: '😊',
        tags: const ['여행'],
        companions: const ['친구'],
        media: [
          DiaryMedia(
            id: 'media-1',
            kind: DiaryMediaKind.video,
            mimeType: 'video/mp4',
            encryptedPath: 'secure/media-1.bin',
            thumbnailPath: 'secure/media-1-thumb.bin',
            key: Uint8List.fromList(List<int>.generate(32, (index) => index)),
            byteLength: 1234,
            duration: const Duration(seconds: 12),
            representativeFrame: const Duration(seconds: 3),
          ),
        ],
        weather: const WeatherEntry(
          condition: WeatherCondition.sunny,
          temperature: 24,
          precipitation: false,
          displayMask: 15,
        ),
      ),
      newMediaIds: const {'media-1'},
    );

    final decoded = decodeDiaryDraft(encodeDiaryDraft(snapshot));

    expect(decoded.draft.id, 'diary-1');
    expect(decoded.draft.entryDateTime.hour, 12);
    expect(decoded.draft.headline, '오늘');
    expect(decoded.draft.media.single.kind, DiaryMediaKind.video);
    expect(decoded.draft.media.single.key, snapshot.draft.media.single.key);
    expect(
      decoded.draft.media.single.representativeFrame,
      const Duration(seconds: 3),
    );
    expect(decoded.draft.weather?.condition, WeatherCondition.sunny);
    expect(decoded.newMediaIds, {'media-1'});
  });
}
