import 'dart:math';

class SudokuGenerator {
  final Random _random = Random();

  /// 완성된 스도쿠 보드 생성
  List<List<int>> generateSolvedBoard() {
    List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(board);
    return board;
  }

  /// 퍼즐 생성 (difficulty: 빈 칸 개수, 30-60 권장)
  List<List<int>> generatePuzzle(List<List<int>> solvedBoard, int difficulty) {
    List<List<int>> puzzle =
        solvedBoard.map((row) => List<int>.from(row)).toList();

    int cellsToRemove = difficulty.clamp(20, 64);
    List<int> positions = List.generate(81, (i) => i)..shuffle(_random);

    for (int i = 0; i < cellsToRemove; i++) {
      int pos = positions[i];
      int row = pos ~/ 9;
      int col = pos % 9;
      puzzle[row][col] = 0;
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
