import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _pages = [
    (
      icon: Icons.auto_stories_rounded,
      title: '나만 보는 그림일기',
      body: '사진과 짧은 영상을 남기고 피드와 달력에서 다시 꺼내보세요.',
    ),
    (
      icon: Icons.enhanced_encryption_rounded,
      title: '기기 안에서 안전하게',
      body: '일기 데이터와 미디어를 암호화해 저장하며 공개형 SNS 기능은 없습니다.',
    ),
    (
      icon: Icons.lock_person_rounded,
      title: '앱 잠금은 선택 사항',
      body: '설정에서 생체 인증 또는 기기 암호 잠금을 켜고 유예 시간을 고를 수 있습니다.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    await ref
        .read(settingsProvider.notifier)
        .save((value) => value.copyWith(onboardingComplete: true));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(page.icon, size: 96),
                      const SizedBox(height: 32),
                      Text(
                        page.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.body,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => Container(
                width: index == _page ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: index == _page
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _next,
                child: Text(_page == _pages.length - 1 ? '시작하기' : '다음'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
