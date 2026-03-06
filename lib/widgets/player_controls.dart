import 'package:flutter/material.dart';

enum RepeatMode { off, all, one }

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback togglePlay;
  final VoidCallback next;
  final VoidCallback prev;
  final RepeatMode repeatMode;
  final VoidCallback toggleRepeat;
  final bool isShuffled;
  final VoidCallback toggleShuffle;

  const PlayerControls({
    Key? key,
    required this.isPlaying,
    required this.togglePlay,
    required this.next,
    required this.prev,
    required this.repeatMode,
    required this.toggleRepeat,
    required this.isShuffled,
    required this.toggleShuffle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color iconColor(bool active) =>
        active ? const Color(0xFF8B5CF6) : Colors.grey;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle),
          color: iconColor(isShuffled),
          onPressed: toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          color: Colors.white,
          onPressed: prev,
        ),
        GestureDetector(
          onTap: togglePlay,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          color: Colors.white,
          onPressed: next,
        ),
        IconButton(
          icon: Icon(
            repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
          ),
          color: iconColor(repeatMode != RepeatMode.off),
          onPressed: toggleRepeat,
        ),
      ],
    );
  }
}
