import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../diary/domain/diary.dart';
import '../diary/presentation/media_viewer.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trash = ref.watch(trashDiariesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('휴지통')),
      body: trash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('휴지통이 비어 있어요.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) => _TrashTile(diary: items[index]),
              ),
      ),
    );
  }
}

class _TrashTile extends ConsumerWidget {
  const _TrashTile({required this.diary});

  final Diary diary;

  Future<void> _restore(WidgetRef ref) async {
    await (await ref.read(diaryRepositoryProvider.future)).restore(diary.id);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('완전히 삭제할까요?'),
        content: const Text('암호화 키와 미디어 파일이 제거되며 복원할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('완전히 삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await (await ref.read(
        diaryRepositoryProvider.future,
      )).deletePermanently(diary.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = diary.purgeAt?.difference(DateTime.now().toUtc()).inDays ?? 0;
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: 56,
            child: DiaryMediaView(media: diary.media.first, thumbnail: true),
          ),
        ),
        title: Text(
          diary.headline ?? DateFormat('yyyy.M.d').format(diary.entryDate),
        ),
        subtitle: Text('${days < 0 ? 0 : days}일 후 자동 삭제'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'restore') _restore(ref);
            if (value == 'delete') _delete(context, ref);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'restore', child: Text('복원')),
            PopupMenuItem(value: 'delete', child: Text('완전히 삭제')),
          ],
        ),
      ),
    );
  }
}
