import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/file_item.dart';
import '../../providers/file_explorer_provider.dart';
import '../../services/platform_channel_service.dart';
import '../../theme/colors.dart';

class AudioPlayerModal extends ConsumerStatefulWidget {
  final FileItem item;

  const AudioPlayerModal({super.key, required this.item});

  static void show(BuildContext context, FileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AudioPlayerModal(item: item),
    );
  }

  @override
  ConsumerState<AudioPlayerModal> createState() => _AudioPlayerModalState();
}

class _AudioPlayerModalState extends ConsumerState<AudioPlayerModal> {
  late final PlatformChannelService _platformService;
  Timer? _positionTimer;
  bool _isPlaying = false;
  int _positionMs = 0;
  int _durationMs = 0;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _platformService = ref.read(platformServiceProvider);
    _startPlayback();
  }

  Future<void> _startPlayback() async {
    final res = await _platformService.playAudio(widget.item.path);
    if (mounted) {
      setState(() {
        _durationMs = res['duration'] as int? ?? 0;
        _positionMs = res['position'] as int? ?? 0;
        _isPlaying = res['isPlaying'] as bool? ?? true;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (!_isSeeking && mounted) {
        final pos = await _platformService.getAudioPosition();
        if (mounted) {
          setState(() {
            _positionMs = pos['position'] as int? ?? _positionMs;
            _durationMs = pos['duration'] as int? ?? _durationMs;
            _isPlaying = pos['isPlaying'] as bool? ?? _isPlaying;
          });
        }
      }
    });
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _platformService.pauseAudio();
      setState(() => _isPlaying = false);
    } else {
      await _platformService.resumeAudio();
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _seek(double val) async {
    final target = val.toInt();
    setState(() {
      _positionMs = target;
      _isSeeking = false;
    });
    await _platformService.seekAudio(target);
  }

  String _formatTime(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final remS = s % 60;
    return '${m.toString().padLeft(2, '0')}:${remS.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _platformService.stopAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxD = (_durationMs > 0 ? _durationMs : 1000).toDouble();
    final curP = _positionMs.toDouble().clamp(0.0, maxD);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Disc/Music Art
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentTeal.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.4), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.music_note_rounded, size: 40, color: AppColors.accentTeal),
            ),
          ),
          const SizedBox(height: 16),

          // Track Title
          Text(
            widget.item.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.item.extension.toUpperCase()} • ${widget.item.formattedSize}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          // Seek Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppColors.accentTeal,
              inactiveTrackColor: AppColors.surfaceGlass,
              thumbColor: AppColors.accentTeal,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: curP,
              min: 0.0,
              max: maxD,
              onChangeStart: (_) => _isSeeking = true,
              onChanged: (v) => setState(() => _positionMs = v.toInt()),
              onChangeEnd: _seek,
            ),
          ),

          // Time Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatTime(_positionMs), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(_formatTime(_durationMs), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, size: 28, color: AppColors.textPrimary),
                onPressed: () {
                  final target = (_positionMs - 10000).clamp(0, _durationMs);
                  _seek(target.toDouble());
                },
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentTeal,
                  ),
                  child: Center(
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, size: 28, color: AppColors.textPrimary),
                onPressed: () {
                  final target = (_positionMs + 10000).clamp(0, _durationMs);
                  _seek(target.toDouble());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VideoViewerModal extends ConsumerWidget {
  final FileItem item;

  const VideoViewerModal({super.key, required this.item});

  static void show(BuildContext context, FileItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VideoViewerModal(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Video Card Thumbnail Preview
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.video_library_rounded,
                    size: 64,
                    color: AppColors.accentTeal.withValues(alpha: 0.5),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(platformServiceProvider).openFileWithSystemApp(
                        item.path,
                        mimeType: item.mimeType.isNotEmpty ? item.mimeType : 'video/*',
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentTeal,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: 36),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.extension.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Video Title & Meta
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${item.formattedSize} • Modified ${item.lastModified.toString().split('.').first}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(platformServiceProvider).openFileWithSystemApp(
                  item.path,
                  mimeType: item.mimeType.isNotEmpty ? item.mimeType : 'video/*',
                );
              },
              child: const Text('Play in System Video Player', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
