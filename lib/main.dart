import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

import 'models/track.dart';
import 'widgets/library_screen.dart';
import 'widgets/mini_player.dart';
import 'widgets/now_playing_screen.dart';
import 'widgets/player_controls.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مشغل القرآن الكريم',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32), // أخضر داكن
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        focusColor: const Color(0xFF8B5CF6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32), // أخضر داكن
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: GoogleFonts.amiriTextTheme().copyWith(
          bodyLarge: GoogleFonts.amiri(color: Colors.white),
          bodyMedium: GoogleFonts.amiri(color: Colors.white70),
          titleLarge: GoogleFonts.amiri(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700), // ذهبي
            foregroundColor: const Color(0xFF2E7D32), // أخضر على الذهبي
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      home: const MusicPlayerHome(),
    );
  }
}

/// Some pleasant gradients that we cycle through for each track.  Picked
/// to loosely resemble the neon gradients used in the React demo, but
/// they also complement the green/gold Quranic theme.
final List<List<Color>> kGradients = [
  [const Color(0xFF667EEA), const Color(0xFF764BA2)],
  [const Color(0xFFFF0844), const Color(0xFFFFB199)],
  [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
  [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
  [const Color(0xFFFA709A), const Color(0xFFFEED40)],
  [const Color(0xFF30CFD0), const Color(0xFF330867)],
  [const Color(0xFFF6D365), const Color(0xFFFDA085)],
  [const Color(0xFF09203F), const Color(0xFF537895)],
];

class MusicPlayerHome extends StatefulWidget {
  const MusicPlayerHome({super.key});

  @override
  State<MusicPlayerHome> createState() => _MusicPlayerHomeState();
}

class _MusicPlayerHomeState extends State<MusicPlayerHome> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// playlist derived from the filesystem
  List<Track> _tracks = [];

  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isShuffled = false;
  LoopMode _loopMode = LoopMode.off;
  Duration _progress = Duration.zero;
  Duration _duration = Duration.zero;
  String? _selectedDirectory;
  bool _showNowPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
    _setupAudioPlayerListeners();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    _audioPlayer.currentIndexStream.listen((idx) {
      if (mounted && idx != null) {
        setState(() {
          _currentIndex = idx;
        });
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _progress = pos);
    });
    _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });

    _audioPlayer.shuffleModeEnabledStream.listen((enabled) {
      if (mounted) setState(() => _isShuffled = enabled);
    });
    _audioPlayer.loopModeStream.listen((mode) {
      if (mounted) setState(() => _loopMode = mode);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSavedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('selected_directory');
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        _selectedDirectory = savedPath;
      });
      await _loadFilesFromDirectory(savedPath);
    }
  }

  Future<void> _saveDirectory(String dirPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_directory', dirPath);
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
      if (await Permission.manageExternalStorage.isGranted == false) {
        await Permission.manageExternalStorage.request();
      }

      // Also request storage permission for older versions
      if (await Permission.storage.isGranted == false) {
        await Permission.storage.request();
      }

      // For Android 13+ (API 33+), request media permissions
      if (await Permission.audio.isGranted == false) {
        await Permission.audio.request();
      }
    }
  }

  Future<void> _pickFolder() async {
    await _requestPermissions();
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      _selectedDirectory = selectedDirectory;
      await _saveDirectory(selectedDirectory);
      await _loadFilesFromDirectory(selectedDirectory);
    }
  }

  Future<Duration?> _getDuration(String filePath) async {
    final tmp = AudioPlayer();
    try {
      await tmp.setFilePath(filePath);
      return tmp.duration;
    } catch (_) {
      return null;
    } finally {
      await tmp.dispose();
    }
  }

  Future<void> _loadFilesFromDirectory(String dirPath) async {
    Directory dir = Directory(dirPath);
    List<FileSystemEntity> entities = dir.listSync(
      recursive: true,
      followLinks: false,
    );
    List<File> audioFiles = [];

    for (var entity in entities) {
      if (entity is File) {
        String extension = path.extension(entity.path).toLowerCase();
        if ([
          '.mp3',
          '.wav',
          '.flac',
          '.aac',
          '.ogg',
          '.m4a',
        ].contains(extension)) {
          audioFiles.add(entity);
        }
      }
    }

    audioFiles.sort(
      (a, b) => path.basename(a.path).compareTo(path.basename(b.path)),
    );

    final List<Track> tracks = [];
    for (var i = 0; i < audioFiles.length; i++) {
      final file = audioFiles[i];
      final dur = await _getDuration(file.path) ?? Duration.zero;
      final gradient = kGradients[i % kGradients.length];
      tracks.add(
        Track(
          id: path.basenameWithoutExtension(file.path),
          title: path.basenameWithoutExtension(file.path),
          duration: dur,
          gradientFrom: gradient[0],
          gradientTo: gradient[1],
          filePath: file.path,
        ),
      );
    }

    setState(() {
      _tracks = tracks;
      _currentIndex = -1;
      _isPlaying = false;
    });

    if (tracks.isNotEmpty) {
      final playlist = ConcatenatingAudioSource(
        children: tracks.map((t) => AudioSource.file(t.filePath)).toList(),
      );
      await _audioPlayer.setAudioSource(playlist);
    }
  }

  /// From a track object, move the player to that index and start
  /// playing.
  Future<void> _playTrack(Track track) async {
    final idx = _tracks.indexWhere((t) => t.id == track.id);
    if (idx == -1) return;
    await _audioPlayer.seek(Duration.zero, index: idx);
    await _audioPlayer.play();
    setState(() {
      _currentIndex = idx;
      _isPlaying = true;
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _next() {
    _audioPlayer.seekToNext();
  }

  void _prev() {
    // if we're more than 3 seconds in restart current track
    if (_progress > const Duration(seconds: 3)) {
      _audioPlayer.seek(Duration.zero);
    } else {
      _audioPlayer.seekToPrevious();
    }
  }

  void _seek(Duration d) {
    _audioPlayer.seek(d);
  }

  void _toggleRepeat() {
    final nextMode = _loopMode == LoopMode.off
        ? LoopMode.all
        : _loopMode == LoopMode.all
        ? LoopMode.one
        : LoopMode.off;
    _audioPlayer.setLoopMode(nextMode);
  }

  void _toggleShuffle() {
    final shouldShuffle = !_isShuffled;
    _audioPlayer.setShuffleModeEnabled(shouldShuffle);
    if (shouldShuffle) _audioPlayer.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = _currentIndex >= 0 && _currentIndex < _tracks.length
        ? _tracks[_currentIndex]
        : null;

    // Convert audio player's loop mode enum into UI repeat mode enum once
    final RepeatMode currentRepeatMode = _loopMode == LoopMode.one
        ? RepeatMode.one
        : _loopMode == LoopMode.all
        ? RepeatMode.all
        : RepeatMode.off;

    return Scaffold(
      body: Stack(
        children: [
          LibraryScreen(
            tracks: _tracks,
            currentTrack: currentTrack,
            isPlaying: _isPlaying,
            onTrackSelected: _playTrack,
            onOpenNowPlaying: () => setState(() {
              _showNowPlaying = true;
            }),
            onPickFolder: _pickFolder,
          ),
          // mini player with slide-in animation
          if (currentTrack != null)
            Positioned(
              key: const ValueKey('mini'),
              left: 0,
              right: 0,
              bottom: 16, // add extra space from bottom edge
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: !_showNowPlaying
                    ? SafeArea(
                        bottom: true,
                        child: MiniPlayer(
                          track: currentTrack,
                          isPlaying: _isPlaying,
                          progress: _progress,
                          duration: _duration,
                          onTogglePlay: _togglePlayPause,
                          onNext: _next,
                          onTap: () => setState(() {
                            _showNowPlaying = true;
                          }),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          // now-playing overlay appears from bottom and sticks near the bottom edge
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              // slide in/out from bottom
              final offset = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(position: offset, child: child);
            },
            child: _showNowPlaying && currentTrack != null
                ? Align(
                    key: const ValueKey('nowplaying'),
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      bottom: true,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SizedBox(
                          // keep most of the screen, but anchor from bottom
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: NowPlayingScreen(
                            track: currentTrack,
                            progress: _progress,
                            duration: _duration,
                            isPlaying: _isPlaying,
                            onClose: () => setState(() {
                              _showNowPlaying = false;
                            }),
                            onTogglePlay: _togglePlayPause,
                            onNext: _next,
                            onPrev: _prev,
                            repeatMode: currentRepeatMode,
                            toggleRepeat: _toggleRepeat,
                            isShuffled: _isShuffled,
                            toggleShuffle: _toggleShuffle,
                            onSeek: _seek,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
