import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'map_painter.dart';
import 'task_dialog.dart';
import 'bottom_bar.dart';
import 'top_bar.dart';
import 'world_map_screen.dart';
import 'under_construction.dart';
import 'dart:math' as math;

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
  static const _framesCount = 3;
  static const _pxPerFrame = 16.0; // co ile px scrola przeskakiwać klatkę
  SpriteFrames? _topSeq, _botSeq;
  int _frame = 0;
  double _lastOff = 0;


  static const double _vertStep     = 0.09;  // co ile "w dół" pojawia się kolejny punkt (9% wysokości)
  static const double _periodRelY   = 0.30;  // pełna fala co 30% wysokości
  static const double _amplitude    = 0.22;  // amplituda w osi X (22% szerokości)
  static const double _xCenter      = 0.5;   // środkowa linia sinusa (poziomo)
  static const double _xMargin      = 0.08;  // margines od krawędzi, by punkty nie wychodziły poza zwój
  static const double _phase        = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _topSeq = await loadFrames(context, 'assets/parchment/roll_{i}.png', _framesCount);
      _botSeq = await loadFrames(context, 'assets/parchment/roll_{i}.png', _framesCount);
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

    // 2) Wyznacz relY: rośnij w dół co _vertStep (bazując na ostatnim punkcie)
    final lastRelY = _dots.isEmpty ? (72 / parchmentSize.height) : _dots.map((d) => d.relY).reduce(math.max);
    final relY = (lastRelY + _vertStep).clamp(0.0, 0.98);

    // 3) RelX wg sinusa: x = x0 + A * sin(2π * y/okres + faza)
    //    Zadbaj, by nie wyjść poza marginesy: skuteczna amplituda <= 0.5 - _xMargin
    final ampMax = 0.5 - _xMargin;
    final A = math.min(_amplitude, ampMax);
    final relX = (_xCenter + A * math.sin(2 * math.pi * (relY / _periodRelY) + _phase))
        .clamp(_xMargin, 1 - _xMargin);
    // final relX = 0.3 + Random().nextDouble() * 0.4; // w przedziale 0.3–0.7
    // final lastRelY = _dots.isEmpty ? 0.1 : _dots.last.relY;
    // final relY = (lastRelY + 0.15).clamp(0.0, 0.1);


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
  @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: false,
    body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/wood_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      // ⬇️ SafeArea NIE obejmuje całego Stacka — tylko górną część z UI
      child: Stack(
        fit: StackFit.expand,
        children: [
          // --- Główna kolumna ekranu w SafeArea (bez dołu) ---
          SafeArea(
            bottom: false, // 👈 dół pozostawiamy dla overlayu
            child: Column(
              children: [
                const SizedBox(height: 6),
                TopBar(
                  icons: const [
                    'assets/icons/top_-05.png',
                    'assets/icons/top_-06.png',
                    'assets/icons/top_-07.png',
                    'assets/icons/top_-08.png',
                  ],
                  onTap: (i) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UnderConstructionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, cons) {
                      final parchmentHeight = cons.maxHeight * 1.9; // dłuuugi zwój
                      return Center(
                        child: Transform.translate(
                          offset: const Offset(0, -20),
                          child: SizedBox(
                            width: cons.maxWidth - 30,
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
                              scrollWidth: (cons.maxWidth - 54) * 0.96,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // --- Dolny pasek jako OVERLAY poza SafeArea ---
          BottomBarOverlay(
            bottomOffset: 24, // podnieś/opuść pasek względem dolnej krawędzi
            icons: [
              BottomIconSpec('assets/icons/bottom_scroll.png', () => _toast(context, 'Scroll')),
              BottomIconSpec('assets/icons/bottom_quill.png',  () => _toast(context, 'Quill')),
              BottomIconSpec('assets/icons/bottom_sun.png',    () => _toast(context, 'Sun')),
              BottomIconSpec('assets/icons/bottom_fire.png',   () => _toast(context, 'Fire')),
              BottomIconSpec('assets/icons/bottom_star.png',   () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorldMapScreen()),
                );
              }),
            ],
          ),
        ],
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
  final double scrollWidth;
  const _Parchment({required this.controller, required this.height, required this.frame, required this.top, required this.bottom, required this.dots, required this.onPlus, required this.onDotTap,  required this.scrollWidth});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;

      // 1) Wymiary klatek rolek (jeśli brak, przyjmij 0)
      final Size topSize   = top?.frameSize()    ?? const Size(0, 0);
      final Size bottomSize= bottom?.frameSize() ?? const Size(0, 0);

      const double topOffset    = 12;   // przesuń GÓRNĄ rolkę w DÓŁ o X px
      const double bottomOffset = 80;   // przesuń DOLNĄ rolkę w GÓRĘ o X px
      const double gap          = 0;   // odstęp między każdą rolką a pergaminem

      return Stack(
        children: [
          // ===  A) STAŁE ROLKI: NA GÓRZE I NA DOLE  ===
          if (top != null)
            Positioned(
              top: topOffset,
              left: (w - topSize.width) / 2,
              width: topSize.width,
              height: topSize.height,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SingleImagePainter(top!.frame(frame)),
                ),
              ),
            ),

          if (bottom != null)
            Positioned(
              bottom: bottomOffset,
              left: (w - bottomSize.width) / 2,
              width: bottomSize.width,
              height: bottomSize.height,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SingleImagePainter(bottom!.frame(frame)),
                ),
              ),
            ),

          // ===  B) SCROLL PERGAMINU MIĘDZY ROLKAMI  ===
          // wałki nie klipują; pergamin ma margines top/bottom równy wysokościom rolek + gap
          Positioned.fill(
            top: topOffset + topSize.height + gap,
            bottom: bottomOffset + bottomSize.height + gap,
            child: SingleChildScrollView(
              controller: controller,
              physics: const BouncingScrollPhysics(),
              child: LayoutBuilder(builder: (context, inner) {
                final ww = inner.maxWidth;
                final hh = height; // całkowita wysokość zawartości pergaminu

                return Stack(
                  children: [
                    // TŁO pergaminu — powtarzany tile w pionie
                    Align(
                      alignment: Alignment.topCenter,
                      child:SizedBox(
                        width: scrollWidth,
                        height: hh,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/parchment/parchment_tile.png'),
                              repeat: ImageRepeat.repeatY,
                              alignment: Alignment.topCenter,
                              //fit: BoxFit.fill, // lub usuń fit, jeśli tile ma idealną szerokość
                            ),
                          ),
                        ),
                      ),
                    ),
                    // MAPA: przerywana linia + kropki
                    SizedBox(
                      width: ww,
                      height: hh,
                      child: _MapLayer(
                        dots: dots,
                        anchorRelX: 0.5, 
                        anchorRelY: (12 + 56/2) / hh,
                        onDotTap: onDotTap,
                      ),
                    ),

                    // Przyciski/banery na pergaminie (np. „START” itd.)
                    // + przycisk „+” przy górnej krawędzi obszaru pergaminu
                    Positioned(
                      top: 12,
                      left: (ww - 56) / 2,
                      child: GestureDetector(
                        onTap: () => onPlus(Size(ww, hh)),
                        child: Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.08),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset('assets/icons/add_task_icon.png', width: 28, height: 28),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      );
    });
  }
}

// Pomocniczy painter do narysowania jednej klatki (np. dolnej rolki)
class _SingleImagePainter extends CustomPainter {
  final ui.Image img;
  _SingleImagePainter(this.img);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Offset.zero & Size(img.width.toDouble(), img.height.toDouble());
    final dst = Offset.zero & size;
    canvas.drawImageRect(img, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _SingleImagePainter old) => old.img != img;
}

class _RollsPainterSeq extends CustomPainter {
  final SpriteFrames top;
  final SpriteFrames bottom;
  final int frame;
  final bool debug;
  _RollsPainterSeq({required this.top, required this.bottom, required this.frame, this.debug=false});

  @override
  void paint(Canvas canvas, Size size) {
    final topImg = top.frame(frame);
    final botImg = bottom.frame(frame);
    final topSize = top.frameSize();
    final botSize = bottom.frameSize();

    final topDst = Rect.fromLTWH((size.width - topSize.width) / 2, 0, topSize.width, topSize.height);
    final botDst = Rect.fromLTWH((size.width - botSize.width) / 2, size.height - botSize.height, botSize.width, botSize.height);
    
    if (debug) {
      final dbg = Paint()..color = const Color(0x8800FF00);
      canvas.drawRect(topDst, dbg);
      canvas.drawRect(botDst, dbg);
    }
    canvas.drawImageRect(topImg, Offset.zero & Size(topImg.width.toDouble(), topImg.height.toDouble()), topDst, Paint());
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
              child: Image.asset(
                _assetForDifficulty(d.task.difficulty), // 👈 wybór odpowiedniego PNG
                width: 36,
                height: 36,
              ),
            ),
          );
        }),
      ]);
    });
  }
}

// class _TopBar extends StatelessWidget {
//   final List<String> icons;           // np. ['assets/icons/top_1.png', ...]
//   final void Function(int) onTap;     // callback
//   const _TopBar({required this.icons, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,   // 👈 równe rozmieszczenie
//         children: List.generate(icons.length, (i) {
//           return GestureDetector(
//             onTap: () => onTap(i),
//             behavior: HitTestBehavior.opaque,
//             child: SizedBox(                          // „hit area”, ale bez tła
//               width: 80,                              // dopasuj do swoich PNG
//               height: 80,
//               child: Center(
//                 child: Image.asset(
//                   icons[i],
//                   width: 118,                          // rozmiar samej ikony
//                   height: 117,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }


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

String _assetForDifficulty(Difficulty diff) {
  switch (diff) {
    case Difficulty.easy:
      return 'assets/icons/dot_easy.png';
    case Difficulty.medium:
      return 'assets/icons/dot_medium.png';
    case Difficulty.hard:
      return 'assets/icons/dot_hard.png';
  }
}

// class _BottomIconButton extends StatelessWidget {
//   final String asset;
//   final VoidCallback onTap;

//   const _BottomIconButton(this.asset, this.onTap);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: SizedBox(
//         width: 56,
//         height: 56,
//         child: Image.asset(asset, fit: BoxFit.contain),
//       ),
//     );
//   }
// }
