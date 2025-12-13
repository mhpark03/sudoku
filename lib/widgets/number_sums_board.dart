import 'package:flutter/material.dart';
import '../models/number_sums_game_state.dart';
import 'number_sums_cell.dart';

class NumberSumsBoard extends StatelessWidget {
  final NumberSumsGameState gameState;
  final Function(int row, int col) onCellTap;
  final bool isQuickInputMode;
  final int? quickInputNumber;

  const NumberSumsBoard({
    super.key,
    required this.gameState,
    required this.onCellTap,
    this.isQuickInputMode = false,
    this.quickInputNumber,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade800, width: 2),
        ),
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
        isHighlighted: !isQuickInputMode && gameState.isSameRun(row, col),
        isSameValue: !isQuickInputMode && gameState.isSameValue(row, col),
        hasError: gameState.hasError(row, col) || gameState.hasRunSumError(row, col),
        notes: gameState.notes[row][col],
        onTap: () => onCellTap(row, col),
        isQuickInputHighlight: isQuickInputMode &&
            quickInputNumber != null &&
            gameState.currentBoard[row][col] != 0 &&
            gameState.currentBoard[row][col] == quickInputNumber,
        isQuickInputNoteHighlight: _shouldHighlightNote(row, col),
      );
    }

    // Blocked cell
    return const NumberSumsBlockedCell();
  }

  bool _shouldHighlightNote(int row, int col) {
    if (gameState.currentBoard[row][col] != 0) return false;
    if (gameState.notes[row][col].isEmpty) return false;

    if (isQuickInputMode) {
      if (quickInputNumber == null) return false;
      return gameState.notes[row][col].contains(quickInputNumber);
    } else {
      if (gameState.selectedRow == null || gameState.selectedCol == null) {
        return false;
      }
      int selectedValue = gameState
          .currentBoard[gameState.selectedRow!][gameState.selectedCol!];
      if (selectedValue == 0) return false;
      return gameState.notes[row][col].contains(selectedValue);
    }
  }
}
