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
    Color borderColor = Colors.grey.shade300;

    if (isSelected) {
      backgroundColor = const Color(0xFFFFF3C4);
      borderColor = const Color(0xFFFFD93D);
    } else if (hasError) {
      backgroundColor = const Color(0xFFFFE0E0);
      borderColor = Colors.red.shade300;
    } else if (isSameValue) {
      backgroundColor = const Color(0xFFE8F4FD);
    } else if (isHighlighted) {
      backgroundColor = const Color(0xFFFFF9E6);
    } else {
      backgroundColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Center(
          child: value != 0
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: hasError ? Colors.red : const Color(0xFF333333),
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
        final fontSize = noteSize * 0.55;

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
                    color: Colors.grey.shade500,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E0D5), // 좀 더 어두운 베이지색
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      child: Stack(
        children: [
          // Diagonal line from top-left to bottom-right
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalLinePainter(),
            ),
          ),
          // Down sum (bottom-left) - 킬러 스도쿠 스타일 배지
          if (downSum != null)
            Positioned(
              left: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$downSum',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
              ),
            ),
          // Right sum (top-right) - 킬러 스도쿠 스타일 배지
          if (rightSum != null)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$rightSum',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBB0A0)
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
        color: const Color(0xFFE8E0D5),
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
    );
  }
}
