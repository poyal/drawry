import 'package:drawry/features/diary/domain/diary.dart';
import 'package:drawry/features/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('사용자 옵션은 JSON 왕복 후 유지된다', () {
    const settings = AppSettingsState(
      onboardingComplete: true,
      lockEnabled: true,
      lockTimeout: LockTimeout.minutes15,
      feedLayout: FeedLayout.grid3,
      themeMode: AppThemeMode.dark,
      preserveOriginal: true,
      weatherDisplayMask:
          WeatherEntry.conditionMask | WeatherEntry.precipitationMask,
      shareBody: true,
      shareWeather: true,
      shareRatio: '9:16',
      shareTheme: 'dark',
    );

    final restored = AppSettingsState.fromJson(settings.toJson());

    expect(restored.onboardingComplete, isTrue);
    expect(restored.lockEnabled, isTrue);
    expect(restored.lockTimeout, LockTimeout.minutes15);
    expect(restored.feedLayout, FeedLayout.grid3);
    expect(restored.themeMode, AppThemeMode.dark);
    expect(restored.preserveOriginal, isTrue);
    expect(
      restored.weatherDisplayMask,
      WeatherEntry.conditionMask | WeatherEntry.precipitationMask,
    );
    expect(restored.shareBody, isTrue);
    expect(restored.shareWeather, isTrue);
    expect(restored.shareRatio, '9:16');
    expect(restored.shareTheme, 'dark');
  });
}
