import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../diary/domain/diary.dart';

enum LockTimeout {
  immediately(Duration.zero, '즉시'),
  seconds30(Duration(seconds: 30), '30초'),
  minute1(Duration(minutes: 1), '1분'),
  minutes5(Duration(minutes: 5), '5분'),
  minutes15(Duration(minutes: 15), '15분'),
  minutes30(Duration(minutes: 30), '30분');

  const LockTimeout(this.duration, this.label);
  final Duration duration;
  final String label;
}

final class AppSettingsState {
  const AppSettingsState({
    this.onboardingComplete = false,
    this.lockEnabled = false,
    this.lockTimeout = LockTimeout.minute1,
    this.feedLayout = FeedLayout.card,
    this.themeMode = AppThemeMode.system,
    this.preserveOriginal = false,
    this.weatherDisplayMask = WeatherEntry.allMask,
    this.lastHomePath = '/feed',
    this.shareDate = true,
    this.shareHeadline = true,
    this.shareMood = true,
    this.shareBody = false,
    this.shareWeather = false,
    this.shareWatermark = false,
    this.shareRatio = '4:5',
    this.shareTheme = 'basic',
  });

  final bool onboardingComplete;
  final bool lockEnabled;
  final LockTimeout lockTimeout;
  final FeedLayout feedLayout;
  final AppThemeMode themeMode;
  final bool preserveOriginal;
  final int weatherDisplayMask;
  final String lastHomePath;
  final bool shareDate;
  final bool shareHeadline;
  final bool shareMood;
  final bool shareBody;
  final bool shareWeather;
  final bool shareWatermark;
  final String shareRatio;
  final String shareTheme;

  ThemeMode get materialThemeMode => switch (themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  AppSettingsState copyWith({
    bool? onboardingComplete,
    bool? lockEnabled,
    LockTimeout? lockTimeout,
    FeedLayout? feedLayout,
    AppThemeMode? themeMode,
    bool? preserveOriginal,
    int? weatherDisplayMask,
    String? lastHomePath,
    bool? shareDate,
    bool? shareHeadline,
    bool? shareMood,
    bool? shareBody,
    bool? shareWeather,
    bool? shareWatermark,
    String? shareRatio,
    String? shareTheme,
  }) => AppSettingsState(
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    lockEnabled: lockEnabled ?? this.lockEnabled,
    lockTimeout: lockTimeout ?? this.lockTimeout,
    feedLayout: feedLayout ?? this.feedLayout,
    themeMode: themeMode ?? this.themeMode,
    preserveOriginal: preserveOriginal ?? this.preserveOriginal,
    weatherDisplayMask: weatherDisplayMask ?? this.weatherDisplayMask,
    lastHomePath: lastHomePath ?? this.lastHomePath,
    shareDate: shareDate ?? this.shareDate,
    shareHeadline: shareHeadline ?? this.shareHeadline,
    shareMood: shareMood ?? this.shareMood,
    shareBody: shareBody ?? this.shareBody,
    shareWeather: shareWeather ?? this.shareWeather,
    shareWatermark: shareWatermark ?? this.shareWatermark,
    shareRatio: shareRatio ?? this.shareRatio,
    shareTheme: shareTheme ?? this.shareTheme,
  );

  Map<String, Object?> toJson() => {
    'onboardingComplete': onboardingComplete,
    'lockEnabled': lockEnabled,
    'lockTimeout': lockTimeout.name,
    'feedLayout': feedLayout.name,
    'themeMode': themeMode.name,
    'preserveOriginal': preserveOriginal,
    'weatherDisplayMask': weatherDisplayMask,
    'lastHomePath': lastHomePath,
    'shareDate': shareDate,
    'shareHeadline': shareHeadline,
    'shareMood': shareMood,
    'shareBody': shareBody,
    'shareWeather': shareWeather,
    'shareWatermark': shareWatermark,
    'shareRatio': shareRatio,
    'shareTheme': shareTheme,
  };

  factory AppSettingsState.fromJson(Map<String, Object?> json) =>
      AppSettingsState(
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        lockEnabled: json['lockEnabled'] as bool? ?? false,
        lockTimeout: _enumByName(
          LockTimeout.values,
          json['lockTimeout'] as String?,
          LockTimeout.minute1,
        ),
        feedLayout: _enumByName(
          FeedLayout.values,
          json['feedLayout'] as String?,
          FeedLayout.card,
        ),
        themeMode: _enumByName(
          AppThemeMode.values,
          json['themeMode'] as String?,
          AppThemeMode.system,
        ),
        preserveOriginal: json['preserveOriginal'] as bool? ?? false,
        weatherDisplayMask:
            json['weatherDisplayMask'] as int? ?? WeatherEntry.allMask,
        lastHomePath: json['lastHomePath'] as String? ?? '/feed',
        shareDate: json['shareDate'] as bool? ?? true,
        shareHeadline: json['shareHeadline'] as bool? ?? true,
        shareMood: json['shareMood'] as bool? ?? true,
        shareBody: json['shareBody'] as bool? ?? false,
        shareWeather: json['shareWeather'] as bool? ?? false,
        shareWatermark: json['shareWatermark'] as bool? ?? false,
        shareRatio: json['shareRatio'] as String? ?? '4:5',
        shareTheme: json['shareTheme'] as String? ?? 'basic',
      );
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

final class SettingsController extends AsyncNotifier<AppSettingsState> {
  static const _settingsKey = 'app-settings-v1';

  @override
  Future<AppSettingsState> build() async {
    final database = await ref.watch(databaseProvider.future);
    final encoded = await database.readSetting<String>(_settingsKey);
    if (encoded == null) return const AppSettingsState();
    return AppSettingsState.fromJson(
      (jsonDecode(encoded) as Map<String, dynamic>).cast<String, Object?>(),
    );
  }

  Future<void> save(AppSettingsState Function(AppSettingsState) change) async {
    final current = state.value ?? await future;
    final next = change(current);
    state = AsyncData(next);
    final database = await ref.read(databaseProvider.future);
    await database.putSetting(_settingsKey, jsonEncode(next.toJson()));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, AppSettingsState>(
      SettingsController.new,
    );
