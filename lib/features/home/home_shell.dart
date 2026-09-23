import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../calendar/calendar_screen.dart';
import '../diary/presentation/diary_editor_screen.dart';
import '../feed/feed_screen.dart';
import '../settings/app_settings.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    final path = ref.read(settingsProvider).value?.lastHomePath;
    _index = path == '/calendar'
        ? 1
        : path == '/settings'
        ? 2
        : 0;
  }

  Future<void> _select(int index) async {
    setState(() => _index = index);
    final path = switch (index) {
      1 => '/calendar',
      2 => '/settings',
      _ => '/feed',
    };
    await ref
        .read(settingsProvider.notifier)
        .save((value) => value.copyWith(lastHomePath: path));
  }

  Future<void> _createDiary() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const DiaryEditorScreen()));
  }

  @override
  Widget build(BuildContext context) {
    const pages = [FeedScreen(), CalendarScreen(), SettingsScreen()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _createDiary,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('일기 쓰기'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed_rounded),
            label: '피드',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
