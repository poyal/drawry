import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../share/share_screen.dart';
import '../domain/diary.dart';
import 'diary_editor_screen.dart';
import 'media_viewer.dart';

class DiaryDetailScreen extends ConsumerWidget {
  const DiaryDetailScreen({required this.diaryId, super.key});

  final String diaryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diaryAsync = ref.watch(diaryProvider(diaryId));
    return diaryAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('일기를 열지 못했습니다.\n$error')),
      ),
      data: (diary) => diary == null
          ? Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('삭제되었거나 존재하지 않는 일기입니다.')),
            )
          : _DiaryDetail(diary: diary),
    );
  }
}

class _DiaryDetail extends ConsumerWidget {
  const _DiaryDetail({required this.diary});

  final Diary diary;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiaryEditorScreen(initial: diary),
      ),
    );
    ref.invalidate(diaryProvider(diary.id));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('휴지통으로 이동할까요?'),
        content: const Text('30일 동안 복원할 수 있으며 이후 자동으로 완전히 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('이동'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await (await ref.read(
      diaryRepositoryProvider.future,
    )).moveToTrash(diary.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('일기'),
      actions: [
        IconButton(
          tooltip: '공유 이미지 만들기',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ShareScreen(diary: diary)),
          ),
          icon: const Icon(Icons.ios_share_rounded),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _edit(context, ref);
            if (value == 'delete') _delete(context, ref);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('수정')),
            PopupMenuItem(value: 'delete', child: Text('휴지통으로 이동')),
          ],
        ),
      ],
    ),
    body: ListView(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: diary.media.length,
            itemBuilder: (_, index) => ColoredBox(
              color: Colors.black,
              child: DiaryMediaView(
                media: diary.media[index],
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${DateFormat('yyyy년 M월 d일').format(diary.entryDate)}  '
                '${diary.entryTime.inHours.toString().padLeft(2, '0')}:'
                '${(diary.entryTime.inMinutes % 60).toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (diary.mood != null) ...[
                const SizedBox(height: 12),
                Text(diary.mood!, style: const TextStyle(fontSize: 36)),
              ],
              if (diary.headline != null) ...[
                const SizedBox(height: 12),
                Text(
                  diary.headline!,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
              if (diary.body != null) ...[
                const SizedBox(height: 16),
                Text(diary.body!, style: Theme.of(context).textTheme.bodyLarge),
              ],
              if (diary.tags.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: diary.tags
                      .map((tag) => Chip(label: Text('#$tag')))
                      .toList(),
                ),
              ],
              if (diary.companions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.group_outlined),
                    const SizedBox(width: 8),
                    Expanded(child: Text(diary.companions.join(', '))),
                  ],
                ),
              ],
              if (diary.weather != null) ...[
                const SizedBox(height: 16),
                _WeatherSummary(weather: diary.weather!),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _WeatherSummary extends StatelessWidget {
  const _WeatherSummary({required this.weather});

  final WeatherEntry weather;

  @override
  Widget build(BuildContext context) {
    final values = <String>[
      if (weather.shows(WeatherEntry.conditionMask) &&
          weather.condition != null)
        _conditionLabel(weather.condition!),
      if (weather.shows(WeatherEntry.temperatureMask) &&
          weather.temperature != null)
        '${weather.temperature}°C',
      if (weather.shows(WeatherEntry.rangeMask) &&
          weather.minimumTemperature != null)
        '최저 ${weather.minimumTemperature}°C',
      if (weather.shows(WeatherEntry.rangeMask) &&
          weather.maximumTemperature != null)
        '최고 ${weather.maximumTemperature}°C',
      if (weather.shows(WeatherEntry.precipitationMask) &&
          weather.precipitation != null)
        weather.precipitation! ? '강수 있음' : '강수 없음',
    ];
    if (values.isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cloud_outlined),
        const SizedBox(width: 8),
        Expanded(child: Text(values.join(' · '))),
      ],
    );
  }
}

String _conditionLabel(WeatherCondition condition) => switch (condition) {
  WeatherCondition.sunny => '맑음',
  WeatherCondition.cloudy => '흐림',
  WeatherCondition.rain => '비',
  WeatherCondition.snow => '눈',
  WeatherCondition.fog => '안개',
  WeatherCondition.windy => '바람',
  WeatherCondition.other => '기타',
};
