import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../settings/app_settings.dart';

final class LockState {
  const LockState({
    this.locked = false,
    this.privacyCovered = false,
    this.unlocking = false,
    this.message,
  });

  final bool locked;
  final bool privacyCovered;
  final bool unlocking;
  final String? message;

  LockState copyWith({
    bool? locked,
    bool? privacyCovered,
    bool? unlocking,
    String? message,
    bool clearMessage = false,
  }) => LockState(
    locked: locked ?? this.locked,
    privacyCovered: privacyCovered ?? this.privacyCovered,
    unlocking: unlocking ?? this.unlocking,
    message: clearMessage ? null : message ?? this.message,
  );
}

final class LockController extends Notifier<LockState> {
  final LocalAuthentication _authentication = LocalAuthentication();
  DateTime? _backgroundedAt;
  bool? _lockEnabled;

  @override
  LockState build() => const LockState();

  void configure(AppSettingsState settings) {
    final changed = _lockEnabled != settings.lockEnabled;
    _lockEnabled = settings.lockEnabled;
    if (!settings.lockEnabled && state.locked) {
      state = state.copyWith(locked: false, clearMessage: true);
    } else if (settings.lockEnabled && changed) {
      state = state.copyWith(locked: true, clearMessage: true);
    }
  }

  void onLifecycle(AppLifecycleState lifecycle, AppSettingsState settings) {
    switch (lifecycle) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _backgroundedAt ??= DateTime.now();
        state = state.copyWith(
          privacyCovered: true,
          locked:
              state.locked ||
              (settings.lockEnabled &&
                  settings.lockTimeout == LockTimeout.immediately),
        );
      case AppLifecycleState.resumed:
        final elapsed = _backgroundedAt == null
            ? Duration.zero
            : DateTime.now().difference(_backgroundedAt!);
        final shouldLock =
            settings.lockEnabled && elapsed >= settings.lockTimeout.duration;
        _backgroundedAt = null;
        state = state.copyWith(
          privacyCovered: false,
          locked: state.locked || shouldLock,
        );
    }
  }

  Future<bool> canEnable() => _authentication.isDeviceSupported();

  Future<bool> unlock() async {
    if (state.unlocking) return false;
    state = state.copyWith(unlocking: true, clearMessage: true);
    try {
      final success = await _authentication.authenticate(
        localizedReason: 'Drawry의 개인 일기 잠금을 해제합니다.',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      state = state.copyWith(
        unlocking: false,
        locked: !success,
        message: success ? null : '인증을 취소했습니다.',
        clearMessage: success,
      );
      return success;
    } catch (_) {
      state = state.copyWith(unlocking: false, message: '기기 인증을 사용할 수 없습니다.');
      return false;
    }
  }

  void lockNow() => state = state.copyWith(locked: true, privacyCovered: false);
}

final lockProvider = NotifierProvider<LockController, LockState>(
  LockController.new,
);
