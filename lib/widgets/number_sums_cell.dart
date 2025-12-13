import 'package:flutter/material.dart';

/// 숫자가 표시되는 입력 셀
class NumberSumsInputCell extends StatelessWidget {
  final int value;
  final bool isSelected;
  final bool isEmpty; // 제거된 셀
  final VoidCallback onTap;

  const NumberSumsInputCell({
    super.key,
    required this.value,
    required this.isSelected,
    required this.isEmpty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor = const Color(0xFF4A4A4A);

    if (isEmpty) {
      // 제거된 셀 - 빈 상태
      backgroundColor = const Color(0xFFE0E0E0);
    } else if (isSelected) {
      backgroundColor = const Color(0xFFFFEB3B);
      borderColor = const Color(0xFFFF9800);
    } else {
      backgroundColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
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
                        color: isSelected
                            ? const Color(0xFF1A237E)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// 단서 셀 (합계 표시)
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
            color: const Color(0xFF2D2D2D),
            border: Border.all(color: const Color(0xFF4A4A4A), width: 1),
          ),
          child: Stack(
            children: [
              // Diagonal line
              Positioned.fill(
                child: CustomPaint(
                  painter: _DiagonalLinePainter(),
                ),
              ),
              // Down sum (bottom-left)
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
              // Right sum (top-right)
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

/// 블록 셀 (빈 검은 셀)
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
