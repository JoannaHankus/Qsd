// =============================
// lib/main.dart
// =============================
import 'package:flutter/material.dart';
import 'src/ui/map_screen.dart';
/*
void main() => runApp(const QuesdoMapApp());

class QuesdoMapApp extends StatelessWidget {
  const QuesdoMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parchment Map',
      theme: ThemeData(useMaterial3: true),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}*/

// =============================
// lib/src/ui/map_screen.dart
// =============================
import 'package:flutter/material.dart';
import 'map_painter.dart';

/// Ekran ze zwojem (scrollowalnym), kropkami jako przyciskami,
/// przyciskiem "+" do dodawania nowych punktów oraz górnym i dolnym paskiem.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ScrollController _scroll = ScrollController();
  bool _addingMode = false; // po wciśnięciu "+" czekamy na dotknięcie zwoju

  // Współrzędne punktów w układzie procentowym (0..1) względem rozmiaru zwoju
  final List<_MapDot> _dots = [
    const _MapDot(relX: .22, relY: .18, color: Color(0xFF67D4C3)),
    const _MapDot(relX: .62, relY: .22, color: Color(0xFF57C1E8)),
    const _MapDot(relX: .32, relY: .38, color: Color(0xFF67D4C3)),
    const _MapDot(relX: .45, relY: .56, color: Color(0xFFF3B546)),
    const _MapDot(relX: .78, relY: .78, color: Color(0xFFF3923E)),
  ];

  void _scrollToBottom() {
    final target = _scroll.position.maxScrollExtent;
    _scroll.animateTo(target, duration: const Duration(milliseconds: 700), curve: Curves.easeInOut);
  }

  void _enterAddMode() {
    setState(() => _addingMode = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wskaż miejsce na zwoju, aby dodać kropkę')), // krótkie info
    );
  }

  void _addDotAt(Offset localPos, Size parchmentSize) async {
    final relX = (localPos.dx / parchmentSize.width).clamp(0.0, 1.0);
    final relY = (localPos.dy / parchmentSize.height).clamp(0.0, 1.0);

    // Otwórz popup formularza zadania
    final task = await showDialog<_Task>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TaskDialog(),
    );

    setState(() {
      _addingMode = false;
      if (task != null) {
        // Kolor wg trudności
        final color = switch (task.difficulty) {
          Difficulty.easy => const Color(0xFF67D4C3),
          Difficulty.medium => const Color(0xFFF3B546),
          Difficulty.hard => const Color(0xFFF3923E),
        };
        _dots.add(_MapDot(relX: relX, relY: relY, color: color, task: task));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wood = const Color(0xFF6E462A);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [wood.withOpacity(.95), wood],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(onTap: (i) => _showSnack(context, 'Top icon #$i')),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final parchmentHeight = constraints.maxHeight * 1.8;
                    return Stack(
                      children: [
                        // Zwój w SingleChildScrollView
                        SingleChildScrollView(
                          controller: _scroll,
                          physics: const BouncingScrollPhysics(),
                          child: Center(
                            child: _Parchment(
                              width: constraints.maxWidth - 24,
                              height: parchmentHeight,
                              dots: _dots,
                              addingMode: _addingMode,
                              onTapInside: (pos, size) => _addDotAt(pos, size),
                            ),
                          ),
                        ),

                        // Strzałka przewijająca na sam dół
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _RoundIconButton(
                            icon: Icons.arrow_downward_rounded,
                            onTap: _scrollToBottom,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              _BottomBar(onTap: (i) => _showSnack(context, 'Bottom icon #$i')),
            ],
          ),
        ),
      ),
      // Pływający przycisk "+" (widoczny jak na zrzucie), dodaje nową kropkę po wskazaniu miejsca
      floatingActionButton: _RoundIconButton(icon: Icons.add, onTap: _enterAddMode),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 800)),
    );
  }
}

class _Parchment extends StatelessWidget {
  final double width;
  final double height;
  final List<_MapDot> dots;
  final bool addingMode;
  final void Function(Offset localPosition, Size size) onTapInside;
  const _Parchment({required this.width, required this.height, required this.dots, required this.addingMode, required this.onTapInside});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF2E2C4),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final points = dots.map((d) => Offset(d.relX * w, d.relY * h)).toList(growable: false);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: addingMode
                ? (d) => onTapInside(d.localPosition, Size(w, h))
                : null,
            child: Stack(
              children: [
                CustomPaint(painter: ParchmentMapPainter(points: points), size: Size.infinite),
                ...dots.map((d) {
                  final pos = Offset(d.relX * w, d.relY * h);
                  return Positioned(
                    left: pos.dx - 18,
                    top: pos.dy - 18,
                    child: _DotButton(
                  color: d.color,
                  onTap: () async {
                    final edited = await showDialog<_Task>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => _TaskDialog(initial: d.task),
                    );
                    if (edited != null) {
                      final idx = dots.indexOf(d);
                      final newColor = switch (edited.difficulty) {
                        Difficulty.easy => const Color(0xFF67D4C3),
                        Difficulty.medium => const Color(0xFFF3B546),
                        Difficulty.hard => const Color(0xFFF3923E),
                      };
                      dots[idx] = _MapDot(relX: d.relX, relY: d.relY, color: newColor, task: edited);
                      (context as Element).markNeedsBuild();
                    }
                  }),
                  );
                }),
                if (addingMode)
                  // Wskazówka trybu dodawania
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(.6), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Tapnij na zwoju, aby dodać', style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DotButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _DotButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 2))],
          border: Border.all(color: Colors.black26, width: 1),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF3F2A1A),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(height: 56, width: 56, child: Icon(icon, color: Colors.white)),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final void Function(int index) onTap;
  const _TopBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _TopBadge(icon: Icons.military_tech, label: '960', onTap: () => onTap(0)),
          const SizedBox(width: 8),
          _TopBadge(icon: Icons.emoji_events, label: '12', onTap: () => onTap(1)),
          const Spacer(),
          _SquareIcon(icon: Icons.settings, onTap: () => onTap(2)),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TopBadge({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEED9B6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.brown.shade400),
        ),
        child: Row(children: [Icon(icon, size: 18, color: Colors.brown.shade700), const SizedBox(width: 6), Text(label)]),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final void Function(int index) onTap;
  const _BottomBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF3F2A1A), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 8)]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SquareIcon(icon: Icons.map, onTap: () => onTap(0)),
          _SquareIcon(icon: Icons.brush, onTap: () => onTap(1)),
          _SquareIcon(icon: Icons.wb_sunny_outlined, onTap: () => onTap(2)),
          _SquareIcon(icon: Icons.local_fire_department, onTap: () => onTap(3)),
          _SquareIcon(icon: Icons.auto_awesome, onTap: () => onTap(4)),
        ],
      ),
    );
  }
}

class _SquareIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SquareIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEED9B6),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFF4E342E)),
        ),
      ),
    );
  }
}

enum Difficulty { easy, medium, hard }

class _MapDot {
  final double relX; // 0..1
  final double relY; // 0..1
  final Color color;
  final _Task task;
  const _MapDot({required this.relX, required this.relY, required this.color, required this.task});
}

class _Task {
  final String title;
  final DateTime? date; // Data trwania (pojedynczy dzień dla uproszczenia)
  final DateTime? reminder; // data+czas
  final String? note;
  final Difficulty difficulty;
  const _Task({
    required this.title,
    this.date,
    this.reminder,
    this.note,
    this.difficulty = Difficulty.easy,
  });

  _Task copyWith({String? title, DateTime? date, DateTime? reminder, String? note, Difficulty? difficulty}) => _Task(
    title: title ?? this.title,
    date: date ?? this.date,
    reminder: reminder ?? this.reminder,
    note: note ?? this.note,
    difficulty: difficulty ?? this.difficulty,
  );
}

// =============================
// lib/src/ui/task_dialog.dart
// =============================
import 'package:flutter/material.dart';

class _TaskDialog extends StatefulWidget {
  final _Task? initial;
  const _TaskDialog({this.initial});

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late TextEditingController _title;
  late TextEditingController _note;
  DateTime? _date;
  DateTime? _reminderDate;
  TimeOfDay? _reminderTime;
  Difficulty _difficulty = Difficulty.easy;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _note = TextEditingController(text: widget.initial?.note ?? '');
    _date = widget.initial?.date;
    _reminderDate = widget.initial?.reminder;
    _reminderTime = widget.initial?.reminder != null
        ? TimeOfDay(hour: widget.initial!.reminder!.hour, minute: widget.initial!.reminder!.minute)
        : null;
    _difficulty = widget.initial?.difficulty ?? Difficulty.easy;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickReminderDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _reminderDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  void _accept() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Podaj nazwę zadania')));
      return;
    }
    DateTime? reminder;
    if (_reminderDate != null && _reminderTime != null) {
      reminder = DateTime(
        _reminderDate!.year,
        _reminderDate!.month,
        _reminderDate!.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );
    }
    Navigator.of(context).pop(_Task(
      title: _title.text.trim(),
      date: _date,
      reminder: reminder,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      difficulty: _difficulty,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final parchment = const Color(0xFFF2E2C4);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: parchment,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, size: 18),
                const SizedBox(width: 8),
                const Text('Add a Task'),
                const Spacer(),
                TextButton(onPressed: _accept, child: const Text('Accept')),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                hintText: 'Task name',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.brightness_5_outlined, size: 18),
              const SizedBox(width: 8),
              const Text('Date'),
              const Spacer(),
              TextButton(
                onPressed: _pickDate,
                child: Text(_date == null ? 'Pick date' : _fmtDate(_date!)),
              ),
            ]),
            Row(children: [
              const Icon(Icons.alarm, size: 18),
              const SizedBox(width: 8),
              const Text('Reminder'),
              const Spacer(),
              TextButton(
                onPressed: _pickReminderDate,
                child: Text(_reminderDate == null ? 'Pick date' : _fmtDate(_reminderDate!)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _pickReminderTime,
                child: Text(_reminderTime == null ? 'Time' : _fmtTime(_reminderTime!)),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('Notes'),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(border: UnderlineInputBorder(), hintText: 'Optional note'),
            ),
            const SizedBox(height: 12),
            const Text('Difficulty'),
            const SizedBox(height: 6),
            ToggleButtons(
              isSelected: [
                _difficulty == Difficulty.easy,
                _difficulty == Difficulty.medium,
                _difficulty == Difficulty.hard,
              ],
              onPressed: (i) => setState(() => _difficulty = Difficulty.values[i]),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Easy')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Medium')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Hard')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

// =============================
// lib/src/ui/map_painter.dart
// =============================
import 'dart:ui';
import 'package:flutter/material.dart';

/// Malarz rysujący przerywaną ścieżkę i symbol ogniska na środku.
class ParchmentMapPainter extends CustomPainter {
  final List<Offset> points;
  ParchmentMapPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // Cień przy krawędziach zwoju (lekki efekt rulonu)
    final edgePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.black12, Colors.transparent, Colors.transparent, Colors.black12],
        stops: const [0, .06, .94, 1],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, edgePaint);

    if (points.length < 2) return;

    final path = _smoothPath(points);

    // Rysuj przerywaną linię
    final dashed = _dashPath(path, dashLength: 14, gapLength: 10);
    final pathPaint = Paint()
      ..color = const Color(0xFF6B4A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dashed, pathPaint);

    // Prosty piktogram ogniska przy środkowym punkcie (placeholder)
    final middle = points[(points.length / 2).floor()];
    _drawCampfire(canvas, middle);
  }

  @override
  bool shouldRepaint(covariant ParchmentMapPainter oldDelegate) => oldDelegate.points != points;

  // --- helpers ---
  Path _smoothPath(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i];
      final p1 = pts[i + 1];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      p.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    p.lineTo(pts.last.dx, pts.last.dy);
    return p;
  }

  Path _dashPath(Path source, {double dashLength = 10, double gapLength = 6}) {
    final Path dest = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0.0;
      while (dist < metric.length) {
        final double len = (dist + dashLength).clamp(0.0, metric.length);
        dest.addPath(metric.extractPath(dist, len), Offset.zero);
        dist = len + gapLength;
      }
    }
    return dest;
  }

  void _drawCampfire(Canvas canvas, Offset c) {
    // drewienka
    final woodPaint = Paint()..color = const Color(0xFF8D5A3A);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(.25);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: 44, height: 8), const Radius.circular(4)), woodPaint);
    canvas.rotate(-.5);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: 44, height: 8), const Radius.circular(4)), woodPaint);
    canvas.restore();

    // płomień (dwie łezki)
    final flame = Path()
      ..moveTo(c.dx, c.dy - 30)
      ..cubicTo(c.dx + 14, c.dy - 10, c.dx + 10, c.dy, c.dx, c.dy)
      ..cubicTo(c.dx - 10, c.dy, c.dx - 14, c.dy - 10, c.dx, c.dy - 30)
      ..close();
    final flamePaint = Paint()..color = const Color(0xFFF9A825);
    canvas.drawPath(flame, flamePaint);
    canvas.drawPath(flame.shift(const Offset(0, 8)).transform(Matrix4.diagonal3Values(.7, .7, 1).storage), Paint()..color = const Color(0xFFFFD54F));
  }
}
