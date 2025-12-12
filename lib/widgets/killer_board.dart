import 'package:flutter/material.dart';
import '../models/killer_game_state.dart';
import 'killer_cell.dart';

class KillerBoard extends StatelessWidget {
  final KillerGameState gameState;
  final Function(int row, int col) onCellTap;
  final bool isQuickInputMode;
  final int? quickInputNumber;

  const KillerBoard({
    super.key,
    required this.gameState,
    required this.onCellTap,
    this.isQuickInputMode = false,
    this.quickInputNumber,
  });

  @override
  Widget build(BuildContext context) {
    // 케이지 테두리 정보 미리 계산
    final cageBorders = _calculateCageBorders();

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
                  final cage = gameState.getCageForCell(row, col);
                  final borders = cageBorders['${row}_$col'] ??
                      {'top': false, 'bottom': false, 'left': false, 'right': false};

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
                      child: KillerCell(
                        value: gameState.currentBoard[row][col],
                        isFixed: gameState.isFixed[row][col],
                        isSelected: gameState.isSelected(row, col),
                        isHighlighted: !isQuickInputMode &&
                            (gameState.isSameRowOrCol(row, col) ||
                                gameState.isSameBox(row, col)),
                        isSameValue:
                            !isQuickInputMode && gameState.isSameValue(row, col),
                        isSameCage:
                            !isQuickInputMode && gameState.isSameCage(row, col),
                        hasError: gameState.hasError(row, col),
                        hasCageSumError: gameState.hasCageSumError(row, col),
                        notes: gameState.notes[row][col],
                        onTap: () => onCellTap(row, col),
                        isQuickInputHighlight: isQuickInputMode &&
                            quickInputNumber != null &&
                            gameState.currentBoard[row][col] != 0 &&
                            gameState.currentBoard[row][col] == quickInputNumber,
                        isQuickInputNoteHighlight:
                            _shouldHighlightNote(row, col),
                        cageSum: cage?.sum,
                        showCageSum: gameState.isCageTopLeft(row, col),
                        hasTopBorder: borders['top'] ?? false,
                        hasBottomBorder: borders['bottom'] ?? false,
                        hasLeftBorder: borders['left'] ?? false,
                        hasRightBorder: borders['right'] ?? false,
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

  /// 케이지 테두리 정보 계산
  Map<String, Map<String, bool>> _calculateCageBorders() {
    Map<String, Map<String, bool>> borders = {};

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cage = gameState.getCageForCell(row, col);
        if (cage == null) continue;

        String key = '${row}_$col';
        borders[key] = {
          'top': false,
          'bottom': false,
          'left': false,
          'right': false,
        };

        // 상단 테두리: 위의 셀이 같은 케이지가 아니면 테두리 표시
        if (row == 0 || !cage.contains(row - 1, col)) {
          borders[key]!['top'] = true;
        }

        // 하단 테두리: 아래의 셀이 같은 케이지가 아니면 테두리 표시
        if (row == 8 || !cage.contains(row + 1, col)) {
          borders[key]!['bottom'] = true;
        }

        // 좌측 테두리: 왼쪽 셀이 같은 케이지가 아니면 테두리 표시
        if (col == 0 || !cage.contains(row, col - 1)) {
          borders[key]!['left'] = true;
        }

        // 우측 테두리: 오른쪽 셀이 같은 케이지가 아니면 테두리 표시
        if (col == 8 || !cage.contains(row, col + 1)) {
          borders[key]!['right'] = true;
        }
      }
    }

    return borders;
  }

  /// 메모 하이라이트 여부 판단
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
