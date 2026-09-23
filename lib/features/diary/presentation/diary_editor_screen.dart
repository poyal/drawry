import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:video_player/video_player.dart';

import '../../../core/database/app_database.dart';
import '../../../core/media/media_storage.dart';
import '../../../core/providers.dart';
import '../../settings/app_settings.dart';
import '../data/diary_draft_codec.dart';
import '../domain/diary.dart';
import 'media_viewer.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  const DiaryEditorScreen({super.key, this.initial});

  final Diary? initial;

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen>
    with WidgetsBindingObserver {
  final _picker = ImagePicker();
  late final TextEditingController _headline;
  late final TextEditingController _body;
  late final TextEditingController _tags;
  late final TextEditingController _companions;
  late final TextEditingController _temperature;
  late final TextEditingController _minimumTemperature;
  late final TextEditingController _maximumTemperature;
  late DateTime _entryDateTime;
  late List<DiaryMedia> _media;
  final Set<String> _newMediaIds = {};
  final Set<String> _changedExistingVideoFrames = {};
  String? _mood;
  WeatherCondition? _weatherCondition;
  bool? _precipitation;
  late int _weatherDisplayMask;
  var _busy = false;
  var _saved = false;
  var _draftReady = false;
  Timer? _draftTimer;
  Future<void>? _draftWriteFuture;
  AppDatabase? _database;
  late final String _draftId;

  static const _moods = ['😊', '🥰', '😌', '😐', '😔', '😢', '😡', '😴'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final diary = widget.initial;
    _draftId = 'editor:${diary?.id ?? 'new'}';
    _headline = TextEditingController(text: diary?.headline);
    _body = TextEditingController(text: diary?.body);
    _tags = TextEditingController(text: diary?.tags.join(', '));
    _companions = TextEditingController(text: diary?.companions.join(', '));
    _temperature = TextEditingController(
      text: _numberText(diary?.weather?.temperature),
    );
    _minimumTemperature = TextEditingController(
      text: _numberText(diary?.weather?.minimumTemperature),
    );
    _maximumTemperature = TextEditingController(
      text: _numberText(diary?.weather?.maximumTemperature),
    );
    final date = diary?.entryDate ?? DateTime.now();
    final time = diary?.entryTime;
    _entryDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time?.inHours ?? date.hour,
      time == null ? date.minute : time.inMinutes % 60,
    );
    _media = [...?diary?.media];
    _mood = diary?.mood;
    _weatherCondition = diary?.weather?.condition;
    _precipitation = diary?.weather?.precipitation;
    _weatherDisplayMask =
        diary?.weather?.displayMask ??
        ref.read(settingsProvider).value?.weatherDisplayMask ??
        WeatherEntry.allMask;
    for (final controller in [
      _headline,
      _body,
      _tags,
      _companions,
      _temperature,
      _minimumTemperature,
      _maximumTemperature,
    ]) {
      controller.addListener(_scheduleDraftSave);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreDraft());
    });
  }

  static String _numberText(double? value) =>
      value == null ? '' : value.toString().replaceFirst(RegExp(r'\.0$'), '');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _draftTimer?.cancel();
      unawaited(_writeDraft());
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final database = await ref.read(databaseProvider.future);
      _database = database;
      final row = await database.draftById(_draftId);
      if (row == null) {
        _draftReady = true;
        return;
      }
      final snapshot = decodeDiaryDraft(row.payloadJson);
      if (!mounted) return;
      final restore = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('작성 중인 일기가 있습니다'),
          content: const Text('암호화해 임시 저장한 내용을 이어서 작성할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('폐기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('복구'),
            ),
          ],
        ),
      );
      if (restore != true) {
        final storage = ref.read(mediaStorageProvider);
        for (final media in snapshot.draft.media.where(
          (item) => snapshot.newMediaIds.contains(item.id),
        )) {
          await storage.deleteMedia(media);
        }
        await database.deleteDraft(_draftId);
        _draftReady = true;
        return;
      }
      final availableMedia = <DiaryMedia>[];
      final storage = ref.read(mediaStorageProvider);
      for (final media in snapshot.draft.media) {
        if (await storage.containsEncrypted(media)) availableMedia.add(media);
      }
      final draft = snapshot.draft;
      _headline.text = draft.headline ?? '';
      _body.text = draft.body ?? '';
      _tags.text = draft.tags.join(', ');
      _companions.text = draft.companions.join(', ');
      _temperature.text = _numberText(draft.weather?.temperature);
      _minimumTemperature.text = _numberText(draft.weather?.minimumTemperature);
      _maximumTemperature.text = _numberText(draft.weather?.maximumTemperature);
      if (!mounted) return;
      setState(() {
        _entryDateTime = draft.entryDateTime;
        _media = availableMedia;
        _newMediaIds
          ..clear()
          ..addAll(
            snapshot.newMediaIds.where(
              (id) => availableMedia.any((media) => media.id == id),
            ),
          );
        _mood = draft.mood;
        _weatherCondition = draft.weather?.condition;
        _precipitation = draft.weather?.precipitation;
        _weatherDisplayMask = draft.weather?.displayMask ?? _weatherDisplayMask;
      });
      _draftReady = true;
      _scheduleDraftSave();
    } catch (error) {
      _draftReady = true;
      _message('임시 저장 내용을 불러오지 못했습니다. $error');
    }
  }

  DiaryDraft _currentDraft() => DiaryDraft(
    id: widget.initial?.id,
    entryDateTime: _entryDateTime,
    headline: _headline.text,
    body: _body.text,
    mood: _mood,
    tags: _split(_tags.text),
    companions: _split(_companions.text),
    media: _media,
    weather: _currentWeather(),
  );

  WeatherEntry? _currentWeather() {
    final weather = WeatherEntry(
      condition: _weatherCondition,
      temperature: _parse(_temperature.text),
      minimumTemperature: _parse(_minimumTemperature.text),
      maximumTemperature: _parse(_maximumTemperature.text),
      precipitation: _precipitation,
      displayMask: _weatherDisplayMask,
    );
    return weather.isEmpty ? null : weather;
  }

  void _scheduleDraftSave() {
    if (!_draftReady || _saved) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 600), () {
      unawaited(_writeDraft());
    });
  }

  Future<void> _writeDraft() async {
    final pending = _draftWriteFuture;
    if (pending != null) await pending;
    if (!_draftReady || _saved) return;
    final operation = _persistDraft();
    _draftWriteFuture = operation;
    try {
      await operation;
    } catch (_) {
      // A failed autosave must not interrupt the user's current edit session.
    } finally {
      if (identical(_draftWriteFuture, operation)) _draftWriteFuture = null;
    }
  }

  Future<void> _persistDraft() async {
    final AppDatabase database =
        _database ?? await ref.read(databaseProvider.future);
    _database = database;
    await database.putDraft(
      _draftId,
      encodeDiaryDraft(
        DiaryDraftSnapshot(draft: _currentDraft(), newMediaIds: _newMediaIds),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    _draftReady = false;
    if (!_saved) {
      final database = _database;
      if (database != null) {
        unawaited(
          (_draftWriteFuture ?? Future<void>.value()).then(
            (_) => database.deleteDraft(_draftId),
          ),
        );
      }
      final storage = ref.read(mediaStorageProvider);
      for (final media in _media.where(
        (item) => _newMediaIds.contains(item.id),
      )) {
        unawaited(storage.deleteMedia(media));
      }
      for (final original in widget.initial?.media ?? const <DiaryMedia>[]) {
        if (_changedExistingVideoFrames.contains(original.id)) {
          unawaited(
            storage.updateVideoRepresentative(
              original,
              original.representativeFrame ?? Duration.zero,
            ),
          );
        }
      }
    }
    _headline.dispose();
    _body.dispose();
    _tags.dispose();
    _companions.dispose();
    _temperature.dispose();
    _minimumTemperature.dispose();
    _maximumTemperature.dispose();
    super.dispose();
  }

  Future<void> _pickLibrary() async {
    final remaining = const MediaLimits().maxItems - _media.length;
    if (remaining <= 0) return _message('미디어는 최대 10개까지 추가할 수 있습니다.');
    final selected = await _picker.pickMultipleMedia(
      limit: remaining,
      requestFullMetadata: false,
    );
    await _import(selected);
  }

  Future<void> _capture(ImageSource source, {required bool video}) async {
    final picked = video
        ? await _picker.pickVideo(
            source: source,
            maxDuration: const Duration(seconds: 30),
          )
        : await _picker.pickImage(source: source, requestFullMetadata: false);
    if (picked != null) await _import([picked]);
  }

  Future<void> _import(List<XFile> files) async {
    if (files.isEmpty) return;
    setState(() => _busy = true);
    try {
      final storage = ref.read(mediaStorageProvider);
      final preserveOriginal =
          ref.read(settingsProvider).value?.preserveOriginal ?? false;
      for (final file in files) {
        final lower = file.path.toLowerCase();
        final isVideo =
            file.mimeType?.startsWith('video/') == true ||
            lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.m4v');
        DiaryMedia imported;
        if (isVideo) {
          if (_media
                  .where((item) => item.kind == DiaryMediaKind.video)
                  .length >=
              const MediaLimits().maxVideos) {
            throw const FormatException('영상은 최대 3개까지 추가할 수 있습니다.');
          }
          final controller = VideoPlayerController.file(File(file.path));
          try {
            await controller.initialize();
            imported = await storage.importVideo(
              file,
              duration: controller.value.duration,
              mimeType: file.mimeType ?? 'video/mp4',
            );
          } finally {
            await controller.dispose();
          }
        } else {
          imported = await storage.importImage(
            file,
            preserveOriginal: preserveOriginal,
          );
        }
        _newMediaIds.add(imported.id);
        if (mounted) {
          setState(() => _media.add(imported));
          _scheduleDraftSave();
        }
      }
    } catch (error) {
      _message('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editImage(int index) async {
    final current = _media[index];
    if (current.kind != DiaryMediaKind.image) return;
    setState(() => _busy = true);
    try {
      final storage = ref.read(mediaStorageProvider);
      final file = await storage.materialize(current);
      if (!mounted) return;
      final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute<Uint8List>(
          builder: (_) => _ImageEditorPage(file: file),
        ),
      );
      if (bytes == null) return;
      final edited = await storage.importImage(
        XFile.fromData(
          bytes,
          mimeType: 'image/jpeg',
          name: '${current.id}-edited.jpg',
        ),
        preserveOriginal: true,
      );
      _newMediaIds.add(edited.id);
      if (_newMediaIds.remove(current.id)) await storage.deleteMedia(current);
      if (mounted) {
        setState(() => _media[index] = edited);
        _scheduleDraftSave();
      }
    } catch (error) {
      _message('이미지를 편집하지 못했습니다. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(int index) async {
    final removed = _media.removeAt(index);
    setState(() {});
    _scheduleDraftSave();
    if (_newMediaIds.remove(removed.id)) {
      await ref.read(mediaStorageProvider).deleteMedia(removed);
    }
  }

  Future<void> _chooseVideoFrame(int index) async {
    final current = _media[index];
    final duration = current.duration ?? Duration.zero;
    if (duration == Duration.zero) return;
    var seconds = (current.representativeFrame ?? Duration.zero).inMilliseconds
        .toDouble();
    final selected = await showDialog<Duration>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('대표 화면 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(seconds / 1000).toStringAsFixed(1)}초'),
              Slider(
                min: 0,
                max: duration.inMilliseconds.toDouble(),
                value: seconds.clamp(0, duration.inMilliseconds.toDouble()),
                onChanged: (value) => setDialogState(() => seconds = value),
              ),
              const Text('선택한 시점의 정지 이미지를 피드와 공유에 사용합니다.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                Duration(milliseconds: seconds.round()),
              ),
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(mediaStorageProvider)
          .updateVideoRepresentative(current, selected);
      if (!_newMediaIds.contains(current.id)) {
        _changedExistingVideoFrames.add(current.id);
      }
      if (mounted) {
        setState(() => _media[index] = updated);
        _scheduleDraftSave();
      }
    } catch (error) {
      _message('대표 화면을 만들지 못했습니다. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _entryDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entryDateTime),
    );
    if (time == null) return;
    setState(() {
      _entryDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
    _scheduleDraftSave();
  }

  Future<void> _save() async {
    if (_media.isEmpty) return _message('사진 또는 영상을 한 개 이상 추가하세요.');
    setState(() => _busy = true);
    try {
      await (await ref.read(
        diaryRepositoryProvider.future,
      )).save(_currentDraft());
      _saved = true;
      _draftReady = false;
      _draftTimer?.cancel();
      await _draftWriteFuture;
      await _database?.deleteDraft(_draftId);
      ref.invalidate(activeDiariesProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _message('저장하지 못했습니다. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  double? _parse(String value) => double.tryParse(value.trim());

  List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? '새 일기' : '일기 수정'),
        actions: [
          TextButton(onPressed: _busy ? null : _save, child: const Text('저장')),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              _MediaEditor(
                media: _media,
                onLibrary: _pickLibrary,
                onCameraImage: () => _capture(ImageSource.camera, video: false),
                onCameraVideo: () => _capture(ImageSource.camera, video: true),
                onEdit: _editImage,
                onVideoFrame: _chooseVideoFrame,
                onRemove: _remove,
                onReorder: _scheduleDraftSave,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.schedule_rounded),
                title: Text(
                  '${_entryDateTime.year}.${_entryDateTime.month.toString().padLeft(2, '0')}.'
                  '${_entryDateTime.day.toString().padLeft(2, '0')}  '
                  '${_entryDateTime.hour.toString().padLeft(2, '0')}:'
                  '${_entryDateTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _headline,
                maxLength: 80,
                decoration: const InputDecoration(labelText: '오늘의 한 줄 (선택)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                minLines: 4,
                maxLines: 12,
                decoration: const InputDecoration(labelText: '일기 내용 (선택)'),
              ),
              const SizedBox(height: 20),
              Text('기분 (선택)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _moods
                    .map(
                      (mood) => ChoiceChip(
                        label: Text(mood),
                        selected: _mood == mood,
                        onSelected: (selected) {
                          setState(() => _mood = selected ? mood : null);
                          _scheduleDraftSave();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: '태그 (선택)',
                  hintText: '여행, 가족처럼 쉼표로 구분',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _companions,
                decoration: const InputDecoration(
                  labelText: '함께한 사람 (선택)',
                  hintText: '쉼표로 구분',
                ),
              ),
              const SizedBox(height: 24),
              _WeatherEditor(
                condition: _weatherCondition,
                precipitation: _precipitation,
                displayMask: _weatherDisplayMask,
                temperature: _temperature,
                minimumTemperature: _minimumTemperature,
                maximumTemperature: _maximumTemperature,
                onCondition: (value) {
                  setState(() => _weatherCondition = value);
                  _scheduleDraftSave();
                },
                onPrecipitation: (value) {
                  setState(() => _precipitation = value);
                  _scheduleDraftSave();
                },
                onDisplayMask: (value) {
                  setState(() => _weatherDisplayMask = value);
                  _scheduleDraftSave();
                  unawaited(
                    ref
                        .read(settingsProvider.notifier)
                        .save(
                          (settings) =>
                              settings.copyWith(weatherDisplayMask: value),
                        ),
                  );
                },
              ),
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
    ),
  );
}

class _MediaEditor extends StatelessWidget {
  const _MediaEditor({
    required this.media,
    required this.onLibrary,
    required this.onCameraImage,
    required this.onCameraVideo,
    required this.onEdit,
    required this.onVideoFrame,
    required this.onRemove,
    required this.onReorder,
  });

  final List<DiaryMedia> media;
  final VoidCallback onLibrary;
  final VoidCallback onCameraImage;
  final VoidCallback onCameraVideo;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onVideoFrame;
  final ValueChanged<int> onRemove;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (media.isNotEmpty)
        SizedBox(
          height: 148,
          child: ReorderableListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: media.length,
            onReorderItem: (oldIndex, newIndex) {
              final item = media.removeAt(oldIndex);
              media.insert(newIndex, item);
              onReorder();
            },
            itemBuilder: (context, index) => Padding(
              key: ValueKey(media[index].id),
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DiaryMediaView(
                        media: media[index],
                        thumbnail: true,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onRemove(index),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                    if (media[index].kind == DiaryMediaKind.image)
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: FilledButton.tonalIcon(
                          onPressed: () => onEdit(index),
                          icon: const Icon(Icons.auto_fix_high, size: 16),
                          label: const Text('꾸미기'),
                        ),
                      ),
                    if (media[index].kind == DiaryMediaKind.video)
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: FilledButton.tonalIcon(
                          onPressed: () => onVideoFrame(index),
                          icon: const Icon(Icons.video_settings, size: 16),
                          label: const Text('대표 화면'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onLibrary,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('보관함'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: '사진 촬영',
            onPressed: onCameraImage,
            icon: const Icon(Icons.photo_camera_outlined),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: '영상 촬영',
            onPressed: onCameraVideo,
            icon: const Icon(Icons.videocam_outlined),
          ),
        ],
      ),
      if (media.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('사진 또는 영상 1개 이상은 필수입니다.'),
        ),
    ],
  );
}

class _WeatherEditor extends StatelessWidget {
  const _WeatherEditor({
    required this.condition,
    required this.precipitation,
    required this.displayMask,
    required this.temperature,
    required this.minimumTemperature,
    required this.maximumTemperature,
    required this.onCondition,
    required this.onPrecipitation,
    required this.onDisplayMask,
  });

  final WeatherCondition? condition;
  final bool? precipitation;
  final int displayMask;
  final TextEditingController temperature;
  final TextEditingController minimumTemperature;
  final TextEditingController maximumTemperature;
  final ValueChanged<WeatherCondition?> onCondition;
  final ValueChanged<bool?> onPrecipitation;
  final ValueChanged<int> onDisplayMask;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('과거 날씨 직접 기록 (선택)'),
    subtitle: const Text('위치나 네트워크 권한 없이 직접 입력합니다.'),
    children: [
      DropdownButtonFormField<WeatherCondition?>(
        initialValue: condition,
        decoration: const InputDecoration(labelText: '날씨'),
        items: const [
          DropdownMenuItem(value: null, child: Text('선택 안 함')),
          DropdownMenuItem(value: WeatherCondition.sunny, child: Text('맑음 ☀️')),
          DropdownMenuItem(
            value: WeatherCondition.cloudy,
            child: Text('흐림 ☁️'),
          ),
          DropdownMenuItem(value: WeatherCondition.rain, child: Text('비 🌧️')),
          DropdownMenuItem(value: WeatherCondition.snow, child: Text('눈 ❄️')),
          DropdownMenuItem(value: WeatherCondition.fog, child: Text('안개 🌫️')),
          DropdownMenuItem(value: WeatherCondition.windy, child: Text('바람 💨')),
          DropdownMenuItem(value: WeatherCondition.other, child: Text('기타')),
        ],
        onChanged: onCondition,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _TemperatureField(controller: temperature, label: '기온'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TemperatureField(
              controller: minimumTemperature,
              label: '최저',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TemperatureField(
              controller: maximumTemperature,
              label: '최고',
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SegmentedButton<bool?>(
        segments: const [
          ButtonSegment(value: null, label: Text('미입력')),
          ButtonSegment(value: false, label: Text('강수 없음')),
          ButtonSegment(value: true, label: Text('강수 있음')),
        ],
        selected: {precipitation},
        onSelectionChanged: (value) => onPrecipitation(value.first),
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '일기와 공유에 표시할 항목',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          _maskChip('상태', WeatherEntry.conditionMask),
          _maskChip('기온', WeatherEntry.temperatureMask),
          _maskChip('최저·최고', WeatherEntry.rangeMask),
          _maskChip('강수', WeatherEntry.precipitationMask),
        ],
      ),
    ],
  );

  Widget _maskChip(String label, int mask) => FilterChip(
    label: Text(label),
    selected: displayMask & mask != 0,
    onSelected: (selected) =>
        onDisplayMask(selected ? displayMask | mask : displayMask & ~mask),
  );
}

class _TemperatureField extends StatelessWidget {
  const _TemperatureField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    decoration: InputDecoration(labelText: '$label °C'),
  );
}

class _ImageEditorPage extends StatelessWidget {
  const _ImageEditorPage({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) => ProImageEditor.file(
    file,
    callbacks: ProImageEditorCallbacks(
      onImageEditingComplete: (bytes) async {
        if (context.mounted) Navigator.of(context).pop(bytes);
      },
    ),
  );
}
