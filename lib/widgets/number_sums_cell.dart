import 'package:flutter/material.dart';

class NumberSumsInputCell extends StatelessWidget {
  final int value;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSameValue;
  final bool hasError;
  final Set<int> notes;
  final VoidCallback onTap;

  const NumberSumsInputCell({
    super.key,
    required this.value,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSameValue,
    required this.hasError,
    required this.notes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor = const Color(0xFF4A4A4A);

    if (isSelected) {
      backgroundColor = const Color(0xFFFFEB3B); // Bright yellow for selection
      borderColor = const Color(0xFFFF9800);
    } else if (hasError) {
      backgroundColor = const Color(0xFFFFCDD2);
      borderColor = Colors.red;
    } else if (isSameValue) {
      backgroundColor = const Color(0xFFE3F2FD);
    } else if (isHighlighted) {
      backgroundColor = const Color(0xFFFFF8E1);
    } else {
      backgroundColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: value != 0
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: hasError ? Colors.red : const Color(0xFF1A237E),
                      ),
                    ),
                  ),
                )
              : _buildNotes(),
        ),
      ),
    );
  }

  Widget _buildNotes() {
    if (notes.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth;
        final noteSize = cellSize / 3;
        final fontSize = noteSize * 0.5;

        return Stack(
          children: notes.map((note) {
            final row = (note - 1) ~/ 3;
            final col = (note - 1) % 3;
            return Positioned(
              left: col * noteSize,
              top: row * noteSize,
              width: noteSize,
              height: noteSize,
              child: Center(
                child: Text(
                  '$note',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class NumberSumsClueCell extends StatelessWidget {
  final int? downSum;
  final int? rightSum;

  const NumberSumsClueCell({
    super.key,
    this.downSum,
    this.rightSum,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final fontSize = (size * 0.28).clamp(8.0, 14.0);

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D), // Dark background
            border: Border.all(color: const Color(0xFF4A4A4A), width: 1),
          ),
          child: Stack(
            children: [
              // Diagonal line from top-left to bottom-right
              Positioned.fill(
                child: CustomPaint(
                  painter: _DiagonalLinePainter(),
                ),
              ),
              // Down sum (bottom-left triangle area)
              if (downSum != null)
                Positioned(
                  left: size * 0.08,
                  bottom: size * 0.08,
                  child: Text(
                    '$downSum',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Right sum (top-right triangle area)
              if (rightSum != null)
                Positioned(
                  right: size * 0.08,
                  top: size * 0.08,
                  child: Text(
                    '$rightSum',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5A5A5A)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NumberSumsBlockedCell extends StatelessWidget {
  const NumberSumsBlockedCell({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border.all(color: const Color(0xFF4A4A4A), width: 1),
      ),
    );
  }
}
