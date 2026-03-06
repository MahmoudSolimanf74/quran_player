import 'package:flutter/material.dart';
import '../models/track.dart';
import 'player_controls.dart';
import 'progress_bar.dart';

class NowPlayingScreen extends StatelessWidget {
  final Track track;
  final Duration progress;
  final Duration duration;
  final bool isPlaying;
  final VoidCallback onClose;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final RepeatMode repeatMode;
  final VoidCallback toggleRepeat;
  final bool isShuffled;
  final VoidCallback toggleShuffle;
  final ValueChanged<Duration> onSeek;

  const NowPlayingScreen({
    Key? key,
    required this.track,
    required this.progress,
    required this.duration,
    required this.isPlaying,
    required this.onClose,
    required this.onTogglePlay,
    required this.onNext,
    required this.onPrev,
    required this.repeatMode,
    required this.toggleRepeat,
    required this.isShuffled,
    required this.toggleShuffle,
    required this.onSeek,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // primary background gradient glow
    final bgGradient = Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [track.gradientFrom, track.gradientTo.withOpacity(0)],
          center: const Alignment(0, -0.5),
          radius: 1.5,
        ),
      ),
    );

    // solid black overlay to fully hide underlying content
    final bgOverlay = Container(color: Colors.black);

    return Stack(
      children: [
        // dark overlay then glow on top
        Positioned.fill(child: bgOverlay),
        Positioned.fill(child: bgGradient),
        Column(
          children: [
            // handle / safety area
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // small drag indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: onClose,
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 32),
            // album art placeholder
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [track.gradientFrom, track.gradientTo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: track.gradientFrom.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                track.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ProgressBar(
                progress: progress,
                duration: duration,
                onSeek: onSeek,
              ),
            ),
            const SizedBox(height: 24),
            PlayerControls(
              isPlaying: isPlaying,
              togglePlay: onTogglePlay,
              next: onNext,
              prev: onPrev,
              repeatMode: repeatMode,
              toggleRepeat: toggleRepeat,
              isShuffled: isShuffled,
              toggleShuffle: toggleShuffle,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.66,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
