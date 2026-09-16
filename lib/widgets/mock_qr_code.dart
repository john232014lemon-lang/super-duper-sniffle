import 'package:flutter/material.dart';

class MockQrCode extends StatelessWidget {
  const MockQrCode({super.key, required this.value, this.size = 176});

  final String value;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'QR code for $value',
    child: Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: CustomPaint(painter: _MockQrPainter(value)),
    ),
  );
}

class _MockQrPainter extends CustomPainter {
  const _MockQrPainter(this.value);
  final String value;

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 21;
    final cell = size.width / cells;
    final paint = Paint()..color = const Color(0xFF0C2A1B);
    var seed = value.hashCode.abs();
    for (var row = 0; row < cells; row++) {
      for (var column = 0; column < cells; column++) {
        final finder = _finderCell(row, column, cells);
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        if (finder || seed.isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(column * cell, row * cell, cell + 0.2, cell + 0.2),
            paint,
          );
        }
      }
    }
  }

  bool _finderCell(int row, int column, int cells) {
    bool inFinder(int top, int left) {
      final r = row - top;
      final c = column - left;
      if (r < 0 || r > 6 || c < 0 || c > 6) return false;
      return r == 0 ||
          r == 6 ||
          c == 0 ||
          c == 6 ||
          (r >= 2 && r <= 4 && c >= 2 && c <= 4);
    }

    return inFinder(0, 0) || inFinder(0, cells - 7) || inFinder(cells - 7, 0);
  }

  @override
  bool shouldRepaint(covariant _MockQrPainter oldDelegate) =>
      oldDelegate.value != value;
}
