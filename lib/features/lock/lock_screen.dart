import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lock_controller.dart';

class LockScreen extends ConsumerWidget {
  const LockScreen({super.key, this.privacyOnly = false});

  final bool privacyOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lockProvider);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: privacyOnly
              ? const Icon(Icons.auto_stories_rounded, size: 56)
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, size: 64),
                        const SizedBox(height: 20),
                        Text(
                          'Drawry가 잠겨 있어요',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '생체 인증 또는 기기 암호로 개인 일기를 확인하세요.',
                          textAlign: TextAlign.center,
                        ),
                        if (state.message != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.message!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: state.unlocking
                              ? null
                              : () => ref.read(lockProvider.notifier).unlock(),
                          icon: state.unlocking
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.fingerprint),
                          label: const Text('잠금 해제'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
