import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../diary/domain/diary.dart';
import '../settings/app_settings.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({required this.diary, super.key});

  final Diary diary;

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _boundaryKey = GlobalKey();
  File? _image;
  late bool _date;
  late bool _headline;
  late bool _mood;
  late bool _body;
  late bool _weather;
  late bool _watermark;
  late String _ratio;
  late String _theme;
  var _sharing = false;

  @override
  void initState() {
    super.initState();
    final settings =
        ref.read(settingsProvider).value ?? const AppSettingsState();
    _date = settings.shareDate;
    _headline = settings.shareHeadline;
    _mood = settings.shareMood;
    _body = settings.shareBody;
    _weather = settings.shareWeather;
    _watermark = settings.shareWatermark;
    _ratio = settings.shareRatio;
    _theme = settings.shareTheme;
    _loadImage();
  }

  Future<void> _loadImage() async {
    final media = widget.diary.media.first;
    final image = await ref
        .read(mediaStorageProvider)
        .materialize(media, thumbnail: media.kind == DiaryMediaKind.video);
    if (mounted) setState(() => _image = image);
  }

  Future<void> _share() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _sharing = true);
    File? temporaryShareFile;
    try {
      await ref
          .read(settingsProvider.notifier)
          .save(
            (value) => value.copyWith(
              shareDate: _date,
              shareHeadline: _headline,
              shareMood: _mood,
              shareBody: _body,
              shareWeather: _weather,
              shareWatermark: _watermark,
              shareRatio: _ratio,
              shareTheme: _theme,
            ),
          );
      await WidgetsBinding.instance.endOfFrame;
      final rendered = await boundary.toImage(pixelRatio: 3);
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('공유 이미지를 만들지 못했습니다.');
      final temporary = await getTemporaryDirectory();
      final file = File(
        p.join(temporary.path, 'drawry-share-${widget.diary.id}.png'),
      );
      temporaryShareFile = file;
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'Drawry에서 만든 그림일기',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('공유하지 못했습니다. $error')));
      }
    } finally {
      if (temporaryShareFile != null && await temporaryShareFile.exists()) {
        await temporaryShareFile.delete();
      }
      if (mounted) setState(() => _sharing = false);
    }
  }

  double get _aspectRatio => switch (_ratio) {
    '1:1' => 1,
    '9:16' => 9 / 16,
    _ => 4 / 5,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('공유 이미지')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: RepaintBoundary(
              key: _boundaryKey,
              child: AspectRatio(
                aspectRatio: _aspectRatio,
                child: _ShareCard(
                  diary: widget.diary,
                  image: _image,
                  date: _date,
                  headline: _headline,
                  mood: _mood,
                  body: _body,
                  weather: _weather,
                  watermark: _watermark,
                  theme: _theme,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: '1:1', label: Text('1:1')),
            ButtonSegment(value: '4:5', label: Text('4:5')),
            ButtonSegment(value: '9:16', label: Text('9:16')),
          ],
          selected: {_ratio},
          onSelectionChanged: (value) => setState(() => _ratio = value.first),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'basic', label: Text('기본')),
            ButtonSegment(value: 'light', label: Text('밝게')),
            ButtonSegment(value: 'dark', label: Text('어둡게')),
          ],
          selected: {_theme},
          onSelectionChanged: (value) => setState(() => _theme = value.first),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('날짜'),
              selected: _date,
              onSelected: (v) => setState(() => _date = v),
            ),
            FilterChip(
              label: const Text('한 줄'),
              selected: _headline,
              onSelected: (v) => setState(() => _headline = v),
            ),
            FilterChip(
              label: const Text('기분'),
              selected: _mood,
              onSelected: (v) => setState(() => _mood = v),
            ),
            FilterChip(
              label: const Text('본문'),
              selected: _body,
              onSelected: (v) => setState(() => _body = v),
            ),
            FilterChip(
              label: const Text('날씨'),
              selected: _weather,
              onSelected: (v) => setState(() => _weather = v),
            ),
            FilterChip(
              label: const Text('Drawry 표시'),
              selected: _watermark,
              onSelected: (v) => setState(() => _watermark = v),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _sharing || _image == null ? null : _share,
          icon: _sharing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.ios_share_rounded),
          label: const Text('이미지로 공유'),
        ),
        const SizedBox(height: 8),
        const Text(
          '공유 파일에는 원본 GPS 메타데이터가 포함되지 않습니다.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.diary,
    required this.image,
    required this.date,
    required this.headline,
    required this.mood,
    required this.body,
    required this.weather,
    required this.watermark,
    required this.theme,
  });

  final Diary diary;
  final File? image;
  final bool date;
  final bool headline;
  final bool mood;
  final bool body;
  final bool weather;
  final bool watermark;
  final String theme;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, secondary) = switch (theme) {
      'light' => (
        const Color(0xFFFFFFFF),
        const Color(0xFF211A25),
        const Color(0xFF665F70),
      ),
      'dark' => (
        const Color(0xFF1E1822),
        const Color(0xFFF9F1FC),
        const Color(0xFFD6C8DB),
      ),
      _ => (
        const Color(0xFFF9F6FF),
        const Color(0xFF2B2430),
        const Color(0xFF665F70),
      ),
    };
    return ColoredBox(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: image == null
                  ? const Center(child: CircularProgressIndicator())
                  : Image.file(image!, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (date)
                  Text(
                    DateFormat('yyyy년 M월 d일').format(diary.entryDate),
                    style: TextStyle(color: secondary),
                  ),
                if (mood && diary.mood != null)
                  Text(
                    diary.mood!,
                    style: TextStyle(fontSize: 26, color: foreground),
                  ),
                if (headline && diary.headline != null)
                  Text(
                    diary.headline!,
                    maxLines: 2,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: foreground),
                  ),
                if (body && diary.body != null)
                  Text(
                    diary.body!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: foreground),
                  ),
                if (weather && diary.weather != null)
                  Text(
                    _weatherText(diary.weather!),
                    style: TextStyle(color: foreground),
                  ),
                if (watermark)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Drawry',
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _weatherText(WeatherEntry weather) => [
  if (weather.shows(WeatherEntry.conditionMask) && weather.condition != null)
    weather.condition!.name,
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
].join(' · ');
