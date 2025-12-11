import 'package:flutter/material.dart';
import '../models/samurai_game_state.dart';

class MiniSudokuBoard extends StatelessWidget {
  final List<List<int>> board;
  final List<List<bool>> isFixed;
  final int boardIndex;
  final SamuraiGameState gameState;
  final Function(int row, int col) onCellTap;
  final bool isActiveBoard;

  const MiniSudokuBoard({
    super.key,
    required this.board,
    required this.isFixed,
    required this.boardIndex,
    required this.gameState,
    required this.onCellTap,
    required this.isActiveBoard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(9, (row) {
        return Expanded(
          child: Row(
            children: List.generate(9, (col) {
              return Expanded(
                child: _buildCell(row, col),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildCell(int row, int col) {
    int value = board[row][col];
    bool fixed = isFixed[row][col];
    bool isSelected = gameState.isSelectedCell(boardIndex, row, col);
    bool isHighlighted = isActiveBoard &&
        (gameState.isSameRowOrCol(boardIndex, row, col) ||
            gameState.isSameBox(boardIndex, row, col));
    bool isSameValue = gameState.isSameValue(boardIndex, row, col);
    bool hasError = gameState.hasError(boardIndex, row, col);
    bool isOverlap = gameState.isOverlapRegion(boardIndex, row, col);

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.blue.shade300;
    } else if (isSameValue && value != 0) {
      backgroundColor = Colors.blue.shade100;
    } else if (isHighlighted) {
      backgroundColor = Colors.blue.shade50;
    } else if (isOverlap) {
      backgroundColor = Colors.yellow.shade50;
    } else {
      backgroundColor = Colors.white;
    }

    Color textColor;
    if (hasError) {
      textColor = Colors.red;
    } else if (fixed) {
      textColor = Colors.black;
    } else {
      textColor = Colors.blue.shade700;
    }

    // 3x3 박스 테두리 계산
    bool rightBorder = (col + 1) % 3 == 0 && col != 8;
    bool bottomBorder = (row + 1) % 3 == 0 && row != 8;

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            right: BorderSide(
              color: rightBorder ? Colors.black : Colors.grey.shade300,
              width: rightBorder ? 1.5 : 0.5,
            ),
            bottom: BorderSide(
              color: bottomBorder ? Colors.black : Colors.grey.shade300,
              width: bottomBorder ? 1.5 : 0.5,
            ),
            left: BorderSide(color: Colors.grey.shade300, width: 0.5),
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Text(
                value == 0 ? '' : value.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: fixed ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
