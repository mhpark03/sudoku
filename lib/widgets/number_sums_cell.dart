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
      backgroundColor = const Color(0xFFFFF3C4); // 연한 노란색
      borderColor = const Color(0xFFFFD93D);
    } else if (hasError) {
      backgroundColor = const Color(0xFFFFE0E0); // 연한 빨간색
      borderColor = Colors.red.shade300;
    } else if (isSameValue) {
      backgroundColor = const Color(0xFFE8F4FD); // 연한 파란색
    } else if (isHighlighted) {
      backgroundColor = const Color(0xFFFFF9E6); // 아주 연한 노란색
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
        color: const Color(0xFFF5F0E6), // 베이지/크림색
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final fontSize = size * 0.26;

          return Stack(
            children: [
              // Diagonal line
              Positioned.fill(
                child: CustomPaint(
                  painter: _DiagonalLinePainter(),
                ),
              ),
              // Down sum (bottom-left triangle)
              if (downSum != null)
                Positioned(
                  left: 3,
                  bottom: 2,
                  child: Text(
                    '$downSum',
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // Right sum (top-right triangle)
              if (rightSum != null)
                Positioned(
                  right: 3,
                  top: 2,
                  child: Text(
                    '$rightSum',
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1.0;

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
        color: const Color(0xFFF5F0E6), // 베이지/크림색
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
    );
  }
}
