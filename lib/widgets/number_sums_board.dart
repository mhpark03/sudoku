import 'package:flutter/material.dart';
import '../models/number_sums_game_state.dart';
import 'number_sums_cell.dart';

class NumberSumsBoard extends StatelessWidget {
  final NumberSumsGameState gameState;
  final Function(int row, int col) onCellTap;

  const NumberSumsBoard({
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
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Column(
            children: List.generate(gameState.gridSize, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(gameState.gridSize, (col) {
                    return Expanded(
                      child: _buildCell(row, col),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    // Check if this is a clue cell
    final clue = gameState.getClueAt(row, col);
    if (clue != null) {
      return NumberSumsClueCell(
        downSum: clue.downSum,
        rightSum: clue.rightSum,
      );
    }

    // Check if this is an input cell
    if (gameState.cellTypes[row][col] == 1) {
      return NumberSumsInputCell(
        value: gameState.currentBoard[row][col],
        isSelected: gameState.isSelected(row, col),
        isHighlighted: gameState.isSameRun(row, col),
        isSameValue: gameState.isSameValue(row, col),
        hasError: gameState.hasError(row, col),
        notes: gameState.notes[row][col],
        onTap: () => onCellTap(row, col),
      );
    }

    // Blocked cell
    return const NumberSumsBlockedCell();
  }
}
