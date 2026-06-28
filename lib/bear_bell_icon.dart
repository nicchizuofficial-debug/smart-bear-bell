import 'dart:math';
import 'package:flutter/material.dart';

/// 熊耳付き・鳴動アニメーション付きベルアイコン
class BearBellIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool ringing; // trueのとき揺れ＋音波を表示

  const BearBellIcon({
    super.key,
    this.size = 40,
    this.color = const Color(0xFFFFD700),
    this.ringing = true,
  });

  @override
  State<BearBellIcon> createState() => _BearBellIconState();
}

class _BearBellIconState extends State<BearBellIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _swing;
  late Animation<double> _wave;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    // ベルの揺れ（±12°）
    _swing = Tween<double>(begin: -12 * pi / 180, end: 12 * pi / 180)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // 音波の広がり（0→1）
    _wave = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.ringing) {
      return CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _BearBellPainter(color: widget.color, swing: 0, wave: 0),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _BearBellPainter(
          color: widget.color,
          swing: _swing.value,
          wave: _wave.value,
        ),
      ),
    );
  }
}

class _BearBellPainter extends CustomPainter {
  final Color color;
  final double swing; // ラジアン
  final double wave;  // 0〜1

  const _BearBellPainter({
    required this.color,
    required this.swing,
    required this.wave,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color..style = PaintingStyle.fill;

    // ── 音波（ベル左右に円弧）──
    if (wave > 0) {
      final wavePaint = Paint()
        ..color = color.withValues(alpha: (1 - wave) * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round;

      // 左の音波
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.52),
            width: (w * 0.6 + w * 0.5 * wave), height: (h * 0.6 + h * 0.4 * wave)),
        pi * 0.65, pi * 0.35, false, wavePaint,
      );
      // 右の音波
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.52),
            width: (w * 0.6 + w * 0.5 * wave), height: (h * 0.6 + h * 0.4 * wave)),
        pi * 1.65, pi * 0.35, false, wavePaint,
      );

      // 外側の大きな音波
      final wavePaint2 = Paint()
        ..color = color.withValues(alpha: (1 - wave) * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.52),
            width: (w * 0.9 + w * 0.6 * wave), height: (h * 0.8 + h * 0.5 * wave)),
        pi * 0.60, pi * 0.45, false, wavePaint2,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w * 0.50, h * 0.52),
            width: (w * 0.9 + w * 0.6 * wave), height: (h * 0.8 + h * 0.5 * wave)),
        pi * 1.60, pi * 0.45, false, wavePaint2,
      );
    }

    // ── ベル本体を揺らす ──
    canvas.save();
    canvas.translate(w * 0.5, h * 0.10); // 頂点を中心に回転
    canvas.rotate(swing);
    canvas.translate(-w * 0.5, -h * 0.10);

    // 熊の耳（外）
    canvas.drawCircle(Offset(w * 0.20, h * 0.18), w * 0.13, paint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.18), w * 0.13, paint);
    // 耳の内側
    final innerEar = Paint()
      ..color = color.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.20, h * 0.18), w * 0.07, innerEar);
    canvas.drawCircle(Offset(w * 0.80, h * 0.18), w * 0.07, innerEar);

    // ベル本体
    final bellPath = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..cubicTo(w * 0.20, h * 0.10, w * 0.08, h * 0.38, w * 0.08, h * 0.62)
      ..lineTo(w * 0.08, h * 0.68)
      ..quadraticBezierTo(w * 0.08, h * 0.76, w * 0.18, h * 0.76)
      ..lineTo(w * 0.82, h * 0.76)
      ..quadraticBezierTo(w * 0.92, h * 0.76, w * 0.92, h * 0.68)
      ..lineTo(w * 0.92, h * 0.62)
      ..cubicTo(w * 0.92, h * 0.38, w * 0.80, h * 0.10, w * 0.50, h * 0.10)
      ..close();
    canvas.drawPath(bellPath, paint);

    // ベル下部フレア横棒
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.74, w * 0.88, h * 0.07),
        Radius.circular(w * 0.04),
      ),
      paint,
    );

    // ハンガー
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.10), width: w * 0.18, height: h * 0.14),
      pi, pi, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );

    // クラッパー（振り子）— 揺れで左右にずれる
    canvas.drawCircle(
      Offset(w * 0.50 + swing * w * 0.8, h * 0.84),
      w * 0.07,
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BearBellPainter old) =>
      old.swing != swing || old.wave != wave || old.color != color;
}
