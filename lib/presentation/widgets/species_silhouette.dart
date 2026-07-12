import 'package:flutter/material.dart';

/// Solid cat/dog head silhouettes drawn with paths (Material has no
/// dedicated cat/dog icons). Falls back to a generic paw for other species.
class SpeciesSilhouette extends StatelessWidget {
  final String species; // 'dog' | 'cat' | other
  final double size;
  final Color color;

  const SpeciesSilhouette({
    super.key,
    required this.species,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    switch (species) {
      case 'dog':
        return CustomPaint(
          size: Size.square(size),
          painter: _DogSilhouettePainter(color),
        );
      case 'cat':
        return CustomPaint(
          size: Size.square(size),
          painter: _CatSilhouettePainter(color),
        );
      default:
        return Icon(Icons.pets, size: size, color: color);
    }
  }
}

/// Front-facing cat head: round face with pointed ears.
class _CatSilhouettePainter extends CustomPainter {
  final Color color;
  const _CatSilhouettePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      // Left ear.
      ..moveTo(22 * s, 40 * s)
      ..lineTo(14 * s, 10 * s)
      ..lineTo(40 * s, 24 * s)
      // Top of head.
      ..quadraticBezierTo(50 * s, 20 * s, 60 * s, 24 * s)
      // Right ear.
      ..lineTo(86 * s, 10 * s)
      ..lineTo(78 * s, 40 * s)
      // Right cheek down to chin.
      ..cubicTo(88 * s, 52 * s, 88 * s, 68 * s, 76 * s, 80 * s)
      ..cubicTo(62 * s, 92 * s, 38 * s, 92 * s, 24 * s, 80 * s)
      // Left cheek back up to the left ear.
      ..cubicTo(12 * s, 68 * s, 12 * s, 52 * s, 22 * s, 40 * s)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CatSilhouettePainter old) => old.color != color;
}

/// Front-facing dog head: rounded skull with floppy ears and a muzzle.
class _DogSilhouettePainter extends CustomPainter {
  final Color color;
  const _DogSilhouettePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final head = Path()
      // Top of the skull, left to right.
      ..moveTo(30 * s, 26 * s)
      ..cubicTo(38 * s, 12 * s, 62 * s, 12 * s, 70 * s, 26 * s)
      // Right floppy ear.
      ..cubicTo(82 * s, 26 * s, 90 * s, 36 * s, 90 * s, 50 * s)
      ..cubicTo(90 * s, 62 * s, 82 * s, 68 * s, 74 * s, 62 * s)
      // Right side of the face down to the chin.
      ..cubicTo(76 * s, 74 * s, 68 * s, 86 * s, 50 * s, 86 * s)
      ..cubicTo(32 * s, 86 * s, 24 * s, 74 * s, 26 * s, 62 * s)
      // Left floppy ear.
      ..cubicTo(18 * s, 68 * s, 10 * s, 62 * s, 10 * s, 50 * s)
      ..cubicTo(10 * s, 36 * s, 18 * s, 26 * s, 30 * s, 26 * s)
      ..close();

    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_DogSilhouettePainter old) => old.color != color;
}
