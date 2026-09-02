import 'package:flutter/material.dart';

/// A brand logo rendering the "Cracked X on Folder Cover" identity.
/// Features a cybernetic folder silhouette with an embossed, fractured "X"
/// cut into the front cover, dynamically adapting to the active theme accent.
class CrackedXLogo extends StatelessWidget {
  final double size;
  final Color? accentColor;
  final bool showBackground;

  const CrackedXLogo({
    super.key,
    this.size = 48,
    this.accentColor,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = accentColor ?? const Color(0xFF00897B);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FolderCrackedXPainter(accentColor: themeColor),
      ),
    );
  }
}

class _FolderCrackedXPainter extends CustomPainter {
  final Color accentColor;

  _FolderCrackedXPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base folder dimensions
    final folderTabWidth = w * 0.40;
    final folderRadius = Radius.circular(w * 0.08);

    // 1. Folder Back Plate & Tab
    final backPlatePath = Path()
      ..moveTo(w * 0.12, h * 0.22)
      ..lineTo(w * 0.12 + folderTabWidth * 0.85, h * 0.22)
      ..lineTo(w * 0.12 + folderTabWidth, h * 0.30)
      ..lineTo(w * 0.88, h * 0.30)
      ..arcToPoint(Offset(w * 0.92, h * 0.34), radius: Radius.circular(w * 0.04))
      ..lineTo(w * 0.92, h * 0.82)
      ..arcToPoint(Offset(w * 0.84, h * 0.88), radius: folderRadius)
      ..lineTo(w * 0.16, h * 0.88)
      ..arcToPoint(Offset(w * 0.08, h * 0.82), radius: folderRadius)
      ..lineTo(w * 0.08, h * 0.28)
      ..arcToPoint(Offset(w * 0.12, h * 0.22), radius: Radius.circular(w * 0.04))
      ..close();

    final backPaint = Paint()
      ..color = const Color(0xFF141820)
      ..style = PaintingStyle.fill;
    canvas.drawPath(backPlatePath, backPaint);

    final backStrokePaint = Paint()
      ..color = const Color(0xFF283040)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    canvas.drawPath(backPlatePath, backStrokePaint);

    // 2. Folder Front Cover Flap
    final frontFlapPath = Path()
      ..moveTo(w * 0.08, h * 0.38)
      ..lineTo(w * 0.92, h * 0.38)
      ..arcToPoint(Offset(w * 0.94, h * 0.42), radius: Radius.circular(w * 0.04))
      ..lineTo(w * 0.90, h * 0.86)
      ..arcToPoint(Offset(w * 0.82, h * 0.92), radius: folderRadius)
      ..lineTo(w * 0.18, h * 0.92)
      ..arcToPoint(Offset(w * 0.10, h * 0.86), radius: folderRadius)
      ..lineTo(w * 0.06, h * 0.42)
      ..arcToPoint(Offset(w * 0.08, h * 0.38), radius: Radius.circular(w * 0.04))
      ..close();

    final frontPaint = Paint()
      ..color = const Color(0xFF1B212D)
      ..style = PaintingStyle.fill;
    canvas.drawPath(frontFlapPath, frontPaint);

    // Subtle front flap rim accent
    final frontStroke = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025;
    canvas.drawPath(frontFlapPath, frontStroke);

    // 3. Cracked X geometry on the front cover
    // Centered around (w * 0.50, h * 0.65)
    final cx = w * 0.50;
    final cy = h * 0.65;
    final r = w * 0.21;

    final xPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    // Top-Left Shard
    final tlPath = Path()
      ..moveTo(cx - r, cy - r * 0.9)
      ..lineTo(cx - r * 0.35, cy - r * 0.9)
      ..lineTo(cx - r * 0.08, cy - r * 0.28)
      ..lineTo(cx - r * 0.45, cy - r * 0.18)
      ..close();
    canvas.drawPath(tlPath, xPaint);

    // Top-Right Shard
    final trPath = Path()
      ..moveTo(cx + r * 0.35, cy - r * 0.9)
      ..lineTo(cx + r, cy - r * 0.9)
      ..lineTo(cx + r * 0.48, cy - r * 0.15)
      ..lineTo(cx + r * 0.12, cy - r * 0.32)
      ..close();
    canvas.drawPath(trPath, xPaint);

    // Bottom-Left Shard
    final blPath = Path()
      ..moveTo(cx - r * 0.48, cy + r * 0.18)
      ..lineTo(cx - r * 0.12, cy + r * 0.35)
      ..lineTo(cx - r * 0.40, cy + r * 0.9)
      ..lineTo(cx - r, cy + r * 0.9)
      ..close();
    canvas.drawPath(blPath, xPaint);

    // Bottom-Right Shard
    final brPath = Path()
      ..moveTo(cx + r * 0.10, cy + r * 0.28)
      ..lineTo(cx + r * 0.52, cy + r * 0.15)
      ..lineTo(cx + r, cy + r * 0.9)
      ..lineTo(cx + r * 0.38, cy + r * 0.9)
      ..close();
    canvas.drawPath(brPath, xPaint);

    // 4. Electric Fissure Line cutting through the X
    final crackPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.024
      ..strokeCap = StrokeCap.round;

    final crackPath = Path()
      ..moveTo(cx - r * 0.65, cy - r * 0.75)
      ..lineTo(cx - r * 0.15, cy - r * 0.10)
      ..lineTo(cx + r * 0.12, cy + r * 0.05)
      ..lineTo(cx - r * 0.05, cy + r * 0.40)
      ..lineTo(cx + r * 0.60, cy + r * 0.80);
    canvas.drawPath(crackPath, crackPaint);

    // Glowing fracture core
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(crackPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _FolderCrackedXPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor;
  }
}
