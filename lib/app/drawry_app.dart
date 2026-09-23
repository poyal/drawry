import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/home/home_shell.dart';
import '../features/lock/lock_controller.dart';
import '../features/lock/lock_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/app_settings.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_theme.dart';

class DrawryApp extends ConsumerStatefulWidget {
  const DrawryApp({super.key});

  @override
  ConsumerState<DrawryApp> createState() => _DrawryAppState();
}

class _DrawryAppState extends ConsumerState<DrawryApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(
      settingsProvider,
      (_, next) => next.whenData(ref.read(lockProvider.notifier).configure),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsProvider).value;
    if (settings != null) {
      ref.read(lockProvider.notifier).onLifecycle(state, settings);
    }
    if (state != AppLifecycleState.resumed) {
      unawaited(ref.read(mediaStorageProvider).clearMaterializedCache());
    } else {
      ref.invalidate(maintenanceProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(maintenanceProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value ?? const AppSettingsState();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drawry',
      locale: const Locale('ko'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: DrawryTheme.light(),
      darkTheme: DrawryTheme.dark(),
      themeMode: settings.materialThemeMode,
      home: settingsAsync.when(
        loading: () => const _StartupScreen(),
        error: (error, _) => _StartupError(error: error),
        data: (value) => value.onboardingComplete
            ? const _PrivacyGate(child: HomeShell())
            : const OnboardingScreen(),
      ),
    );
  }
}

class _PrivacyGate extends ConsumerWidget {
  const _PrivacyGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(lockProvider);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (lock.privacyCovered)
          const LockScreen(privacyOnly: true)
        else if (lock.locked)
          const LockScreen(),
      ],
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52),
              const SizedBox(height: 16),
              const Text('안전한 저장소를 열지 못했습니다.'),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  );
}
