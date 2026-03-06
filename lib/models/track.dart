import 'package:flutter/material.dart';

/// Simple model for a single audio item in the playlist.  The
/// fields mirror the React example, but we add a [filePath] so that
/// we can load the file from disk.
class Track {
  final String id;
  final String title;
  final Duration duration;
  final Color gradientFrom;
  final Color gradientTo;
  final String filePath;

  Track({
    required this.id,
    required this.title,
    required this.duration,
    required this.gradientFrom,
    required this.gradientTo,
    required this.filePath,
  });
}
