import 'package:flutter/material.dart';

/// 숫자가 표시되는 입력 셀
class NumberSumsInputCell extends StatelessWidget {
  final int value;
  final bool isSelected;
  final bool isEmpty;
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
      backgroundColor = const Color(0xFF3A3A3A);
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
                        fontSize: 24,
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

/// 합계를 표시하는 헤더 셀
class NumberSumsSumCell extends StatelessWidget {
  final int sum;
  final bool isColumnSum; // true = 열 합계(상단), false = 행 합계(좌측)

  const NumberSumsSumCell({
    super.key,
    required this.sum,
    required this.isColumnSum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border.all(color: const Color(0xFF4A4A4A), width: 1),
      ),
      child: Stack(
        children: [
          // 대각선
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalLinePainter(),
            ),
          ),
          // 합계 숫자
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                final fontSize = (size * 0.35).clamp(10.0, 16.0);

                return Stack(
                  children: [
                    if (isColumnSum)
                      // 열 합계는 아래 삼각형 (좌하단)
                      Positioned(
                        left: size * 0.1,
                        bottom: size * 0.1,
                        child: Text(
                          '$sum',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      // 행 합계는 위 삼각형 (우상단)
                      Positioned(
                        right: size * 0.1,
                        top: size * 0.1,
                        child: Text(
                          '$sum',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                );
              },
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

/// 블록 셀 (코너 등)
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
