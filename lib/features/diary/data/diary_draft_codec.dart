import 'dart:convert';
import 'dart:typed_data';

import '../domain/diary.dart';

final class DiaryDraftSnapshot {
  const DiaryDraftSnapshot({required this.draft, required this.newMediaIds});

  final DiaryDraft draft;
  final Set<String> newMediaIds;
}

String encodeDiaryDraft(DiaryDraftSnapshot snapshot) => jsonEncode({
  'version': 1,
  'draft': {
    'id': snapshot.draft.id,
    'entryDateTime': _encodeWallClock(snapshot.draft.entryDateTime),
    'headline': snapshot.draft.headline,
    'body': snapshot.draft.body,
    'mood': snapshot.draft.mood,
    'tags': snapshot.draft.tags,
    'companions': snapshot.draft.companions,
    'media': snapshot.draft.media.map(_encodeMedia).toList(growable: false),
    'weather': _encodeWeather(snapshot.draft.weather),
  },
  'newMediaIds': snapshot.newMediaIds.toList(growable: false),
});

DiaryDraftSnapshot decodeDiaryDraft(String source) {
  final root = jsonDecode(source) as Map<String, dynamic>;
  if (root['version'] != 1) {
    throw const FormatException('지원하지 않는 임시저장 형식입니다.');
  }
  final json = root['draft'] as Map<String, dynamic>;
  final mediaJson = json['media'] as List<dynamic>? ?? const [];
  final weatherJson = json['weather'] as Map<String, dynamic>?;
  return DiaryDraftSnapshot(
    draft: DiaryDraft(
      id: json['id'] as String?,
      entryDateTime: _decodeWallClock(
        json['entryDateTime'] as Map<String, dynamic>,
      ),
      headline: json['headline'] as String?,
      body: json['body'] as String?,
      mood: json['mood'] as String?,
      tags: _strings(json['tags']),
      companions: _strings(json['companions']),
      media: mediaJson
          .map((item) => _decodeMedia(item as Map<String, dynamic>))
          .toList(growable: false),
      weather: weatherJson == null ? null : _decodeWeather(weatherJson),
    ),
    newMediaIds: _strings(root['newMediaIds']).toSet(),
  );
}

Map<String, Object?> _encodeMedia(DiaryMedia media) => {
  'id': media.id,
  'kind': media.kind.name,
  'mimeType': media.mimeType,
  'encryptedPath': media.encryptedPath,
  'thumbnailPath': media.thumbnailPath,
  'renderedPath': media.renderedPath,
  'key': base64UrlEncode(media.key),
  'byteLength': media.byteLength,
  'width': media.width,
  'height': media.height,
  'durationMillis': media.duration?.inMilliseconds,
  'representativeMillis': media.representativeFrame?.inMilliseconds,
  'editHistoryJson': media.editHistoryJson,
};

DiaryMedia _decodeMedia(Map<String, dynamic> json) => DiaryMedia(
  id: json['id'] as String,
  kind: DiaryMediaKind.values.byName(json['kind'] as String),
  mimeType: json['mimeType'] as String,
  encryptedPath: json['encryptedPath'] as String,
  thumbnailPath: json['thumbnailPath'] as String?,
  renderedPath: json['renderedPath'] as String?,
  key: Uint8List.fromList(base64Url.decode(json['key'] as String)),
  byteLength: json['byteLength'] as int,
  width: json['width'] as int?,
  height: json['height'] as int?,
  duration: _duration(json['durationMillis']),
  representativeFrame: _duration(json['representativeMillis']),
  editHistoryJson: json['editHistoryJson'] as String?,
);

Map<String, Object?>? _encodeWeather(WeatherEntry? weather) => weather == null
    ? null
    : {
        'condition': weather.condition?.name,
        'temperature': weather.temperature,
        'minimumTemperature': weather.minimumTemperature,
        'maximumTemperature': weather.maximumTemperature,
        'precipitation': weather.precipitation,
        'displayMask': weather.displayMask,
      };

WeatherEntry _decodeWeather(Map<String, dynamic> json) => WeatherEntry(
  condition: json['condition'] == null
      ? null
      : WeatherCondition.values.byName(json['condition'] as String),
  temperature: (json['temperature'] as num?)?.toDouble(),
  minimumTemperature: (json['minimumTemperature'] as num?)?.toDouble(),
  maximumTemperature: (json['maximumTemperature'] as num?)?.toDouble(),
  precipitation: json['precipitation'] as bool?,
  displayMask: json['displayMask'] as int? ?? 1,
);

Duration? _duration(Object? milliseconds) =>
    milliseconds == null ? null : Duration(milliseconds: milliseconds as int);

List<String> _strings(Object? value) =>
    (value as List<dynamic>? ?? const []).cast<String>();

Map<String, int> _encodeWallClock(DateTime value) => {
  'year': value.year,
  'month': value.month,
  'day': value.day,
  'hour': value.hour,
  'minute': value.minute,
  'second': value.second,
  'millisecond': value.millisecond,
};

DateTime _decodeWallClock(Map<String, dynamic> json) => DateTime(
  json['year'] as int,
  json['month'] as int,
  json['day'] as int,
  json['hour'] as int,
  json['minute'] as int,
  json['second'] as int,
  json['millisecond'] as int,
);
