import 'package:flutter/material.dart';
import '../models/track.dart';

class MiniPlayer extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final Duration progress;
  final Duration duration;
  final VoidCallback onTogglePlay;
  final VoidCallback onNext;
  final VoidCallback onTap;

  const MiniPlayer({
    Key? key,
    required this.track,
    required this.isPlaying,
    required this.progress,
    required this.duration,
    required this.onTogglePlay,
    required this.onNext,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = duration.inMilliseconds > 0
        ? progress.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        padding: const EdgeInsets.all(8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // progress bar
            Stack(
              children: [
                Container(height: 2, color: Colors.white.withOpacity(0.05)),
                FractionallySizedBox(
                  widthFactor: percent,
                  child: Container(height: 2, color: const Color(0xFF8B5CF6)),
                ),
              ],
            ),
            Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [track.gradientFrom, track.gradientTo],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: onTogglePlay,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: onNext,
                  ),
                ],
              ),
          ],
          
        ),
      ),
    );
  }
}
