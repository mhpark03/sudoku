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

    int cellsToRemove = difficulty.clamp(25, 72);

    // 각 3x3 박스당 제거할 셀 수 계산 (9개 박스에 균등 분배)
    int cellsPerBox = cellsToRemove ~/ 9;
    int extraCells = cellsToRemove % 9;

    // 난이도에 따른 최소 유지 셀 수
    // 쉬움(30): 5개, 보통(45): 4개, 어려움(60): 2개, 달인(75): 1개
    int minCellsToKeep;
    if (cellsToRemove >= 75) {
      minCellsToKeep = 1; // 달인
    } else if (cellsToRemove >= 60) {
      minCellsToKeep = 2; // 어려움
    } else if (cellsToRemove >= 45) {
      minCellsToKeep = 4; // 보통
    } else {
      minCellsToKeep = 5; // 쉬움
    }
    int maxRemovePerBox = 9 - minCellsToKeep;

    // 1단계: 코너 보드들(0, 1, 3, 4)의 퍼즐 생성
    for (int b in [0, 1, 3, 4]) {
      _generateBoardPuzzle(puzzles, b, cellsPerBox, extraCells, maxRemovePerBox);
    }

    // 2단계: 보드 2(중앙) 초기화 - 모든 셀을 0으로
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        puzzles[2][row][col] = 0;
      }
    }

    // 3단계: 코너 보드들의 겹치는 영역을 보드 2로 복사
    _copyOverlapToCenter(puzzles);

    // 4단계: 보드 2의 비겹침 영역(중앙 5개 박스) 퍼즐 생성
    _generateCenterNonOverlapPuzzle(
        puzzles, solvedBoards, cellsPerBox, extraCells, maxRemovePerBox);

    // 5단계: 모든 박스가 최소 셀 수를 만족하는지 확인
    _ensureMinCellsPerBox(puzzles, solvedBoards, minCellsToKeep);

    return puzzles;
  }

  /// 단일 보드의 퍼즐 생성
  void _generateBoardPuzzle(
    List<List<List<int>>> puzzles,
    int boardIndex,
    int cellsPerBox,
    int extraCells,
    int maxRemovePerBox,
  ) {
    List<int> boxOrder = List.generate(9, (i) => i)..shuffle(_random);

    for (int boxIdx = 0; boxIdx < 9; boxIdx++) {
      int boxNum = boxOrder[boxIdx];
      int boxStartRow = (boxNum ~/ 3) * 3;
      int boxStartCol = (boxNum % 3) * 3;

      List<int> boxPositions = [];
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          boxPositions.add((boxStartRow + r) * 9 + (boxStartCol + c));
        }
      }
      boxPositions.shuffle(_random);

      int toRemoveInBox = cellsPerBox + (boxIdx < extraCells ? 1 : 0);
      toRemoveInBox = toRemoveInBox.clamp(0, maxRemovePerBox);
      int removed = 0;

      for (int pos in boxPositions) {
        if (removed >= toRemoveInBox) break;
        int row = pos ~/ 9;
        int col = pos % 9;
        puzzles[boardIndex][row][col] = 0;
        removed++;
      }
    }
  }

  /// 코너 보드들의 겹치는 영역을 중앙 보드로 복사
  void _copyOverlapToCenter(List<List<List<int>>> puzzles) {
    // 보드 0 우하단 -> 보드 2 좌상단
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        puzzles[2][i][j] = puzzles[0][6 + i][6 + j];
      }
    }

    // 보드 1 좌하단 -> 보드 2 우상단
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        puzzles[2][i][6 + j] = puzzles[1][6 + i][j];
      }
    }

    // 보드 3 우상단 -> 보드 2 좌하단
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        puzzles[2][6 + i][j] = puzzles[3][i][6 + j];
      }
    }

    // 보드 4 좌상단 -> 보드 2 우하단
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        puzzles[2][6 + i][6 + j] = puzzles[4][i][j];
      }
    }
  }

  /// 보드 2의 비겹침 영역(중앙 5개 박스) 퍼즐 생성
  void _generateCenterNonOverlapPuzzle(
    List<List<List<int>>> puzzles,
    List<List<List<int>>> solutions,
    int cellsPerBox,
    int extraCells,
    int maxRemovePerBox,
  ) {
    // 비겹침 박스: 1(상단중앙), 3(중앙좌), 4(중앙), 5(중앙우), 7(하단중앙)
    // 박스 번호: 0 1 2
    //           3 4 5
    //           6 7 8
    // 겹침 박스: 0(좌상단), 2(우상단), 6(좌하단), 8(우하단)

    // 노출할 최소 셀 수 (maxRemovePerBox의 반대)
    int minCellsToReveal = 9 - maxRemovePerBox;

    // 중앙 박스(4)를 먼저 처리 - 항상 최소값+1개 이상 노출
    _revealBoxCells(puzzles, solutions, 4, minCellsToReveal + 1);

    // 나머지 박스들 처리
    List<int> otherBoxes = [1, 3, 5, 7];
    otherBoxes.shuffle(_random);
    for (int boxNum in otherBoxes) {
      int cellsToReveal = minCellsToReveal + (_random.nextInt(2));
      _revealBoxCells(puzzles, solutions, boxNum, cellsToReveal);
    }
  }

  /// 특정 박스에 지정된 수의 셀을 노출
  void _revealBoxCells(
    List<List<List<int>>> puzzles,
    List<List<List<int>>> solutions,
    int boxNum,
    int cellsToReveal,
  ) {
    int boxStartRow = (boxNum ~/ 3) * 3;
    int boxStartCol = (boxNum % 3) * 3;

    // 박스 내 모든 위치를 수집
    List<List<int>> allPositions = [];
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        allPositions.add([boxStartRow + r, boxStartCol + c]);
      }
    }

    // 중앙 박스(4)인 경우, 정중앙 셀(4,4)을 항상 포함
    if (boxNum == 4) {
      // 정중앙(4,4)을 맨 앞으로 이동
      allPositions.removeWhere((pos) => pos[0] == 4 && pos[1] == 4);
      allPositions.insert(0, [4, 4]);
      // 나머지만 셔플
      List<List<int>> rest = allPositions.sublist(1);
      rest.shuffle(_random);
      allPositions = [[4, 4], ...rest];
    } else {
      allPositions.shuffle(_random);
    }

    cellsToReveal = cellsToReveal.clamp(1, 9);

    // 선택된 셀만 솔루션 값으로 설정, 나머지는 0
    for (int i = 0; i < allPositions.length; i++) {
      int row = allPositions[i][0];
      int col = allPositions[i][1];
      if (i < cellsToReveal) {
        puzzles[2][row][col] = solutions[2][row][col];
      } else {
        puzzles[2][row][col] = 0;
      }
    }
  }

  /// 모든 3x3 박스가 최소 셀 수를 가지도록 보장
  void _ensureMinCellsPerBox(
    List<List<List<int>>> puzzles,
    List<List<List<int>>> solutions,
    int minCellsToKeep,
  ) {
    for (int b = 0; b < 5; b++) {
      for (int boxNum = 0; boxNum < 9; boxNum++) {
        int boxStartRow = (boxNum ~/ 3) * 3;
        int boxStartCol = (boxNum % 3) * 3;

        // 현재 박스의 노출된 셀 수 계산
        int revealedCount = 0;
        List<List<int>> emptyPositions = [];

        for (int r = 0; r < 3; r++) {
          for (int c = 0; c < 3; c++) {
            int row = boxStartRow + r;
            int col = boxStartCol + c;
            if (puzzles[b][row][col] != 0) {
              revealedCount++;
            } else {
              emptyPositions.add([row, col]);
            }
          }
        }

        // 최소 셀 수보다 적으면 솔루션에서 복원
        while (revealedCount < minCellsToKeep && emptyPositions.isNotEmpty) {
          emptyPositions.shuffle(_random);
          List<int> pos = emptyPositions.removeLast();
          int row = pos[0];
          int col = pos[1];

          // 솔루션 값으로 복원
          puzzles[b][row][col] = solutions[b][row][col];
          revealedCount++;

          // 겹치는 영역이면 다른 보드에도 동기화
          _syncRestoredCell(puzzles, b, row, col, solutions[b][row][col]);
        }
      }
    }
  }

  /// 복원된 셀을 겹치는 보드에 동기화
  void _syncRestoredCell(
    List<List<List<int>>> puzzles,
    int board,
    int row,
    int col,
    int value,
  ) {
    // 보드 0 우하단 <-> 보드 2 좌상단
    if (board == 0 && row >= 6 && col >= 6) {
      puzzles[2][row - 6][col - 6] = value;
    } else if (board == 2 && row < 3 && col < 3) {
      puzzles[0][row + 6][col + 6] = value;
    }

    // 보드 1 좌하단 <-> 보드 2 우상단
    if (board == 1 && row >= 6 && col < 3) {
      puzzles[2][row - 6][col + 6] = value;
    } else if (board == 2 && row < 3 && col >= 6) {
      puzzles[1][row + 6][col - 6] = value;
    }

    // 보드 2 좌하단 <-> 보드 3 우상단
    if (board == 2 && row >= 6 && col < 3) {
      puzzles[3][row - 6][col + 6] = value;
    } else if (board == 3 && row < 3 && col >= 6) {
      puzzles[2][row + 6][col - 6] = value;
    }

    // 보드 2 우하단 <-> 보드 4 좌상단
    if (board == 2 && row >= 6 && col >= 6) {
      puzzles[4][row - 6][col - 6] = value;
    } else if (board == 4 && row < 3 && col < 3) {
      puzzles[2][row + 6][col + 6] = value;
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
