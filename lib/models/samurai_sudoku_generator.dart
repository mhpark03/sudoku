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

  /// 퍼즐 생성 - 21x21 그리드 기준 비율 적용
  List<List<List<int>>> generatePuzzles(
      List<List<List<int>>> solvedBoards, int difficulty) {
    // 솔루션 복사
    List<List<List<int>>> puzzles = solvedBoards
        .map((board) => board.map((row) => List<int>.from(row)).toList())
        .toList();

    // 난이도를 비율로 변환 (difficulty는 81셀 기준 제거할 셀 수)
    // revealPercentage = (81 - difficulty) / 81
    double revealPercentage = (81 - difficulty.clamp(0, 81)) / 81.0;

    // 21x21 그리드 기준 노출할 셀 수 계산
    int totalGridCells = 21 * 21; // 441
    int cellsToReveal = (totalGridCells * revealPercentage).round();

    // 모든 보드의 모든 셀을 0으로 초기화
    for (int b = 0; b < 5; b++) {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          puzzles[b][r][c] = 0;
        }
      }
    }

    // 달인이 아닌 경우, 중앙 보드의 비겹침 영역에 최소 셀 보장
    Set<int> preRevealedPositions = {};
    bool isExpert = difficulty >= 75;

    if (!isExpert) {
      // 난이도별 중앙 비겹침 박스당 최소 노출 셀 수
      int minCellsPerCenterBox;
      if (difficulty >= 60) {
        minCellsPerCenterBox = 1; // 어려움
      } else if (difficulty >= 45) {
        minCellsPerCenterBox = 2; // 보통
      } else {
        minCellsPerCenterBox = 3; // 쉬움
      }

      // 중앙 보드의 비겹침 박스들 (21x21 그리드 좌표)
      // 박스 1: grid (6-8, 9-11), 박스 3: grid (9-11, 6-8)
      // 박스 4: grid (9-11, 9-11), 박스 5: grid (9-11, 12-14)
      // 박스 7: grid (12-14, 9-11)
      List<List<int>> centerOnlyBoxes = [
        [6, 9], // 박스 1
        [9, 6], // 박스 3
        [9, 9], // 박스 4
        [9, 12], // 박스 5
        [12, 9], // 박스 7
      ];

      for (var box in centerOnlyBoxes) {
        int startRow = box[0];
        int startCol = box[1];

        // 해당 박스의 모든 셀 위치 수집
        List<int> boxPositions = [];
        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            int gridRow = startRow + r;
            int gridCol = startCol + c;
            boxPositions.add(gridRow * 21 + gridCol);
          }
        }
        boxPositions.shuffle(_random);

        // 최소 셀 수만큼 노출
        for (int i = 0; i < minCellsPerCenterBox && i < boxPositions.length; i++) {
          int pos = boxPositions[i];
          preRevealedPositions.add(pos);

          int gridRow = pos ~/ 21;
          int gridCol = pos % 21;
          // 보드 2의 좌표로 변환
          int boardRow = gridRow - 6;
          int boardCol = gridCol - 6;
          puzzles[2][boardRow][boardCol] = solvedBoards[2][boardRow][boardCol];
        }
      }
    }

    // 21x21 그리드의 모든 위치 생성 (이미 노출된 위치 제외)
    List<int> allPositions = [];
    for (int i = 0; i < totalGridCells; i++) {
      if (!preRevealedPositions.contains(i)) {
        allPositions.add(i);
      }
    }
    allPositions.shuffle(_random);

    // 남은 셀 수만큼 추가 노출
    int remainingToReveal = cellsToReveal - preRevealedPositions.length;

    for (int i = 0; i < remainingToReveal && i < allPositions.length; i++) {
      int pos = allPositions[i];
      int gridRow = pos ~/ 21;
      int gridCol = pos % 21;

      // 21x21 위치를 보드 위치로 매핑
      List<List<int>> mappings = _mapGridToBoards(gridRow, gridCol);

      // 매핑된 모든 보드에 셀 노출
      for (var mapping in mappings) {
        int board = mapping[0];
        int row = mapping[1];
        int col = mapping[2];
        puzzles[board][row][col] = solvedBoards[board][row][col];
      }
    }

    return puzzles;
  }

  /// 21x21 그리드 위치를 보드 위치로 매핑
  /// 빈 영역이면 빈 리스트 반환
  /// 겹치는 영역이면 여러 보드 위치 반환
  List<List<int>> _mapGridToBoards(int gridRow, int gridCol) {
    List<List<int>> result = [];

    // 보드 0: 그리드 (0-8, 0-8) -> 보드0 (0-8, 0-8)
    if (gridRow >= 0 && gridRow < 9 && gridCol >= 0 && gridCol < 9) {
      result.add([0, gridRow, gridCol]);
    }

    // 보드 1: 그리드 (0-8, 12-20) -> 보드1 (0-8, 0-8)
    if (gridRow >= 0 && gridRow < 9 && gridCol >= 12 && gridCol < 21) {
      result.add([1, gridRow, gridCol - 12]);
    }

    // 보드 2: 그리드 (6-14, 6-14) -> 보드2 (0-8, 0-8)
    if (gridRow >= 6 && gridRow < 15 && gridCol >= 6 && gridCol < 15) {
      result.add([2, gridRow - 6, gridCol - 6]);
    }

    // 보드 3: 그리드 (12-20, 0-8) -> 보드3 (0-8, 0-8)
    if (gridRow >= 12 && gridRow < 21 && gridCol >= 0 && gridCol < 9) {
      result.add([3, gridRow - 12, gridCol]);
    }

    // 보드 4: 그리드 (12-20, 12-20) -> 보드4 (0-8, 0-8)
    if (gridRow >= 12 && gridRow < 21 && gridCol >= 12 && gridCol < 21) {
      result.add([4, gridRow - 12, gridCol - 12]);
    }

    return result;
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
