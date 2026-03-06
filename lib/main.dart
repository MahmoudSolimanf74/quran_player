import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مشغل القرآن الكريم',
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32), // أخضر داكن
        scaffoldBackgroundColor: const Color(0xFFF1F8E9), // أخضر فاتح
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32), // أخضر داكن
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: GoogleFonts.amiriTextTheme().copyWith(
          bodyLarge: GoogleFonts.amiri(
            color: const Color(0xFF1B5E20),
          ), // أخضر أغمق
          bodyMedium: GoogleFonts.amiri(color: const Color(0xFF2E7D32)),
          titleLarge: GoogleFonts.amiri(
            color: const Color(0xFF1B5E20),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700), // ذهبي
            foregroundColor: const Color(0xFF2E7D32), // أخضر على الذهبي
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
      ),
      home: const MusicPlayerHome(),
    );
  }
}

class MusicPlayerHome extends StatefulWidget {
  const MusicPlayerHome({super.key});

  @override
  State<MusicPlayerHome> createState() => _MusicPlayerHomeState();
}

class _MusicPlayerHomeState extends State<MusicPlayerHome> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<File> _audioFiles = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  String? _selectedDirectory;

  @override
  void initState() {
    super.initState();
    _loadSavedDirectory();
    _setupAudioPlayerListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          _isPlaying = playerState.playing;
        });
      }
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (mounted && index != null) {
        setState(() {
          _currentIndex = index;
        });
      }
    });
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

    // Sort files alphabetically for consistent order
    audioFiles.sort(
      (a, b) => path.basename(a.path).compareTo(path.basename(b.path)),
    );

    setState(() {
      _audioFiles = audioFiles;
      _currentIndex = -1;
      _isPlaying = false;
    });

    // Create playlist
    if (audioFiles.isNotEmpty) {
      final playlist = ConcatenatingAudioSource(
        children: audioFiles
            .map((file) => AudioSource.file(file.path))
            .toList(),
      );
      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
    }
  }

  Future<void> _playAudio(int index) async {
    if (index >= 0 && index < _audioFiles.length) {
      await _audioPlayer.seek(Duration.zero, index: index);
      await _audioPlayer.play();
      setState(() {
        _currentIndex = index;
        _isPlaying = true;
      });
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _resumeAudio() async {
    await _audioPlayer.play();
    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _nextAudio() async {
    if (_currentIndex < _audioFiles.length - 1) {
      await _audioPlayer.seekToNext();
    }
  }

  Future<void> _previousAudio() async {
    if (_currentIndex > 0) {
      await _audioPlayer.seekToPrevious();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مشغل القرآن الكريم'),
        leading: const Icon(Icons.mosque, color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _pickFolder,
            tooltip: 'اختر مجلد',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_audioFiles.isNotEmpty && _currentIndex >= 0)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'الآن يتم تشغيل: ${path.basename(_audioFiles[_currentIndex].path)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _audioFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mosque,
                          size: 80,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'لم يتم العثور على ملفات صوتية. اختر مجلد يحتوي على ملفات القرآن.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _audioFiles.length,
                    itemBuilder: (context, index) {
                      String fileName = path.basename(_audioFiles[index].path);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(
                            Icons.audiotrack,
                            color: Color(0xFF2E7D32),
                          ),
                          title: Text(
                            fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          subtitle: Text(
                            'سورة ${index + 1}',
                            style: const TextStyle(color: Color(0xFF388E3C)),
                          ),
                          onTap: () => _playAudio(index),
                          selected: index == _currentIndex,
                          selectedTileColor: const Color(0xFFE8F5E8),
                        ),
                      );
                    },
                  ),
          ),
          if (_audioFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Progress indicator
                  StreamBuilder<Duration?>(
                    stream: _audioPlayer.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration?>(
                        stream: _audioPlayer.durationStream,
                        builder: (context, durationSnapshot) {
                          final duration =
                              durationSnapshot.data ?? Duration.zero;
                          return Column(
                            children: [
                              Slider(
                                value: duration.inSeconds > 0
                                    ? position.inSeconds.toDouble()
                                    : 0.0,
                                max: duration.inSeconds.toDouble(),
                                onChanged: duration.inSeconds > 0
                                    ? (value) {
                                        _audioPlayer.seek(
                                          Duration(seconds: value.toInt()),
                                        );
                                      }
                                    : null,
                                activeColor: const Color(0xFFFFD700),
                                inactiveColor: Colors.white.withOpacity(0.3),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                        ),
                        onPressed: _previousAudio,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: const Color(0xFF2E7D32),
                          ),
                          onPressed: _isPlaying ? _pauseAudio : _resumeAudio,
                          iconSize: 40,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: _nextAudio,
                        iconSize: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
