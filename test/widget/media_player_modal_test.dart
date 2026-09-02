import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/screens/viewers/media_player_modal.dart';
import 'package:file_manager/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AudioPlayerModal renders track title and playback controls', (tester) async {
    final item = FileItem(
      path: '/sdcard/song.mp3',
      name: 'song.mp3',
      size: 4 * 1024 * 1024,
      isDirectory: false,
      lastModified: DateTime.now(),
      extension: 'mp3',
      mimeType: 'audio/mpeg',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AudioPlayerModal(item: item),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('song.mp3'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byIcon(Icons.replay_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.forward_10_rounded), findsOneWidget);

    // Dispose modal to cleanly stop the audio periodic timer
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('VideoViewerModal renders video title and system player action', (tester) async {
    final item = FileItem(
      path: '/sdcard/movie.mp4',
      name: 'movie.mp4',
      size: 50 * 1024 * 1024,
      isDirectory: false,
      lastModified: DateTime.now(),
      extension: 'mp4',
      mimeType: 'video/mp4',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: VideoViewerModal(item: item),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('movie.mp4'), findsOneWidget);
    expect(find.text('Play in System Video Player'), findsOneWidget);
  });
}
