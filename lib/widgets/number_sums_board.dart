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
          color: const Color(0xFF2D2D2D),
          border: Border.all(color: const Color(0xFF4A4A4A), width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
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
    // (0, 0) = 코너 셀 (투명하게)
    if (row == 0 && col == 0) {
      return const NumberSumsCornerCell();
    }

    // 첫 번째 행 (열 합계 표시)
    if (row == 0 && col > 0) {
      return NumberSumsSumCell(sum: gameState.colSums[col]);
    }

    // 첫 번째 열 (행 합계 표시)
    if (col == 0 && row > 0) {
      return NumberSumsSumCell(sum: gameState.rowSums[row]);
    }

    // 입력 셀
    final value = gameState.currentBoard[row][col];
    return NumberSumsInputCell(
      value: value,
      isSelected: gameState.isSelected(row, col),
      isEmpty: value == 0,
      onTap: () => onCellTap(row, col),
    );
  }
}
