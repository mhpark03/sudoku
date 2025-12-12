import 'package:flutter/material.dart';

class KillerSudokuCell extends StatelessWidget {
  final int value;
  final bool isFixed;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSameValue;
  final bool hasError;
  final Set<int> notes;
  final VoidCallback onTap;
  final int? cageSum; // Sum to display in corner
  final bool hasCageError;
  final bool isQuickInputHighlight;
  final bool isQuickInputNoteHighlight;

  const KillerSudokuCell({
    super.key,
    required this.value,
    required this.isFixed,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSameValue,
    required this.hasError,
    required this.notes,
    required this.onTap,
    this.cageSum,
    this.hasCageError = false,
    this.isQuickInputHighlight = false,
    this.isQuickInputNoteHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = _getBackgroundColor();
    Color textColor = _getTextColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Stack(
          children: [
            // Cage sum in top-left corner
            if (cageSum != null)
              Positioned(
                left: 2,
                top: 1,
                child: Text(
                  cageSum.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: hasCageError ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ),

            // Cell value or notes
            if (value != 0)
              Center(
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              )
            else if (notes.isNotEmpty)
              _buildNotesGrid()
            else
              const SizedBox.expand(),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isSelected) return Colors.blue.shade300;
    if (isQuickInputHighlight) return Colors.blue.shade200;
    if (isQuickInputNoteHighlight) return Colors.green.shade100;
    if (isSameValue && value != 0) return Colors.blue.shade100;
    if (isHighlighted) return Colors.blue.shade50;
    return Colors.white;
  }

  Color _getTextColor() {
    if (hasError || hasCageError) return Colors.red;
    if (isFixed) return Colors.black;
    return Colors.blue.shade700;
  }

  Widget _buildNotesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth;
        final fontSize = (cellSize / 4.5).clamp(6.0, 11.0);
        // Leave space for cage sum
        final topPadding = cageSum != null ? 11.0 : 1.0;

        return Padding(
          padding:
              EdgeInsets.only(top: topPadding, left: 1, right: 1, bottom: 1),
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
