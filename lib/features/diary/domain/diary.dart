import 'dart:typed_data';

enum DiaryMediaKind { image, video }

enum FeedLayout { card, grid2, grid3 }

enum AppThemeMode { system, light, dark }

enum WeatherCondition { sunny, cloudy, rain, snow, fog, windy, other }

final class Diary {
  const Diary({
    required this.id,
    required this.entryDate,
    required this.entryTime,
    required this.utcOffsetMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.headline,
    this.body,
    this.mood,
    this.tags = const [],
    this.companions = const [],
    this.media = const [],
    this.weather,
    this.deletedAt,
    this.purgeAt,
  });

  final String id;
  final DateTime entryDate;
  final Duration entryTime;
  final int utcOffsetMinutes;
  final String? headline;
  final String? body;
  final String? mood;
  final List<String> tags;
  final List<String> companions;
  final List<DiaryMedia> media;
  final WeatherEntry? weather;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? purgeAt;

  bool get isDeleted => deletedAt != null;
}

final class DiaryMedia {
  const DiaryMedia({
    required this.id,
    required this.kind,
    required this.mimeType,
    required this.encryptedPath,
    required this.key,
    required this.byteLength,
    this.thumbnailPath,
    this.renderedPath,
    this.width,
    this.height,
    this.duration,
    this.representativeFrame,
    this.editHistoryJson,
  });

  final String id;
  final DiaryMediaKind kind;
  final String mimeType;
  final String encryptedPath;
  final String? thumbnailPath;
  final String? renderedPath;
  final Uint8List key;
  final int byteLength;
  final int? width;
  final int? height;
  final Duration? duration;
  final Duration? representativeFrame;
  final String? editHistoryJson;

  DiaryMedia copyWith({
    String? thumbnailPath,
    String? renderedPath,
    Duration? representativeFrame,
    String? editHistoryJson,
  }) => DiaryMedia(
    id: id,
    kind: kind,
    mimeType: mimeType,
    encryptedPath: encryptedPath,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    renderedPath: renderedPath ?? this.renderedPath,
    key: key,
    byteLength: byteLength,
    width: width,
    height: height,
    duration: duration,
    representativeFrame: representativeFrame ?? this.representativeFrame,
    editHistoryJson: editHistoryJson ?? this.editHistoryJson,
  );
}

final class WeatherEntry {
  static const conditionMask = 1;
  static const temperatureMask = 2;
  static const rangeMask = 4;
  static const precipitationMask = 8;
  static const allMask = 15;

  const WeatherEntry({
    this.condition,
    this.temperature,
    this.minimumTemperature,
    this.maximumTemperature,
    this.precipitation,
    this.displayMask = 1,
  });

  final WeatherCondition? condition;
  final double? temperature;
  final double? minimumTemperature;
  final double? maximumTemperature;
  final bool? precipitation;
  final int displayMask;

  bool shows(int mask) => displayMask & mask != 0;

  bool get isEmpty =>
      condition == null &&
      temperature == null &&
      minimumTemperature == null &&
      maximumTemperature == null &&
      precipitation == null;
}

final class DiaryDraft {
  const DiaryDraft({
    required this.entryDateTime,
    this.id,
    this.headline,
    this.body,
    this.mood,
    this.tags = const [],
    this.companions = const [],
    this.media = const [],
    this.weather,
  });

  final String? id;
  final DateTime entryDateTime;
  final String? headline;
  final String? body;
  final String? mood;
  final List<String> tags;
  final List<String> companions;
  final List<DiaryMedia> media;
  final WeatherEntry? weather;
}
