import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../diary/domain/diary.dart';
import '../diary/presentation/diary_detail_screen.dart';
import '../diary/presentation/media_viewer.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selected = DateTime.now();
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final diaries = ref.watch(activeDiariesProvider);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              '캘린더',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          _DiaryMonthCalendar(
            month: _visibleMonth,
            selected: _selected,
            diaries: diaries.value ?? const [],
            onMonthChanged: (value) => setState(() => _visibleMonth = value),
            onSelected: (value) => setState(() => _selected = value),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              DateFormat('yyyy년 M월 d일').format(_selected),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: diaries.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (items) {
                final selected = items.where(_sameSelectedDay).toList();
                if (selected.isEmpty) {
                  return const Center(child: Text('이 날짜에는 기록이 없어요.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
                  itemCount: selected.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) =>
                      _CalendarDiaryTile(selected[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _sameSelectedDay(Diary diary) =>
      diary.entryDate.year == _selected.year &&
      diary.entryDate.month == _selected.month &&
      diary.entryDate.day == _selected.day;
}

class _DiaryMonthCalendar extends StatelessWidget {
  const _DiaryMonthCalendar({
    required this.month,
    required this.selected,
    required this.diaries,
    required this.onMonthChanged,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime selected;
  final List<Diary> diaries;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final leadingDays = first.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final counts = <int, int>{};
    for (final diary in diaries) {
      if (diary.entryDate.year == month.year &&
          diary.entryDate.month == month.month) {
        counts.update(
          diary.entryDate.day,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '이전 달',
                onPressed: () =>
                    onMonthChanged(DateTime(month.year, month.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('yyyy년 M월').format(month),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () {
                  final value = DateTime(today.year, today.month, today.day);
                  onMonthChanged(DateTime(value.year, value.month));
                  onSelected(value);
                },
                child: const Text('오늘'),
              ),
              IconButton(
                tooltip: '다음 달',
                onPressed: () =>
                    onMonthChanged(DateTime(month.year, month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Row(
            children: [
              for (final label in ['일', '월', '화', '수', '목', '금', '토'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(label, textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.18,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingDays + 1;
              if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
              final value = DateTime(month.year, month.month, day);
              final isSelected = _sameDay(value, selected);
              final isToday = _sameDay(value, today);
              final count = counts[day] ?? 0;
              final colors = Theme.of(context).colorScheme;
              return Semantics(
                button: true,
                selected: isSelected,
                label: '$day일${count == 0 ? '' : ', 일기 $count개'}',
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(value),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primaryContainer : null,
                      border: isToday && !isSelected
                          ? Border.all(color: colors.primary)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('$day'),
                        if (count > 0)
                          Positioned(
                            right: 4,
                            bottom: 3,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.onPrimary,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

class _CalendarDiaryTile extends StatelessWidget {
  const _CalendarDiaryTile(this.diary);

  final Diary diary;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    leading: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox.square(
        dimension: 56,
        child: DiaryMediaView(media: diary.media.first, thumbnail: true),
      ),
    ),
    title: Text(diary.headline ?? diary.body ?? '그날의 기록'),
    subtitle: Text(
      '${diary.entryTime.inHours.toString().padLeft(2, '0')}:'
      '${(diary.entryTime.inMinutes % 60).toString().padLeft(2, '0')}',
    ),
    trailing: diary.mood == null ? null : Text(diary.mood!),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiaryDetailScreen(diaryId: diary.id),
      ),
    ),
  );
}
