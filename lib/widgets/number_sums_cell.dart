import 'package:flutter/material.dart';

class NumberSumsInputCell extends StatelessWidget {
  final int value;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSameValue;
  final bool hasError;
  final Set<int> notes;
  final VoidCallback onTap;
  final bool isQuickInputHighlight;
  final bool isQuickInputNoteHighlight;

  const NumberSumsInputCell({
    super.key,
    required this.value,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSameValue,
    required this.hasError,
    required this.notes,
    required this.onTap,
    this.isQuickInputHighlight = false,
    this.isQuickInputNoteHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.orange.shade300;
    } else if (hasError) {
      backgroundColor = Colors.red.shade100;
    } else if (isSameValue) {
      backgroundColor = Colors.orange.shade100;
    } else if (isHighlighted) {
      backgroundColor = Colors.orange.shade50;
    } else if (isQuickInputHighlight || isQuickInputNoteHighlight) {
      backgroundColor = Colors.orange.shade200;
    } else {
      backgroundColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        child: value != 0
            ? Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: hasError ? Colors.red : Colors.black87,
                  ),
                ),
              )
            : _buildNotes(),
      ),
    );
  }

  Widget _buildNotes() {
    if (notes.isEmpty) return const SizedBox();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth;
        final noteSize = cellSize / 3;
        final fontSize = noteSize * 0.65;

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
                    color: isQuickInputNoteHighlight && notes.contains(note)
                        ? Colors.orange.shade800
                        : Colors.grey.shade600,
                    fontWeight: isQuickInputNoteHighlight && notes.contains(note)
                        ? FontWeight.bold
                        : FontWeight.normal,
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
        color: Colors.grey.shade800,
        border: Border.all(color: Colors.grey.shade600, width: 0.5),
      ),
      child: CustomPaint(
        painter: _ClueCellPainter(
          downSum: downSum,
          rightSum: rightSum,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ClueCellPainter extends CustomPainter {
  final int? downSum;
  final int? rightSum;

  _ClueCellPainter({this.downSum, this.rightSum});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    // Draw diagonal line
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: size.width * 0.28,
      fontWeight: FontWeight.bold,
    );

    // Draw down sum (bottom-left area)
    if (downSum != null) {
      final textSpan = TextSpan(text: '$downSum', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final offset = Offset(
        size.width * 0.12,
        size.height * 0.55,
      );
      textPainter.paint(canvas, offset);
    }

    // Draw right sum (top-right area)
    if (rightSum != null) {
      final textSpan = TextSpan(text: '$rightSum', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final offset = Offset(
        size.width * 0.55,
        size.height * 0.12,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _ClueCellPainter oldDelegate) {
    return oldDelegate.downSum != downSum || oldDelegate.rightSum != rightSum;
  }
}

class NumberSumsBlockedCell extends StatelessWidget {
  const NumberSumsBlockedCell({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border.all(color: Colors.grey.shade600, width: 0.5),
      ),
    );
  }
}
