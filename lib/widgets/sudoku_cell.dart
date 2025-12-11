import 'package:flutter/material.dart';

class SudokuCell extends StatelessWidget {
  final int value;
  final bool isFixed;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSameValue;
  final bool hasError;
  final Set<int> notes;
  final VoidCallback onTap;
  final bool isQuickInputHighlight;
  final bool isQuickInputNoteHighlight;

  const SudokuCell({
    super.key,
    required this.value,
    required this.isFixed,
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
      backgroundColor = Colors.blue.shade300;
    } else if (isQuickInputHighlight) {
      backgroundColor = Colors.blue.shade200;
    } else if (isQuickInputNoteHighlight) {
      backgroundColor = Colors.blue.shade100;
    } else if (isSameValue && value != 0) {
      backgroundColor = Colors.blue.shade100;
    } else if (isHighlighted) {
      backgroundColor = Colors.blue.shade50;
    } else {
      backgroundColor = Colors.white;
    }

    Color textColor;
    if (hasError) {
      textColor = Colors.red;
    } else if (isFixed) {
      textColor = Colors.black;
    } else {
      textColor = Colors.blue.shade700;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: value != 0
            ? Center(
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: isFixed ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              )
            : notes.isNotEmpty
                ? _buildNotesGrid()
                : const SizedBox.expand(),
      ),
    );
  }

  Widget _buildNotesGrid() {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (index) {
          int num = index + 1;
          bool hasNote = notes.contains(num);
          return Center(
            child: Text(
              hasNote ? num.toString() : '',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }),
      ),
    );
  }
}
