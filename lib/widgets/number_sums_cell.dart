import 'package:flutter/material.dart';

/// 숫자가 표시되는 입력 셀
class NumberSumsInputCell extends StatelessWidget {
  final int value;
  final bool isSelected;
  final bool isEmpty;
  final bool isMarkedCorrect;
  final VoidCallback onTap;

  const NumberSumsInputCell({
    super.key,
    required this.value,
    required this.isSelected,
    required this.isEmpty,
    this.isMarkedCorrect = false,
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
        child: Stack(
          children: [
            // 정답 표시 동그라미
            if (isMarkedCorrect && !isEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: _CirclePainter(),
                ),
              ),
            // 숫자
            Center(
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
          ],
        ),
      ),
    );
  }
}

/// 동그라미 그리기 Painter
class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width < size.height ? size.width : size.height) / 2 - 4;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 합계를 표시하는 헤더 셀
class NumberSumsSumCell extends StatelessWidget {
  final int sum;

  const NumberSumsSumCell({
    super.key,
    required this.sum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border.all(color: const Color(0xFF4A4A4A), width: 1),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              '$sum',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 코너 셀 (투명하게 처리)
class NumberSumsCornerCell extends StatelessWidget {
  const NumberSumsCornerCell({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E), // 배경색과 동일하게
    );
  }
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
