import 'package:flutter/material.dart';
import '../models/game_state.dart';
import 'sudoku_cell.dart';

class SudokuBoard extends StatelessWidget {
  final GameState gameState;
  final Function(int row, int col) onCellTap;

  const SudokuBoard({
    super.key,
    required this.gameState,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Column(
          children: List.generate(9, (row) {
            return Expanded(
              child: Row(
                children: List.generate(9, (col) {
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: (col + 1) % 3 == 0 && col != 8
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                          bottom: BorderSide(
                            color: (row + 1) % 3 == 0 && row != 8
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: SudokuCell(
                        value: gameState.currentBoard[row][col],
                        isFixed: gameState.isFixed[row][col],
                        isSelected: gameState.isSelected(row, col),
                        isHighlighted: gameState.isSameRowOrCol(row, col) ||
                            gameState.isSameBox(row, col),
                        isSameValue: gameState.isSameValue(row, col),
                        hasError: gameState.hasError(row, col),
                        notes: gameState.notes[row][col],
                        onTap: () => onCellTap(row, col),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
