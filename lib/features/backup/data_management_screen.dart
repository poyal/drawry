import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../settings/app_settings.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  var _busy = false;

  Future<void> _export() async {
    final password = await _passwordDialog(confirm: true);
    if (password == null) return;
    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      final backup = await service.createBackup(password: password);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backup.path, mimeType: 'application/octet-stream')],
          subject: 'Drawry 암호화 백업',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (await backup.exists()) await backup.delete();
    } catch (error) {
      _message('백업하지 못했습니다. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    const type = XTypeGroup(
      label: 'Drawry backup',
      extensions: ['drawry'],
      uniformTypeIdentifiers: ['com.poyal.drawry.backup'],
    );
    final selected = await openFile(acceptedTypeGroups: const [type]);
    if (selected == null || !mounted) return;
    final options = await showDialog<_RestoreOptions>(
      context: context,
      builder: (_) => const _RestoreDialog(),
    );
    if (options == null) return;
    setState(() => _busy = true);
    try {
      final service = await ref.read(backupServiceProvider.future);
      await service.restoreBackup(
        source: File(selected.path),
        password: options.password,
        recoveryCode: options.recoveryCode,
        replaceExisting: options.replace,
      );
      ref.invalidate(activeDiariesProvider);
      ref.invalidate(trashDiariesProvider);
      ref.invalidate(settingsProvider);
      _message('복원이 완료되었습니다.');
    } catch (error) {
      _message('복원하지 못했습니다. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _passwordDialog({required bool confirm}) async {
    final first = TextEditingController();
    final second = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 암호 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: first,
              obscureText: true,
              decoration: const InputDecoration(labelText: '8자 이상 암호'),
            ),
            if (confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: second,
                obscureText: true,
                decoration: const InputDecoration(labelText: '암호 확인'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (first.text.length < 8 ||
                  (confirm && first.text != second.text)) {
                return;
              }
              Navigator.pop(context, first.text);
            },
            child: const Text('계속'),
          ),
        ],
      ),
    );
    first.dispose();
    second.dispose();
    return result;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('백업 및 복원')),
    body: Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.enhanced_encryption_outlined),
                    title: const Text('암호화 백업 만들기'),
                    subtitle: const Text('일기·설정·암호화 미디어를 하나의 파일로 내보냅니다.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _busy ? null : _export,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded),
                    title: const Text('백업에서 복원'),
                    subtitle: const Text('기존 데이터에 합치거나 모두 교체할 수 있습니다.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _busy ? null : _restore,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '복구 키',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('백업 암호를 잊었을 때 필요합니다. 안전한 별도 장소에 보관하세요.'),
                    const SizedBox(height: 12),
                    FutureBuilder<String>(
                      future: ref
                          .read(backupServiceProvider.future)
                          .then((service) => service.recoveryCode()),
                      builder: (context, snapshot) => SelectableText(
                        snapshot.data ?? '불러오는 중…',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final service = await ref.read(
                          backupServiceProvider.future,
                        );
                        await Clipboard.setData(
                          ClipboardData(text: await service.recoveryCode()),
                        );
                        _message('복구 키를 복사했습니다.');
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('복사'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('백업 파일도 암호화됩니다. 암호와 복구 키를 모두 잃으면 데이터를 복원할 수 없습니다.'),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x55000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
  );
}

final class _RestoreOptions {
  const _RestoreOptions({
    required this.replace,
    this.password,
    this.recoveryCode,
  });

  final bool replace;
  final String? password;
  final String? recoveryCode;
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _credential = TextEditingController();
  var _recovery = false;
  var _replace = false;

  @override
  void dispose() {
    _credential.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('백업 복원'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('암호')),
            ButtonSegment(value: true, label: Text('복구 키')),
          ],
          selected: {_recovery},
          onSelectionChanged: (value) =>
              setState(() => _recovery = value.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _credential,
          obscureText: !_recovery,
          decoration: InputDecoration(labelText: _recovery ? '복구 키' : '백업 암호'),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('현재 데이터 모두 교체'),
          subtitle: Text(
            _replace ? '현재 일기가 삭제되고 백업으로 교체됩니다.' : '현재 일기에 백업을 합칩니다.',
          ),
          value: _replace,
          onChanged: (value) => setState(() => _replace = value),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(
        onPressed: () {
          if (_credential.text.trim().isEmpty) return;
          Navigator.pop(
            context,
            _RestoreOptions(
              replace: _replace,
              password: _recovery ? null : _credential.text,
              recoveryCode: _recovery ? _credential.text : null,
            ),
          );
        },
        child: const Text('복원'),
      ),
    ],
  );
}
