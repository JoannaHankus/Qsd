import 'dart:ui';
import 'package:flutter/material.dart';

/// Przerywana ścieżka łącząca punkty na zwoju + proste ognisko
class ParchmentMapPainter extends CustomPainter {
  final List<Offset> points;
  ParchmentMapPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // delikatne cieniowanie krawędzi
    final edgePaint = Paint()
      ..shader = LinearGradient(colors: [Colors.black12, Colors.transparent, Colors.transparent, Colors.black12], stops: const [0, .06, .94, 1], begin: Alignment.centerLeft, end: Alignment.centerRight).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, edgePaint);

    if (points.length < 2) return;

    final path = _smoothPath(points);
    final dashed = _dashPath(path, dashLength: 14, gapLength: 10);
    final paintStroke = Paint()
      ..color = const Color(0xFF6B4A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dashed, paintStroke);

    // ognisko w ~1/2 trasy (dla efektu)
    final mid = points[(points.length / 2).floor()];
    _drawCampfire(canvas, mid);
  }

  @override
  bool shouldRepaint(covariant ParchmentMapPainter old) => old.points != points;

  Path _smoothPath(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      p.quadraticBezierTo(a.dx, a.dy, mid.dx, mid.dy);
    }
    p.lineTo(pts.last.dx, pts.last.dy);
    return p;
  }

  Path _dashPath(Path src, {double dashLength = 10, double gapLength = 6}) {
    final out = Path();
    for (final m in src.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final next = (d + dashLength).clamp(0.0, m.length);
        out.addPath(m.extractPath(d, next), Offset.zero);
        d = next + gapLength;
      }
    }
    return out;
  }

  void _drawCampfire(Canvas c, Offset o) {
    final wood = Paint()..color = const Color(0xFF8D5A3A);
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(.25);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: 44, height: 8), const Radius.circular(4)), wood);
    c.rotate(-.5);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: 44, height: 8), const Radius.circular(4)), wood);
    c.restore();

    final flame = Path()
      ..moveTo(o.dx, o.dy - 30)
      ..cubicTo(o.dx + 14, o.dy - 10, o.dx + 10, o.dy, o.dx, o.dy)
      ..cubicTo(o.dx - 10, o.dy, o.dx - 14, o.dy - 10, o.dx, o.dy - 30)
      ..close();
    c.drawPath(flame, Paint()..color = const Color(0xFFF9A825));
    c.drawPath(flame.shift(const Offset(0, 8)).transform(Matrix4.diagonal3Values(.7, .7, 1).storage), Paint()..color = const Color(0xFFFFD54F));
  }
}
