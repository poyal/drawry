import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/data_management_screen.dart';
import '../diary/domain/diary.dart';
import '../lock/lock_controller.dart';
import '../trash/trash_screen.dart';
import 'app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return SafeArea(
      child: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (settings) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                '설정',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            _Section(
              title: '개인정보 보호',
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline_rounded),
                  title: const Text('앱 잠금'),
                  subtitle: const Text('생체 인증 또는 기기 암호 사용'),
                  value: settings.lockEnabled,
                  onChanged: (enabled) async {
                    if (enabled &&
                        !await ref.read(lockProvider.notifier).canEnable()) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이 기기에서는 인증을 사용할 수 없습니다.'),
                          ),
                        );
                      }
                      return;
                    }
                    await ref
                        .read(settingsProvider.notifier)
                        .save((value) => value.copyWith(lockEnabled: enabled));
                  },
                ),
                ListTile(
                  enabled: settings.lockEnabled,
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('다시 잠그는 시간'),
                  subtitle: Text(settings.lockTimeout.label),
                  onTap: () => _chooseLockTimeout(context, ref, settings),
                ),
                if (settings.lockEnabled)
                  ListTile(
                    leading: const Icon(Icons.lock_clock_outlined),
                    title: const Text('지금 잠그기'),
                    onTap: () => ref.read(lockProvider.notifier).lockNow(),
                  ),
              ],
            ),
            _Section(
              title: '보기 및 저장',
              children: [
                ListTile(
                  leading: const Icon(Icons.grid_view_outlined),
                  title: const Text('피드 보기 방식'),
                  subtitle: Text(_layoutLabel(settings.feedLayout)),
                  onTap: () => _chooseLayout(context, ref, settings),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('화면 테마'),
                  subtitle: Text(_themeLabel(settings.themeMode)),
                  onTap: () => _chooseTheme(context, ref, settings),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('날씨 표시 기본값'),
                  subtitle: Text(
                    _weatherMaskLabel(settings.weatherDisplayMask),
                  ),
                  onTap: () => _chooseWeatherDisplay(context, ref, settings),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.high_quality_outlined),
                  title: const Text('원본 해상도 보존'),
                  subtitle: const Text('끄면 긴 변 2560px로 최적화해 저장 공간을 절약합니다.'),
                  value: settings.preserveOriginal,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .save((state) => state.copyWith(preserveOriginal: value)),
                ),
              ],
            ),
            _Section(
              title: '데이터',
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('휴지통'),
                  subtitle: const Text('삭제한 일기는 30일 뒤 완전히 삭제됩니다.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TrashScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore_rounded),
                  title: const Text('백업 및 복원'),
                  subtitle: const Text('암호화 파일로 내보내고 복원'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DataManagementScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Drawry 1.0.0\n일기와 미디어는 서버에 올리지 않고 기기 안에 암호화해 저장합니다.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseLockTimeout(
    BuildContext context,
    WidgetRef ref,
    AppSettingsState settings,
  ) async {
    final selected = await showModalBottomSheet<LockTimeout>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<LockTimeout>(
          groupValue: settings.lockTimeout,
          onChanged: (selected) => Navigator.pop(context, selected),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: LockTimeout.values
                .map(
                  (value) => RadioListTile<LockTimeout>(
                    value: value,
                    title: Text(value.label),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      await ref
          .read(settingsProvider.notifier)
          .save((value) => value.copyWith(lockTimeout: selected));
    }
  }

  Future<void> _chooseLayout(
    BuildContext context,
    WidgetRef ref,
    AppSettingsState settings,
  ) async {
    final selected = await showModalBottomSheet<FeedLayout>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<FeedLayout>(
          groupValue: settings.feedLayout,
          onChanged: (selected) => Navigator.pop(context, selected),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: FeedLayout.values
                .map(
                  (value) => RadioListTile<FeedLayout>(
                    value: value,
                    title: Text(_layoutLabel(value)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      await ref
          .read(settingsProvider.notifier)
          .save((value) => value.copyWith(feedLayout: selected));
    }
  }

  Future<void> _chooseTheme(
    BuildContext context,
    WidgetRef ref,
    AppSettingsState settings,
  ) async {
    final selected = await showModalBottomSheet<AppThemeMode>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<AppThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (selected) => Navigator.pop(context, selected),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values
                .map(
                  (value) => RadioListTile<AppThemeMode>(
                    value: value,
                    title: Text(_themeLabel(value)),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      await ref
          .read(settingsProvider.notifier)
          .save((value) => value.copyWith(themeMode: selected));
    }
  }

  Future<void> _chooseWeatherDisplay(
    BuildContext context,
    WidgetRef ref,
    AppSettingsState settings,
  ) async {
    var mask = settings.weatherDisplayMask;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget chip(String label, int value) => FilterChip(
            label: Text(label),
            selected: mask & value != 0,
            onSelected: (enabled) => setDialogState(
              () => mask = enabled ? mask | value : mask & ~value,
            ),
          );
          return AlertDialog(
            title: const Text('날씨 표시 기본값'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip('상태', WeatherEntry.conditionMask),
                chip('기온', WeatherEntry.temperatureMask),
                chip('최저·최고', WeatherEntry.rangeMask),
                chip('강수', WeatherEntry.precipitationMask),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, mask),
                child: const Text('저장'),
              ),
            ],
          );
        },
      ),
    );
    if (selected != null) {
      await ref
          .read(settingsProvider.notifier)
          .save((value) => value.copyWith(weatherDisplayMask: selected));
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(title, style: Theme.of(context).textTheme.labelLarge),
            ),
            ...children,
          ],
        ),
      ),
    ),
  );
}

String _layoutLabel(FeedLayout layout) => switch (layout) {
  FeedLayout.card => '세로 카드',
  FeedLayout.grid2 => '2열 격자',
  FeedLayout.grid3 => '3열 격자',
};

String _themeLabel(AppThemeMode mode) => switch (mode) {
  AppThemeMode.system => '시스템 설정',
  AppThemeMode.light => '라이트',
  AppThemeMode.dark => '다크',
};

String _weatherMaskLabel(int mask) {
  final values = <String>[
    if (mask & WeatherEntry.conditionMask != 0) '상태',
    if (mask & WeatherEntry.temperatureMask != 0) '기온',
    if (mask & WeatherEntry.rangeMask != 0) '최저·최고',
    if (mask & WeatherEntry.precipitationMask != 0) '강수',
  ];
  return values.isEmpty ? '모두 숨김' : values.join(' · ');
}
