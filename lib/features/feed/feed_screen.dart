import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../diary/domain/diary.dart';
import '../diary/presentation/diary_detail_screen.dart';
import '../diary/presentation/media_viewer.dart';
import '../settings/app_settings.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaries = ref.watch(activeDiariesProvider);
    final layout =
        ref.watch(settingsProvider).value?.feedLayout ?? FeedLayout.card;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Drawry',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                PopupMenuButton<FeedLayout>(
                  tooltip: '피드 보기 방식',
                  initialValue: layout,
                  onSelected: (value) => ref
                      .read(settingsProvider.notifier)
                      .save((settings) => settings.copyWith(feedLayout: value)),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: FeedLayout.card, child: Text('세로 카드')),
                    PopupMenuItem(
                      value: FeedLayout.grid2,
                      child: Text('2열 격자'),
                    ),
                    PopupMenuItem(
                      value: FeedLayout.grid3,
                      child: Text('3열 격자'),
                    ),
                  ],
                  icon: Icon(switch (layout) {
                    FeedLayout.card => Icons.view_agenda_outlined,
                    FeedLayout.grid2 => Icons.grid_view_rounded,
                    FeedLayout.grid3 => Icons.apps_rounded,
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: diaries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(error: error),
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : layout == FeedLayout.card
                  ? ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (_, index) => _DiaryCard(items[index]),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 104),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: layout == FeedLayout.grid2 ? 2 : 3,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, index) => _DiaryTile(items[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard(this.diary);

  final Diary diary;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: () => _open(context, diary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: diary.media.length == 1
                ? DiaryMediaView(media: diary.media.first, thumbnail: true)
                : PageView.builder(
                    itemCount: diary.media.length,
                    itemBuilder: (_, index) => DiaryMediaView(
                      media: diary.media[index],
                      thumbnail: true,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateFormat('yyyy년 M월 d일').format(diary.entryDate)}'
                  '${diary.mood == null ? '' : '  ${diary.mood}'}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (diary.headline != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    diary.headline!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                if (diary.body != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    diary.body!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DiaryTile extends StatelessWidget {
  const _DiaryTile(this.diary);

  final Diary diary;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _open(context, diary),
    child: Hero(
      tag: 'diary-${diary.id}',
      child: DiaryMediaView(media: diary.media.first, thumbnail: true),
    ),
  );
}

void _open(BuildContext context, Diary diary) => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => DiaryDetailScreen(diaryId: diary.id)),
);

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined, size: 64),
          SizedBox(height: 16),
          Text('아직 기록이 없어요'),
          SizedBox(height: 8),
          Text('아래 일기 쓰기 버튼으로 첫 순간을 남겨보세요.'),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('일기를 불러오지 못했습니다.\n$error', textAlign: TextAlign.center),
    ),
  );
}
