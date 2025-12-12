import 'package:flutter/material.dart';

class KillerCell extends StatelessWidget {
  final int value;
  final bool isFixed;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSameValue;
  final bool isSameCage;
  final bool hasError;
  final bool hasCageSumError;
  final Set<int> notes;
  final VoidCallback onTap;
  final bool isQuickInputHighlight;
  final bool isQuickInputNoteHighlight;

  // 케이지 관련
  final int? cageSum;
  final bool showCageSum; // 케이지 합계 표시 여부 (좌상단 셀만)
  final bool hasTopBorder;
  final bool hasBottomBorder;
  final bool hasLeftBorder;
  final bool hasRightBorder;

  const KillerCell({
    super.key,
    required this.value,
    required this.isFixed,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSameValue,
    required this.isSameCage,
    required this.hasError,
    required this.hasCageSumError,
    required this.notes,
    required this.onTap,
    this.isQuickInputHighlight = false,
    this.isQuickInputNoteHighlight = false,
    this.cageSum,
    this.showCageSum = false,
    this.hasTopBorder = false,
    this.hasBottomBorder = false,
    this.hasLeftBorder = false,
    this.hasRightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.blue.shade300;
    } else if (isQuickInputHighlight) {
      backgroundColor = Colors.blue.shade200;
    } else if (isQuickInputNoteHighlight) {
      backgroundColor = Colors.green.shade100;
    } else if (hasCageSumError) {
      backgroundColor = Colors.red.shade50;
    } else if (isSameCage) {
      backgroundColor = Colors.purple.shade50;
    } else if (isSameValue && value != 0) {
      backgroundColor = Colors.blue.shade100;
    } else if (isHighlighted) {
      backgroundColor = Colors.blue.shade50;
    } else {
      backgroundColor = Colors.white;
    }

    Color textColor;
    if (hasError || hasCageSumError) {
      textColor = Colors.red;
    } else if (isFixed) {
      textColor = Colors.black;
    } else {
      textColor = Colors.blue.shade700;
    }

    // 케이지 테두리 색상
    const cageBorderColor = Colors.black54;
    const cageBorderWidth = 1.5;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _CageBorderPainter(
          hasTopBorder: hasTopBorder,
          hasBottomBorder: hasBottomBorder,
          hasLeftBorder: hasLeftBorder,
          hasRightBorder: hasRightBorder,
          borderColor: cageBorderColor,
          borderWidth: cageBorderWidth,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Stack(
            children: [
              // 케이지 합계 표시 (좌상단)
              if (showCageSum && cageSum != null)
                Positioned(
                  top: 1,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      cageSum.toString(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: hasCageSumError ? Colors.red : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              // 셀 값 또는 메모
              Center(
                child: value != 0
                    ? Text(
                        value.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                              isFixed ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                      )
                    : notes.isNotEmpty
                        ? _buildNotesGrid()
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth;
        final fontSize = (cellSize / 4.5).clamp(6.0, 12.0);
        // 합계 표시가 있으면 메모 영역 조정
        final topPadding = showCageSum && cageSum != null ? 10.0 : 1.0;

        return Padding(
          padding: EdgeInsets.only(top: topPadding, left: 1, right: 1, bottom: 1),
          child: Column(
            children: List.generate(3, (rowIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(3, (colIndex) {
                    int num = rowIndex * 3 + colIndex + 1;
                    bool hasNote = notes.contains(num);
                    return Expanded(
                      child: Center(
                        child: Text(
                          hasNote ? num.toString() : '',
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// 케이지 테두리를 점선으로 그리는 커스텀 페인터
class _CageBorderPainter extends CustomPainter {
  final bool hasTopBorder;
  final bool hasBottomBorder;
  final bool hasLeftBorder;
  final bool hasRightBorder;
  final Color borderColor;
  final double borderWidth;

  _CageBorderPainter({
    required this.hasTopBorder,
    required this.hasBottomBorder,
    required this.hasLeftBorder,
    required this.hasRightBorder,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // 점선 패턴
    const dashWidth = 3.0;
    const dashSpace = 2.0;

    if (hasTopBorder) {
      _drawDashedLine(
        canvas,
        Offset(0, borderWidth / 2),
        Offset(size.width, borderWidth / 2),
        paint,
        dashWidth,
        dashSpace,
      );
    }

    if (hasBottomBorder) {
      _drawDashedLine(
        canvas,
        Offset(0, size.height - borderWidth / 2),
        Offset(size.width, size.height - borderWidth / 2),
        paint,
        dashWidth,
        dashSpace,
      );
    }

    if (hasLeftBorder) {
      _drawDashedLine(
        canvas,
        Offset(borderWidth / 2, 0),
        Offset(borderWidth / 2, size.height),
        paint,
        dashWidth,
        dashSpace,
      );
    }

    if (hasRightBorder) {
      _drawDashedLine(
        canvas,
        Offset(size.width - borderWidth / 2, 0),
        Offset(size.width - borderWidth / 2, size.height),
        paint,
        dashWidth,
        dashSpace,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      double dashWidth, double dashSpace) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = (dx * dx + dy * dy).abs();
    final distance = length > 0 ? length.sqrt() : 0.0;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    if (dashCount == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    for (int i = 0; i < dashCount; i++) {
      final startX = start.dx + (dashWidth + dashSpace) * i * unitX;
      final startY = start.dy + (dashWidth + dashSpace) * i * unitY;
      final endX = startX + dashWidth * unitX;
      final endY = startY + dashWidth * unitY;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CageBorderPainter oldDelegate) {
    return hasTopBorder != oldDelegate.hasTopBorder ||
        hasBottomBorder != oldDelegate.hasBottomBorder ||
        hasLeftBorder != oldDelegate.hasLeftBorder ||
        hasRightBorder != oldDelegate.hasRightBorder;
  }
}

extension on num {
  double sqrt() => this < 0 ? 0 : this.toDouble().sqrt();
}

extension on double {
  double sqrt() {
    if (this < 0) return 0;
    double x = this;
    double y = 1;
    double e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = this / x;
    }
    return x;
  }
}
