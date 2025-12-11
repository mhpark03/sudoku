import 'dart:math';

class SudokuGenerator {
  final Random _random = Random();

  /// 완성된 스도쿠 보드 생성
  List<List<int>> generateSolvedBoard() {
    List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(board);
    return board;
  }

  /// 퍼즐 생성 (difficulty: 빈 칸 개수) - 3x3 박스별 균등 분포
  List<List<int>> generatePuzzle(List<List<int>> solvedBoard, int difficulty) {
    List<List<int>> puzzle =
        solvedBoard.map((row) => List<int>.from(row)).toList();

    int cellsToRemove = difficulty.clamp(20, 72);

    // 각 3x3 박스당 제거할 셀 수 계산
    int cellsPerBox = cellsToRemove ~/ 9;
    int extraCells = cellsToRemove % 9;

    // 난이도에 따른 최소 유지 셀 수
    int minCellsToKeep = cellsToRemove >= 64 ? 1 : 3;
    int maxRemovePerBox = 9 - minCellsToKeep;

    // 각 3x3 박스별로 균등하게 셀 제거
    List<int> boxOrder = List.generate(9, (i) => i)..shuffle(_random);

    for (int boxIdx = 0; boxIdx < 9; boxIdx++) {
      int boxNum = boxOrder[boxIdx];
      int boxStartRow = (boxNum ~/ 3) * 3;
      int boxStartCol = (boxNum % 3) * 3;

      // 해당 박스 내 셀 위치들
      List<int> boxPositions = [];
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          boxPositions.add((boxStartRow + r) * 9 + (boxStartCol + c));
        }
      }
      boxPositions.shuffle(_random);

      // 이 박스에서 제거할 셀 수 (최대 제한 적용)
      int toRemoveInBox = cellsPerBox + (boxIdx < extraCells ? 1 : 0);
      toRemoveInBox = toRemoveInBox.clamp(0, maxRemovePerBox);

      for (int i = 0; i < toRemoveInBox && i < boxPositions.length; i++) {
        int pos = boxPositions[i];
        int row = pos ~/ 9;
        int col = pos % 9;
        puzzle[row][col] = 0;
      }
    }

    return puzzle;
  }

  bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_random);
          for (int num in numbers) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) {
                return true;
              }
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValid(List<List<int>> board, int row, int col, int num) {
    // 행 검사
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == num) return false;
    }

    // 열 검사
    for (int i = 0; i < 9; i++) {
      if (board[i][col] == num) return false;
    }

    // 3x3 박스 검사
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[boxRow + i][boxCol + j] == num) return false;
      }
    }

    return true;
  }

  /// 현재 입력이 유효한지 검사
  static bool isValidMove(List<List<int>> board, int row, int col, int num) {
    if (num == 0) return true;

    // 행 검사
    for (int i = 0; i < 9; i++) {
      if (i != col && board[row][i] == num) return false;
    }

    // 열 검사
    for (int i = 0; i < 9; i++) {
      if (i != row && board[i][col] == num) return false;
    }

    // 3x3 박스 검사
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((boxRow + i != row || boxCol + j != col) &&
            board[boxRow + i][boxCol + j] == num) {
          return false;
        }
      }
    }

    return true;
  }

  /// 보드가 완성되었는지 검사
  static bool isBoardComplete(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) return false;
        if (!isValidMove(board, row, col, board[row][col])) return false;
      }
    }
    return true;
  }
}
