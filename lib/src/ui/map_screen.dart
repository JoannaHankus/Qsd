import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'map_painter.dart';
import 'task_dialog.dart';
import 'dart:math';

// Helper do ładowania sekwencji klatek (osobne pliki PNG)
class SpriteFrames {
  final List<ui.Image> images;
  SpriteFrames(this.images);
  int get length => images.length;
  ui.Image frame(int i) => images[i % length];
  Size frameSize() => Size(images.first.width.toDouble(), images.first.height.toDouble());
}

Future<SpriteFrames> loadFrames(BuildContext ctx, String pattern, int frames) async {
  final images = <ui.Image>[];
  for (int i = 0; i < frames; i++) {
    final path = pattern.replaceAll('{i}', '$i');
    final data = await DefaultAssetBundle.of(ctx).load(path);
    final img = await decodeImageFromList(data.buffer.asUint8List());
    images.add(img);
  }
  return SpriteFrames(images);
}

/// Ekran ze zwojem (scrollowalnym) + top bar z 4 przyciskami + przycisk dodawania zadań
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ScrollController _scroll = ScrollController();
  bool _addingMode = false;

  // Zbiór punktów-zadań na mapie (0..1 współrzędne względem rozmiaru zwoju)
  final List<_MapDot> _dots = [];

  // Sprites rolek
  static const _framesCount = 8;
  static const _pxPerFrame = 16.0; // co ile px scrola przeskakiwać klatkę
  SpriteFrames? _topSeq, _botSeq;
  int _frame = 0;
  double _lastOff = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _topSeq = await loadFrames(context, 'assets/parchment/roll_top_{i}.png', _framesCount);
      _botSeq = await loadFrames(context, 'assets/parchment/roll_bottom_{i}.png', _framesCount);
      if (mounted) setState(() {});
    });
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final off = _scroll.offset;
    final delta = (off - _lastOff).abs();
    if (delta >= _pxPerFrame) {
      final steps = (delta ~/ _pxPerFrame);
      setState(() => _frame = (_frame + steps) % _framesCount);
      _lastOff = off;
    }
  }

  Future<void> _onPlusTap(Size parchmentSize) async {
    setState(() => _addingMode = true);
    final task = await showDialog<TaskData>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const TaskDialog(),
    );
    setState(() => _addingMode = false);
    if (task == null) return;

    final relX = 0.3 + Random().nextDouble() * 0.4; // w przedziale 0.3–0.7
    final lastRelY = _dots.isEmpty ? 0.1 : _dots.last.relY;
    final relY = (lastRelY + 0.15).clamp(0.0, 1.0);


    final color = switch (task.difficulty) {
      Difficulty.easy => const Color(0xFF67D4C3),
      Difficulty.medium => const Color(0xFFF3B546),
      Difficulty.hard => const Color(0xFFF3923E),
    };
    setState(() {
      _dots.add(_MapDot(relX: relX, relY: relY, color: color, task: task));
    });
  }

  void _editDot(int index) async {
  final dot = _dots[index];
  final edited = await showDialog<TaskData>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TaskDialog(initial: dot.task), // <- wstępnie wypełniony formularz
  );
  if (edited == null) return;

  // kolor wg trudności
  final color = switch (edited.difficulty) {
    Difficulty.easy   => const Color(0xFF67D4C3),
    Difficulty.medium => const Color(0xFFF3B546),
    Difficulty.hard   => const Color(0xFFF3923E),
  };

  setState(() {
    _dots[index] = _MapDot(
      relX: dot.relX,
      relY: dot.relY,
      color: color,
      task: edited,
    );
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wood_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 6),
              _TopBar(
                icons: const [
                  'assets/icons/top_1.png',
                  'assets/icons/top_2.png',
                  'assets/icons/top_3.png',
                  'assets/icons/top_4.png',
                ],
                onTap: (i) => _toast(context, 'Top btn #$i'),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, cons) {
                    final parchmentHeight = cons.maxHeight * 1.9; // dłuuugi zwój
                    return Center(
                      child: SizedBox(
                        width: cons.maxWidth - 24,
                        height: parchmentHeight,
                        child: _Parchment(
                          controller: _scroll,
                          height: parchmentHeight,
                          frame: _frame,
                          top: _topSeq,
                          bottom: _botSeq,
                          dots: _dots,
                          onPlus: _onPlusTap,
                          onDotTap: _editDot,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 800)));
  }
}

class _Parchment extends StatelessWidget {
  final ScrollController controller;
  final double height;
  final int frame;
  final SpriteFrames? top;
  final SpriteFrames? bottom;
  final List<_MapDot> dots;
  final Future<void> Function(Size parchmentSize) onPlus;
  final void Function(int index) onDotTap;
  const _Parchment({required this.controller, required this.height, required this.frame, required this.top, required this.bottom, required this.dots, required this.onPlus, required this.onDotTap,});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // SCROLL
        SingleChildScrollView(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final h = height; // całkowita wysokość zwoju
            const double kPlusTop = 12;   // jak w Positioned(top: 12)
            const double kPlusSize = 56;  // jak w Container(width/height: 56)
            final double anchorRelX = 0.5;
            final double anchorRelY = (kPlusTop + kPlusSize / 2) / h;

            return Stack(
              children: [
                // TŁO PERGAMINU (powtarzany tile w pionie)
                SizedBox(
                  width: w,
                  height: h,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/parchment/parchment_tile.png'),
                        repeat: ImageRepeat.repeatY,
                        alignment: Alignment.topCenter,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // WARSTWA: ścieżka + kropki (mapa)
                SizedBox(
                  width: w,
                  height: h,
                  child: _MapLayer(dots: dots,
                  anchorRelX: anchorRelX,
                  anchorRelY: anchorRelY,
                  onDotTap: onDotTap,),
                ),

                // PRZYCISK "+" w górnej części zwoju
                Positioned(
                  top: 12,
                  left: (w - 56) / 2,
                  child: GestureDetector(
                    onTap: () => onPlus(Size(w, h)),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.08)),
                      alignment: Alignment.center,
                      child: Image.asset('assets/icons/add_task_icon.png', width: 28, height: 28),
                    ),
                  ),
                ),

                // ANIMOWANE ROLKI (góra/dół) – warstwa na wierzchu
                if (top != null && bottom != null)
                  Positioned.fill(
                    child: CustomPaint(painter: _RollsPainterSeq(top: top!, bottom: bottom!, frame: frame)),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _RollsPainterSeq extends CustomPainter {
  final SpriteFrames top;
  final SpriteFrames bottom;
  final int frame;
  _RollsPainterSeq({required this.top, required this.bottom, required this.frame});

  @override
  void paint(Canvas canvas, Size size) {
    final topImg = top.frame(frame);
    final botImg = bottom.frame(frame);
    final topSize = top.frameSize();
    final botSize = bottom.frameSize();

    final topDst = Rect.fromLTWH((size.width - topSize.width) / 2, 0, topSize.width, topSize.height);
    canvas.drawImageRect(topImg, Offset.zero & Size(topImg.width.toDouble(), topImg.height.toDouble()), topDst, Paint());

    final botDst = Rect.fromLTWH((size.width - botSize.width) / 2, size.height - botSize.height, botSize.width, botSize.height);
    canvas.drawImageRect(botImg, Offset.zero & Size(botImg.width.toDouble(), botImg.height.toDouble()), botDst, Paint());
  }

  @override
  bool shouldRepaint(covariant _RollsPainterSeq old) => old.frame != frame || old.top.length != top.length || old.bottom.length != bottom.length;
}

class _MapLayer extends StatelessWidget {
  final List<_MapDot> dots;
  final void Function(int index) onDotTap;
  final double anchorRelX; // 0..1
  final double anchorRelY;
  const _MapLayer({required this.dots,
    required this.anchorRelX,
    required this.anchorRelY,
    required this.onDotTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final anchor = Offset(anchorRelX * w, anchorRelY * h);
      final orderedDots = List<_MapDot>.from(dots);
      final points = <Offset>[
        anchor,
        ...orderedDots.map((d) => Offset(d.relX * w, d.relY * h)),
      ];
      //final points = dots.map((d) => Offset(d.relX * w, d.relY * h)).toList();
      return Stack(children: [
        CustomPaint(size: Size.infinite, painter: ParchmentMapPainter(points: points)),
        ...orderedDots.asMap().entries.map((entry) {
          final i = entry.key;   // index
          final d = entry.value; // dot
          final pos = Offset(d.relX * w, d.relY * h);
          return Positioned(
            left: pos.dx - 18,
            top: pos.dy - 18,
            child: GestureDetector(
              onTap: () => onDotTap(i),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: d.color,
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 2))],
                  border: Border.all(color: Colors.black26, width: 1),
                ),
              ),
            ),
          );
        }),
      ]);
    });
  }
}

class _TopBar extends StatelessWidget {
  final List<String> icons;
  final void Function(int) onTap;
  const _TopBar({required this.icons, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++) ...[
            GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEED9B6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7A5A3A)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(icons[i], fit: BoxFit.contain),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// ====== MODELE ======
enum Difficulty { easy, medium, hard }

class TaskData {
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? reminder;
  final bool reminderEnabled;
  final double volume;
  final String? notes;
  final Difficulty difficulty;
  const TaskData({
    required this.title,
    this.startDate,
    this.endDate,
    this.reminder,
    this.reminderEnabled = false,
    this.volume = .5,
    this.notes,
    this.difficulty = Difficulty.easy,
  });
}

class _MapDot {
  final double relX; // 0..1
  final double relY; // 0..1
  final Color color;
  final TaskData task;
  const _MapDot({required this.relX, required this.relY, required this.color, required this.task});
}
