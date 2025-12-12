import 'dart:math';
import 'package:flutter/material.dart';
import '../models/killer_cage.dart';

class CageBorderPainter extends CustomPainter {
  final List<KillerCage> cages;
  final double? cellSize;

  CageBorderPainter({required this.cages, this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cSize = cellSize ?? size.width / 9;

    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Build lookup map for cage IDs
    Map<String, int> cellToCage = {};
    for (var cage in cages) {
      for (var cell in cage.cells) {
        cellToCage['${cell[0]}_${cell[1]}'] = cage.cageId;
      }
    }

    // Draw borders for each cell
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        String cellKey = '${row}_$col';
        int? currentCageId = cellToCage[cellKey];
        if (currentCageId == null) continue;

        double x = col * cSize;
        double y = row * cSize;

        // Top edge
        if (row == 0 || cellToCage['${row - 1}_$col'] != currentCageId) {
          _drawDashedLine(canvas, Offset(x, y), Offset(x + cSize, y), paint);
        }

        // Bottom edge
        if (row == 8 || cellToCage['${row + 1}_$col'] != currentCageId) {
          _drawDashedLine(
              canvas, Offset(x, y + cSize), Offset(x + cSize, y + cSize), paint);
        }

        // Left edge
        if (col == 0 || cellToCage['${row}_${col - 1}'] != currentCageId) {
          _drawDashedLine(canvas, Offset(x, y), Offset(x, y + cSize), paint);
        }

        // Right edge
        if (col == 8 || cellToCage['${row}_${col + 1}'] != currentCageId) {
          _drawDashedLine(
              canvas, Offset(x + cSize, y), Offset(x + cSize, y + cSize), paint);
        }
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 3.0;
    const gapLength = 2.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (dx * dx + dy * dy);
    if (distance == 0) return;

    final len = distance > 0 ? sqrt(distance) : distance;
    if (len == 0) return;

    final unitX = dx / len;
    final unitY = dy / len;

    double drawn = 0;
    bool isDash = true;

    while (drawn < len) {
      if (isDash) {
        final dashEnd = (drawn + dashLength).clamp(0.0, len);
        canvas.drawLine(
          Offset(start.dx + unitX * drawn, start.dy + unitY * drawn),
          Offset(start.dx + unitX * dashEnd, start.dy + unitY * dashEnd),
          paint,
        );
        drawn = dashEnd;
      } else {
        drawn += gapLength;
      }
      isDash = !isDash;
    }
  }

  @override
  bool shouldRepaint(covariant CageBorderPainter oldDelegate) {
    return oldDelegate.cages != cages || oldDelegate.cellSize != cellSize;
  }
}
