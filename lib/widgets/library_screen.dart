import 'package:flutter/material.dart';
import '../models/track.dart';
import 'track_item.dart';

class LibraryScreen extends StatefulWidget {
  final List<Track> tracks;
  final Track? currentTrack;
  final bool isPlaying;
  final Function(Track) onTrackSelected;
  final VoidCallback onOpenNowPlaying;
  final VoidCallback onPickFolder;

  const LibraryScreen({
    Key? key,
    required this.tracks,
    required this.currentTrack,
    required this.isPlaying,
    required this.onTrackSelected,
    required this.onOpenNowPlaying,
    required this.onPickFolder,
  }) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.tracks.where((t) {
      final q = _search.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.id.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 56),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.library_music, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'مكتبة القارئ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  onPressed: widget.onPickFolder,
                  tooltip: 'اختر مجلد',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة أو قارئ...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() {
                _search = v;
              }),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'لا يوجد نتائج',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      return TrackItem(
                        track: t,
                        isActive: widget.currentTrack?.id == t.id,
                        isPlaying:
                            widget.isPlaying && widget.currentTrack?.id == t.id,
                        onTap: () {
                          widget.onTrackSelected(t);
                          widget.onOpenNowPlaying();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0D0D0D),
    );
  }
}
