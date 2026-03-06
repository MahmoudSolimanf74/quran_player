import 'package:flutter/material.dart';
import '../models/track.dart';

/// A single row in the library list.  The design is heavily based on the
/// React `TrackItem` component provided by the user, but translated to
/// Flutter and using built in icons.
class TrackItem extends StatelessWidget {
  final Track track;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;

  const TrackItem({
    Key? key,
    required this.track,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      color: isActive ? const Color(0xFF8B5CF6) : Colors.white,
      fontWeight: FontWeight.w600,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // thumbnail/gradient
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [track.gradientFrom, track.gradientTo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isActive
                  ? Container(
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: isPlaying
                            ? const Icon(
                                Icons.equalizer,
                                color: Colors.white,
                                size: 24,
                              )
                            : const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: titleStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(track.duration),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
