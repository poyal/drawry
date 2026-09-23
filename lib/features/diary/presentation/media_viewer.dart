import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/providers.dart';
import '../domain/diary.dart';

class DiaryMediaView extends ConsumerWidget {
  const DiaryMediaView({
    required this.media,
    super.key,
    this.thumbnail = false,
    this.fit = BoxFit.cover,
  });

  final DiaryMedia media;
  final bool thumbnail;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (thumbnail &&
        media.kind == DiaryMediaKind.video &&
        media.thumbnailPath == null) {
      return const ColoredBox(
        color: Colors.black87,
        child: Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
      );
    }
    return FutureBuilder<File>(
      future: ref
          .read(mediaStorageProvider)
          .materialize(
            media,
            thumbnail: thumbnail && media.thumbnailPath != null,
          ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ColoredBox(
            color: Colors.black12,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          );
        }
        final file = snapshot.data;
        if (file == null) {
          return const ColoredBox(
            color: Colors.black12,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (media.kind == DiaryMediaKind.video && !thumbnail) {
          return _VideoView(file: file);
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: fit, gaplessPlayback: true),
            if (media.kind == DiaryMediaKind.video)
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black54,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VideoView extends StatefulWidget {
  const _VideoView({required this.file});

  final File file;

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialized;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file);
    _initialized = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialized,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      return GestureDetector(
        onTap: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            if (!_controller.value.isPlaying)
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
          ],
        ),
      );
    },
  );
}
