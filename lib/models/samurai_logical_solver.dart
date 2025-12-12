/// 사무라이 스도쿠용 논리적 풀이 검증 솔버
/// 5개의 연결된 9x9 보드에서 추측(guessing) 없이 풀 수 있는지 확인
///
/// 보드 배치:
///   [0]   [1]      (상단 좌/우)
///     [2]          (중앙)
///   [3]   [4]      (하단 좌/우)
///
/// 겹치는 영역:
/// - 보드 0의 우하단 3x3 (6-8, 6-8) = 보드 2의 좌상단 3x3 (0-2, 0-2)
/// - 보드 1의 좌하단 3x3 (6-8, 0-2) = 보드 2의 우상단 3x3 (0-2, 6-8)
/// - 보드 2의 좌하단 3x3 (6-8, 0-2) = 보드 3의 우상단 3x3 (0-2, 6-8)
/// - 보드 2의 우하단 3x3 (6-8, 6-8) = 보드 4의 좌상단 3x3 (0-2, 0-2)
class SamuraiLogicalSolver {
  /// 겹치는 영역 정의: [보드1, 행시작1, 열시작1, 보드2, 행시작2, 열시작2]
  static const List<List<int>> _overlaps = [
    [0, 6, 6, 2, 0, 0], // B0 우하단 = B2 좌상단
    [1, 6, 0, 2, 0, 6], // B1 좌하단 = B2 우상단
    [2, 6, 0, 3, 0, 6], // B2 좌하단 = B3 우상단
    [2, 6, 6, 4, 0, 0], // B2 우하단 = B4 좌상단
  ];

  /// 사무라이 퍼즐이 논리적 기법만으로 풀 수 있는지 확인
  static bool canSolveLogically(List<List<List<int>>> puzzles) {
    // 퍼즐 복사
    List<List<List<int>>> boards = puzzles
        .map((board) => board.map((row) => List<int>.from(row)).toList())
        .toList();

    // 각 보드, 각 셀의 후보 숫자 초기화
    List<List<List<Set<int>>>> candidates = List.generate(
      5,
      (_) => List.generate(
        9,
        (_) => List.generate(9, (_) => <int>{}),
      ),
    );

    // 초기 후보 계산 (겹치는 영역 고려)
    for (int b = 0; b < 5; b++) {
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (boards[b][row][col] == 0) {
            candidates[b][row][col] = _getCandidates(boards, b, row, col);
          }
        }
      }
    }

    // 겹치는 영역의 후보를 동기화
    _syncOverlapCandidates(candidates);

    // 반복적으로 논리 기법 적용
    bool progress = true;
    while (progress) {
      progress = false;

      // 1. Naked Singles (유일 후보)
      for (int b = 0; b < 5; b++) {
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            if (boards[b][row][col] == 0 &&
                candidates[b][row][col].length == 1) {
              int value = candidates[b][row][col].first;
              _placeValue(boards, candidates, b, row, col, value);
              progress = true;
            }
          }
        }
      }

      // 2. Hidden Singles
      for (int b = 0; b < 5; b++) {
        // 행에서 Hidden Singles
        for (int row = 0; row < 9; row++) {
          for (int num = 1; num <= 9; num++) {
            List<int> positions = [];
            for (int col = 0; col < 9; col++) {
              if (boards[b][row][col] == 0 &&
                  candidates[b][row][col].contains(num)) {
                positions.add(col);
              }
            }
            if (positions.length == 1) {
              int col = positions[0];
              _placeValue(boards, candidates, b, row, col, num);
              progress = true;
            }
          }
        }

        // 열에서 Hidden Singles
        for (int col = 0; col < 9; col++) {
          for (int num = 1; num <= 9; num++) {
            List<int> positions = [];
            for (int row = 0; row < 9; row++) {
              if (boards[b][row][col] == 0 &&
                  candidates[b][row][col].contains(num)) {
                positions.add(row);
              }
            }
            if (positions.length == 1) {
              int row = positions[0];
              _placeValue(boards, candidates, b, row, col, num);
              progress = true;
            }
          }
        }

        // 박스에서 Hidden Singles
        for (int boxRow = 0; boxRow < 3; boxRow++) {
          for (int boxCol = 0; boxCol < 3; boxCol++) {
            for (int num = 1; num <= 9; num++) {
              List<List<int>> positions = [];
              for (int r = 0; r < 3; r++) {
                for (int c = 0; c < 3; c++) {
                  int row = boxRow * 3 + r;
                  int col = boxCol * 3 + c;
                  if (boards[b][row][col] == 0 &&
                      candidates[b][row][col].contains(num)) {
                    positions.add([row, col]);
                  }
                }
              }
              if (positions.length == 1) {
                int row = positions[0][0];
                int col = positions[0][1];
                _placeValue(boards, candidates, b, row, col, num);
                progress = true;
              }
            }
          }
        }
      }

      // 3. Pointing Pairs
      if (_applyPointingPairs(boards, candidates)) {
        progress = true;
      }

      // 4. Box-Line Reduction
      if (_applyBoxLineReduction(boards, candidates)) {
        progress = true;
      }

      // 5. Naked Pairs
      if (_applyNakedPairs(boards, candidates)) {
        progress = true;
      }

      // 모순 검사: 빈 셀인데 후보가 없으면 풀 수 없음
      for (int b = 0; b < 5; b++) {
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            if (boards[b][row][col] == 0 && candidates[b][row][col].isEmpty) {
              return false;
            }
          }
        }
      }
    }

    // 모든 셀이 채워졌는지 확인
    for (int b = 0; b < 5; b++) {
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (boards[b][row][col] == 0) {
            return false; // 아직 빈 셀이 있으면 추측이 필요함
          }
        }
      }
    }

    return true;
  }

  /// 셀에 가능한 후보 숫자 계산 (겹치는 영역 고려)
  static Set<int> _getCandidates(
      List<List<List<int>>> boards, int boardIndex, int row, int col) {
    Set<int> cands = {1, 2, 3, 4, 5, 6, 7, 8, 9};
    List<List<int>> board = boards[boardIndex];

    // 같은 행에서 제거
    for (int c = 0; c < 9; c++) {
      cands.remove(board[row][c]);
    }

    // 같은 열에서 제거
    for (int r = 0; r < 9; r++) {
      cands.remove(board[r][col]);
    }

    // 같은 박스에서 제거
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        cands.remove(board[boxRow + r][boxCol + c]);
      }
    }

    // 겹치는 영역이면 다른 보드의 제약도 적용
    var overlap = _getOverlapInfo(boardIndex, row, col);
    if (overlap != null) {
      int otherBoard = overlap[0];
      int otherRow = overlap[1];
      int otherCol = overlap[2];
      List<List<int>> other = boards[otherBoard];

      // 다른 보드의 같은 행에서 제거
      for (int c = 0; c < 9; c++) {
        cands.remove(other[otherRow][c]);
      }

      // 다른 보드의 같은 열에서 제거
      for (int r = 0; r < 9; r++) {
        cands.remove(other[r][otherCol]);
      }

      // 다른 보드의 같은 박스에서 제거
      int otherBoxRow = (otherRow ~/ 3) * 3;
      int otherBoxCol = (otherCol ~/ 3) * 3;
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          cands.remove(other[otherBoxRow + r][otherBoxCol + c]);
        }
      }
    }

    return cands;
  }

  /// 겹치는 영역인지 확인하고, 대응하는 다른 보드의 위치 반환
  /// 반환: [다른보드인덱스, 행, 열] 또는 null
  static List<int>? _getOverlapInfo(int boardIndex, int row, int col) {
    for (var overlap in _overlaps) {
      int b1 = overlap[0], r1 = overlap[1], c1 = overlap[2];
      int b2 = overlap[3], r2 = overlap[4], c2 = overlap[5];

      // 현재 셀이 b1의 겹치는 영역에 있는지
      if (boardIndex == b1 &&
          row >= r1 &&
          row < r1 + 3 &&
          col >= c1 &&
          col < c1 + 3) {
        return [b2, r2 + (row - r1), c2 + (col - c1)];
      }

      // 현재 셀이 b2의 겹치는 영역에 있는지
      if (boardIndex == b2 &&
          row >= r2 &&
          row < r2 + 3 &&
          col >= c2 &&
          col < c2 + 3) {
        return [b1, r1 + (row - r2), c1 + (col - c2)];
      }
    }
    return null;
  }

  /// 값을 배치하고 관련 셀에서 후보 제거 (겹치는 영역 동기화)
  static void _placeValue(List<List<List<int>>> boards,
      List<List<List<Set<int>>>> candidates, int b, int row, int col, int value) {
    boards[b][row][col] = value;
    candidates[b][row][col].clear();
    _eliminateFromPeers(candidates, boards, b, row, col, value);

    // 겹치는 영역이면 다른 보드에도 적용
    var overlap = _getOverlapInfo(b, row, col);
    if (overlap != null) {
      int otherBoard = overlap[0];
      int otherRow = overlap[1];
      int otherCol = overlap[2];
      boards[otherBoard][otherRow][otherCol] = value;
      candidates[otherBoard][otherRow][otherCol].clear();
      _eliminateFromPeers(
          candidates, boards, otherBoard, otherRow, otherCol, value);
    }
  }

  /// 관련 셀들에서 후보 제거 (겹치는 영역 포함)
  static void _eliminateFromPeers(List<List<List<Set<int>>>> candidates,
      List<List<List<int>>> boards, int b, int row, int col, int value) {
    // 같은 행
    for (int c = 0; c < 9; c++) {
      candidates[b][row][c].remove(value);
      // 행의 셀이 겹치는 영역이면 다른 보드에도 제거
      var overlap = _getOverlapInfo(b, row, c);
      if (overlap != null) {
        candidates[overlap[0]][overlap[1]][overlap[2]].remove(value);
      }
    }

    // 같은 열
    for (int r = 0; r < 9; r++) {
      candidates[b][r][col].remove(value);
      // 열의 셀이 겹치는 영역이면 다른 보드에도 제거
      var overlap = _getOverlapInfo(b, r, col);
      if (overlap != null) {
        candidates[overlap[0]][overlap[1]][overlap[2]].remove(value);
      }
    }

    // 같은 박스
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        candidates[b][boxRow + r][boxCol + c].remove(value);
        // 박스의 셀이 겹치는 영역이면 다른 보드에도 제거
        var overlap = _getOverlapInfo(b, boxRow + r, boxCol + c);
        if (overlap != null) {
          candidates[overlap[0]][overlap[1]][overlap[2]].remove(value);
        }
      }
    }
  }

  /// 겹치는 영역의 후보를 동기화 (교집합)
  static void _syncOverlapCandidates(List<List<List<Set<int>>>> candidates) {
    for (var overlap in _overlaps) {
      int b1 = overlap[0], r1 = overlap[1], c1 = overlap[2];
      int b2 = overlap[3], r2 = overlap[4], c2 = overlap[5];

      for (int dr = 0; dr < 3; dr++) {
        for (int dc = 0; dc < 3; dc++) {
          Set<int> cands1 = candidates[b1][r1 + dr][c1 + dc];
          Set<int> cands2 = candidates[b2][r2 + dr][c2 + dc];

          // 교집합으로 동기화
          Set<int> intersection = cands1.intersection(cands2);
          candidates[b1][r1 + dr][c1 + dc] = Set.from(intersection);
          candidates[b2][r2 + dr][c2 + dc] = Set.from(intersection);
        }
      }
    }
  }

  /// Pointing Pairs: 박스 내에서 특정 숫자가 한 행/열에만 있으면
  /// 그 행/열의 다른 박스에서 해당 숫자 제거
  static bool _applyPointingPairs(
      List<List<List<int>>> boards, List<List<List<Set<int>>>> candidates) {
    bool changed = false;

    for (int b = 0; b < 5; b++) {
      for (int boxRow = 0; boxRow < 3; boxRow++) {
        for (int boxCol = 0; boxCol < 3; boxCol++) {
          for (int num = 1; num <= 9; num++) {
            Set<int> rows = {};
            Set<int> cols = {};
            for (int r = 0; r < 3; r++) {
              for (int c = 0; c < 3; c++) {
                int row = boxRow * 3 + r;
                int col = boxCol * 3 + c;
                if (boards[b][row][col] == 0 &&
                    candidates[b][row][col].contains(num)) {
                  rows.add(row);
                  cols.add(col);
                }
              }
            }

            // 한 행에만 있으면 그 행의 다른 박스에서 제거
            if (rows.length == 1) {
              int row = rows.first;
              for (int c = 0; c < 9; c++) {
                if (c ~/ 3 != boxCol) {
                  if (candidates[b][row][c].remove(num)) {
                    changed = true;
                    // 겹치는 영역이면 다른 보드에도 제거
                    var overlap = _getOverlapInfo(b, row, c);
                    if (overlap != null) {
                      candidates[overlap[0]][overlap[1]][overlap[2]].remove(num);
                    }
                  }
                }
              }
            }

            // 한 열에만 있으면 그 열의 다른 박스에서 제거
            if (cols.length == 1) {
              int col = cols.first;
              for (int r = 0; r < 9; r++) {
                if (r ~/ 3 != boxRow) {
                  if (candidates[b][r][col].remove(num)) {
                    changed = true;
                    // 겹치는 영역이면 다른 보드에도 제거
                    var overlap = _getOverlapInfo(b, r, col);
                    if (overlap != null) {
                      candidates[overlap[0]][overlap[1]][overlap[2]].remove(num);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return changed;
  }

  /// Box-Line Reduction: 행/열에서 특정 숫자가 한 박스에만 있으면
  /// 그 박스의 다른 셀에서 해당 숫자 제거
  static bool _applyBoxLineReduction(
      List<List<List<int>>> boards, List<List<List<Set<int>>>> candidates) {
    bool changed = false;

    for (int b = 0; b < 5; b++) {
      // 행 검사
      for (int row = 0; row < 9; row++) {
        for (int num = 1; num <= 9; num++) {
          Set<int> boxes = {};
          List<int> positions = [];
          for (int col = 0; col < 9; col++) {
            if (boards[b][row][col] == 0 &&
                candidates[b][row][col].contains(num)) {
              boxes.add(col ~/ 3);
              positions.add(col);
            }
          }

          if (boxes.length == 1 && positions.isNotEmpty) {
            int boxCol = boxes.first;
            int boxRow = row ~/ 3;
            for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
              if (r != row) {
                for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
                  if (candidates[b][r][c].remove(num)) {
                    changed = true;
                    var overlap = _getOverlapInfo(b, r, c);
                    if (overlap != null) {
                      candidates[overlap[0]][overlap[1]][overlap[2]].remove(num);
                    }
                  }
                }
              }
            }
          }
        }
      }

      // 열 검사
      for (int col = 0; col < 9; col++) {
        for (int num = 1; num <= 9; num++) {
          Set<int> boxes = {};
          List<int> positions = [];
          for (int row = 0; row < 9; row++) {
            if (boards[b][row][col] == 0 &&
                candidates[b][row][col].contains(num)) {
              boxes.add(row ~/ 3);
              positions.add(row);
            }
          }

          if (boxes.length == 1 && positions.isNotEmpty) {
            int boxRow = boxes.first;
            int boxCol = col ~/ 3;
            for (int c = boxCol * 3; c < boxCol * 3 + 3; c++) {
              if (c != col) {
                for (int r = boxRow * 3; r < boxRow * 3 + 3; r++) {
                  if (candidates[b][r][c].remove(num)) {
                    changed = true;
                    var overlap = _getOverlapInfo(b, r, c);
                    if (overlap != null) {
                      candidates[overlap[0]][overlap[1]][overlap[2]].remove(num);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return changed;
  }

  /// Naked Pairs: 같은 유닛에서 두 셀이 같은 두 후보만 가지면
  /// 그 유닛의 다른 셀에서 해당 숫자들 제거
  static bool _applyNakedPairs(
      List<List<List<int>>> boards, List<List<List<Set<int>>>> candidates) {
    bool changed = false;

    for (int b = 0; b < 5; b++) {
      // 행에서 Naked Pairs
      for (int row = 0; row < 9; row++) {
        List<int> pairCells = [];
        for (int col = 0; col < 9; col++) {
          if (boards[b][row][col] == 0 && candidates[b][row][col].length == 2) {
            pairCells.add(col);
          }
        }

        for (int i = 0; i < pairCells.length; i++) {
          for (int j = i + 1; j < pairCells.length; j++) {
            int col1 = pairCells[i];
            int col2 = pairCells[j];
            if (candidates[b][row][col1]
                    .containsAll(candidates[b][row][col2]) &&
                candidates[b][row][col2]
                    .containsAll(candidates[b][row][col1])) {
              Set<int> pair = candidates[b][row][col1];
              for (int c = 0; c < 9; c++) {
                if (c != col1 && c != col2 && boards[b][row][c] == 0) {
                  for (int num in pair) {
                    if (candidates[b][row][c].remove(num)) {
                      changed = true;
                      var overlap = _getOverlapInfo(b, row, c);
                      if (overlap != null) {
                        candidates[overlap[0]][overlap[1]][overlap[2]]
                            .remove(num);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // 열에서 Naked Pairs
      for (int col = 0; col < 9; col++) {
        List<int> pairCells = [];
        for (int row = 0; row < 9; row++) {
          if (boards[b][row][col] == 0 && candidates[b][row][col].length == 2) {
            pairCells.add(row);
          }
        }

        for (int i = 0; i < pairCells.length; i++) {
          for (int j = i + 1; j < pairCells.length; j++) {
            int row1 = pairCells[i];
            int row2 = pairCells[j];
            if (candidates[b][row1][col]
                    .containsAll(candidates[b][row2][col]) &&
                candidates[b][row2][col]
                    .containsAll(candidates[b][row1][col])) {
              Set<int> pair = candidates[b][row1][col];
              for (int r = 0; r < 9; r++) {
                if (r != row1 && r != row2 && boards[b][r][col] == 0) {
                  for (int num in pair) {
                    if (candidates[b][r][col].remove(num)) {
                      changed = true;
                      var overlap = _getOverlapInfo(b, r, col);
                      if (overlap != null) {
                        candidates[overlap[0]][overlap[1]][overlap[2]]
                            .remove(num);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // 박스에서 Naked Pairs
      for (int boxRow = 0; boxRow < 3; boxRow++) {
        for (int boxCol = 0; boxCol < 3; boxCol++) {
          List<List<int>> pairCells = [];
          for (int r = 0; r < 3; r++) {
            for (int c = 0; c < 3; c++) {
              int row = boxRow * 3 + r;
              int col = boxCol * 3 + c;
              if (boards[b][row][col] == 0 &&
                  candidates[b][row][col].length == 2) {
                pairCells.add([row, col]);
              }
            }
          }

          for (int i = 0; i < pairCells.length; i++) {
            for (int j = i + 1; j < pairCells.length; j++) {
              int row1 = pairCells[i][0], col1 = pairCells[i][1];
              int row2 = pairCells[j][0], col2 = pairCells[j][1];
              if (candidates[b][row1][col1]
                      .containsAll(candidates[b][row2][col2]) &&
                  candidates[b][row2][col2]
                      .containsAll(candidates[b][row1][col1])) {
                Set<int> pair = candidates[b][row1][col1];
                for (int r = 0; r < 3; r++) {
                  for (int c = 0; c < 3; c++) {
                    int row = boxRow * 3 + r;
                    int col = boxCol * 3 + c;
                    if ((row != row1 || col != col1) &&
                        (row != row2 || col != col2) &&
                        boards[b][row][col] == 0) {
                      for (int num in pair) {
                        if (candidates[b][row][col].remove(num)) {
                          changed = true;
                          var overlap = _getOverlapInfo(b, row, col);
                          if (overlap != null) {
                            candidates[overlap[0]][overlap[1]][overlap[2]]
                                .remove(num);
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    return changed;
  }
}
