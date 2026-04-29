import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Aged-paper background with optional ruled lines, subtle vignette and a
/// faint paper-grain noise. Used by the journal screens to give that
/// old-school diary feel.
class PaperBackground extends StatelessWidget {
  final Widget child;
  final bool ruled;
  final double lineSpacing;
  final bool showLeftMargin;

  const PaperBackground({
    super.key,
    required this.child,
    this.ruled = false,
    this.lineSpacing = 32,
    this.showLeftMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cream, AppColors.beigeWarm],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: _PaperPainter(
          ruled: ruled,
          lineSpacing: lineSpacing,
          showLeftMargin: showLeftMargin,
        ),
        child: child,
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  final bool ruled;
  final double lineSpacing;
  final bool showLeftMargin;

  _PaperPainter({
    required this.ruled,
    required this.lineSpacing,
    required this.showLeftMargin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          AppColors.crimsonDeep.withValues(alpha: 0.04),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: size.longestSide * 0.7,
      ));
    canvas.drawRect(Offset.zero & size, vignettePaint);

    // Paper grain — sparse warm specks
    final rng = math.Random(7);
    final speckPaint = Paint()
      ..color = AppColors.crimsonDeep.withValues(alpha: 0.025);
    final speckCount = (size.width * size.height / 9000).clamp(40, 220).toInt();
    for (var i = 0; i < speckCount; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      canvas.drawCircle(
          Offset(dx, dy), 0.4 + rng.nextDouble() * 0.6, speckPaint);
    }

    // Ruled horizontal lines
    if (ruled) {
      final rulePaint = Paint()
        ..color = AppColors.crimson.withValues(alpha: 0.10)
        ..strokeWidth = 0.7;
      var y = lineSpacing;
      while (y < size.height) {
        canvas.drawLine(
            Offset(8, y), Offset(size.width - 8, y), rulePaint);
        y += lineSpacing;
      }
    }

    // Left margin red line (notebook style)
    if (showLeftMargin) {
      final marginPaint = Paint()
        ..color = AppColors.crimson.withValues(alpha: 0.45)
        ..strokeWidth = 1.2;
      const marginX = 56.0;
      canvas.drawLine(
          const Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperPainter oldDelegate) =>
      oldDelegate.ruled != ruled ||
      oldDelegate.lineSpacing != lineSpacing ||
      oldDelegate.showLeftMargin != showLeftMargin;
}

/// A horizontal ornamental divider — small swash + dot + swash.
class PageOrnament extends StatelessWidget {
  final Color color;
  final double width;
  const PageOrnament({
    super.key,
    this.color = AppColors.crimson,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 16,
      child: CustomPaint(
        painter: _OrnamentPainter(color: color),
      ),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  final Color color;
  _OrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final cy = size.height / 2;
    final mid = size.width / 2;

    // Left swash
    final leftPath = Path()
      ..moveTo(0, cy)
      ..cubicTo(size.width * 0.18, cy - 6, size.width * 0.32, cy + 6,
          mid - 8, cy);
    canvas.drawPath(leftPath, paint);

    // Right swash
    final rightPath = Path()
      ..moveTo(size.width, cy)
      ..cubicTo(size.width * 0.82, cy - 6, size.width * 0.68, cy + 6,
          mid + 8, cy);
    canvas.drawPath(rightPath, paint);

    // Center diamond
    final diamondPaint = Paint()..color = color.withValues(alpha: 0.55);
    final r = 3.0;
    final diamond = Path()
      ..moveTo(mid, cy - r)
      ..lineTo(mid + r, cy)
      ..lineTo(mid, cy + r)
      ..lineTo(mid - r, cy)
      ..close();
    canvas.drawPath(diamond, diamondPaint);
  }

  @override
  bool shouldRepaint(covariant _OrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}
