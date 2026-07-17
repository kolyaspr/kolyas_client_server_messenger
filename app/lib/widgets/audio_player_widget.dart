import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int? durationSeconds;
  final bool isOwnMessage;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.durationSeconds,
    this.isOwnMessage = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();

    if (widget.durationSeconds != null) {
      _total = Duration(seconds: widget.durationSeconds!);
    }

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _total = dur);
    });

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else {
        await _player.play(UrlSource(widget.audioUrl));
      }
    } on Exception catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось воспроизвести аудио')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final iconColor = widget.isOwnMessage ? Colors.white : const Color(0xFF8B7CFF);
    final textColor =
        widget.isOwnMessage ? Colors.white.withOpacity(0.78) : const Color(0xFFB6BED8);
    final sliderColor = widget.isOwnMessage ? Colors.white : const Color(0xFF8B7CFF);

    final progress = _total.inMilliseconds > 0
        ? _position.inMilliseconds / _total.inMilliseconds
        : 0.0;

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isOwnMessage
            ? Colors.white.withOpacity(0.10)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              size: 34,
              color: iconColor,
            ),
            onPressed: _togglePlay,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: sliderColor,
                    inactiveTrackColor: sliderColor.withOpacity(0.28),
                    thumbColor: sliderColor,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (v) async {
                      final pos =
                          Duration(milliseconds: (v * _total.inMilliseconds).toInt());
                      await _player.seek(pos);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_total)}',
                    style: TextStyle(fontSize: 11, color: textColor),
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