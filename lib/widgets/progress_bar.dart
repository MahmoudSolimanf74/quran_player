import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final Duration progress;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const ProgressBar({
    Key? key,
    required this.progress,
    required this.duration,
    required this.onSeek,
  }) : super(key: key);

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  bool _dragging = false;
  bool _hovering = false;
  double _localPercent = 0;

  @override
  void didUpdateWidget(covariant ProgressBar old) {
    super.didUpdateWidget(old);
    if (!_dragging) {
      _localPercent = _calcPercent(widget.progress);
    }
  }

  double _calcPercent(Duration d) {
    if (widget.duration.inMilliseconds == 0) return 0;
    return d.inMilliseconds / widget.duration.inMilliseconds;
  }

  void _seekFromPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPosition);
    final pct = local.dx.clamp(0.0, box.size.width) / box.size.width;
    final newDuration = widget.duration * pct;
    setState(() {
      _localPercent = pct;
    });
    widget.onSeek(newDuration);
  }

  @override
  Widget build(BuildContext context) {
    final thumbVisible = _dragging || _hovering;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (details) {
          setState(() {
            _dragging = true;
          });
          _seekFromPosition(details.globalPosition);
        },
        onHorizontalDragUpdate: (details) {
          _seekFromPosition(details.globalPosition);
        },
        onHorizontalDragEnd: (details) {
          setState(() {
            _dragging = false;
          });
        },
        child: Column(
          children: [
            SizedBox(
              height: 20,
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _localPercent,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (thumbVisible)
                    Positioned(
                      left:
                          (_localPercent * MediaQuery.of(context).size.width) -
                          6,
                      top: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _format(widget.progress),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _format(widget.duration),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
