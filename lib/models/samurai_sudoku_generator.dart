import 'dart:math';

/// 사무라이 스도쿠: 5개의 9x9 보드가 겹쳐진 형태
/// 배치:
///   [0]   [1]      (상단 좌/우)
///     [2]          (중앙)
///   [3]   [4]      (하단 좌/우)
///
/// 겹치는 영역:
/// - 보드 0의 우하단 3x3 = 보드 2의 좌상단 3x3
/// - 보드 1의 좌하단 3x3 = 보드 2의 우상단 3x3
/// - 보드 2의 좌하단 3x3 = 보드 3의 우상단 3x3
/// - 보드 2의 우하단 3x3 = 보드 4의 좌상단 3x3

class SamuraiSudokuGenerator {
  final Random _random = Random();

  /// 5개의 연결된 스도쿠 보드 생성
  List<List<List<int>>> generateSolvedBoards() {
    List<List<List<int>>> boards = List.generate(
      5,
      (_) => List.generate(9, (_) => List.filled(9, 0)),
    );

    // 순서대로 보드 생성 (겹치는 영역 고려)
    _fillBoard(boards[0]);
    _fillBoardWithConstraint(boards[1], null, null);
    _fillCenterBoard(boards[2], boards[0], boards[1]);
    _fillBoardWithOverlap(boards[3], boards[2], 3); // 보드2의 좌하단과 보드3의 우상단
    _fillBoardWithOverlap(boards[4], boards[2], 4); // 보드2의 우하단과 보드4의 좌상단

    return boards;
  }

  /// 퍼즐 생성 (각 보드에서 셀 제거) - 3x3 박스별 균등 분포
  List<List<List<int>>> generatePuzzles(
      List<List<List<int>>> solvedBoards, int difficulty) {
    List<List<List<int>>> puzzles = solvedBoards
        .map((board) => board.map((row) => List<int>.from(row)).toList())
        .toList();

    int cellsToRemove = difficulty.clamp(25, 50);

    // 각 3x3 박스당 제거할 셀 수 계산 (9개 박스에 균등 분배)
    int cellsPerBox = cellsToRemove ~/ 9;
    int extraCells = cellsToRemove % 9;

    // 각 박스에서 최소 유지할 셀 수 (최소 3개는 보이도록)
    int minCellsToKeep = 3;
    int maxRemovePerBox = 9 - minCellsToKeep; // 최대 6개만 제거 가능

    for (int b = 0; b < 5; b++) {
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
            int row = boxStartRow + r;
            int col = boxStartCol + c;
            boxPositions.add(row * 9 + col);
          }
        }
        boxPositions.shuffle(_random);

        // 이 박스에서 제거할 셀 수 (최대 제한 적용)
        int toRemoveInBox = cellsPerBox + (boxIdx < extraCells ? 1 : 0);
        toRemoveInBox = toRemoveInBox.clamp(0, maxRemovePerBox);
        int removed = 0;

        for (int pos in boxPositions) {
          if (removed >= toRemoveInBox) break;

          int row = pos ~/ 9;
          int col = pos % 9;

          // 겹치는 영역은 제거 확률을 낮춤
          if (_isOverlapCell(b, row, col) && _random.nextDouble() > 0.5) {
            continue;
          }

          puzzles[b][row][col] = 0;
          removed++;
        }
      }
    }

    // 겹치는 영역 동기화
    _syncOverlapRegions(puzzles);

    return puzzles;
  }

  bool _isOverlapCell(int boardIndex, int row, int col) {
    switch (boardIndex) {
      case 0:
        return row >= 6 && col >= 6; // 우하단
      case 1:
        return row >= 6 && col < 3; // 좌하단
      case 2:
        return (row < 3 && col < 3) || // 좌상단
            (row < 3 && col >= 6) || // 우상단
            (row >= 6 && col < 3) || // 좌하단
            (row >= 6 && col >= 6); // 우하단
      case 3:
        return row < 3 && col >= 6; // 우상단
      case 4:
        return row < 3 && col < 3; // 좌상단
      default:
        return false;
    }
  }

  void _syncOverlapRegions(List<List<List<int>>> boards) {
    // 보드 0 우하단 <-> 보드 2 좌상단
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int val = boards[0][6 + i][6 + j] != 0
            ? boards[0][6 + i][6 + j]
            : boards[2][i][j];
        boards[0][6 + i][6 + j] = val;
        boards[2][i][j] = val;
      }
    }

    // 보드 1 좌하단 <-> 보드 2 우상단
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int val = boards[1][6 + i][j] != 0
            ? boards[1][6 + i][j]
            : boards[2][i][6 + j];
        boards[1][6 + i][j] = val;
        boards[2][i][6 + j] = val;
      }
    }

    // 보드 2 좌하단 <-> 보드 3 우상단
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int val = boards[2][6 + i][j] != 0
            ? boards[2][6 + i][j]
            : boards[3][i][6 + j];
        boards[2][6 + i][j] = val;
        boards[3][i][6 + j] = val;
      }
    }

    // 보드 2 우하단 <-> 보드 4 좌상단
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        int val = boards[2][6 + i][6 + j] != 0
            ? boards[2][6 + i][6 + j]
            : boards[4][i][j];
        boards[2][6 + i][6 + j] = val;
        boards[4][i][j] = val;
      }
    }
  }

  bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_random);
          for (int num in numbers) {
            if (_isValidInBoard(board, row, col, num)) {
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

  void _fillBoardWithConstraint(
      List<List<int>> board, List<List<int>>? constraint, String? position) {
    _fillBoard(board);
  }

  void _fillCenterBoard(List<List<int>> center, List<List<int>> topLeft,
      List<List<int>> topRight) {
    // 좌상단 3x3을 topLeft의 우하단에서 복사
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        center[i][j] = topLeft[6 + i][6 + j];
      }
    }

    // 우상단 3x3을 topRight의 좌하단에서 복사
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        center[i][6 + j] = topRight[6 + i][j];
      }
    }

    // 나머지 채우기
    _fillBoardPartial(center);
  }

  void _fillBoardWithOverlap(
      List<List<int>> board, List<List<int>> centerBoard, int boardIndex) {
    if (boardIndex == 3) {
      // 보드 3: 우상단 3x3을 center의 좌하단에서 복사
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          board[i][6 + j] = centerBoard[6 + i][j];
        }
      }
    } else if (boardIndex == 4) {
      // 보드 4: 좌상단 3x3을 center의 우하단에서 복사
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          board[i][j] = centerBoard[6 + i][6 + j];
        }
      }
    }

    _fillBoardPartial(board);
  }

  bool _fillBoardPartial(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_random);
          for (int num in numbers) {
            if (_isValidInBoard(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoardPartial(board)) {
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

  bool _isValidInBoard(List<List<int>> board, int row, int col, int num) {
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

  /// 특정 보드에서 입력이 유효한지 검사
  static bool isValidMove(List<List<int>> board, int row, int col, int num) {
    if (num == 0) return true;

    for (int i = 0; i < 9; i++) {
      if (i != col && board[row][i] == num) return false;
    }

    for (int i = 0; i < 9; i++) {
      if (i != row && board[i][col] == num) return false;
    }

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

  /// 모든 보드가 완성되었는지 검사
  static bool areAllBoardsComplete(List<List<List<int>>> boards) {
    for (var board in boards) {
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (board[row][col] == 0) return false;
          if (!isValidMove(board, row, col, board[row][col])) return false;
        }
      }
    }
    return true;
  }
}
