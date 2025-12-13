import 'dart:math';

enum NumberSumsDifficulty { easy, medium, hard }

/// Represents a clue cell in the Number Sums puzzle
class NumberSumsClue {
  final int row;
  final int col;
  final int? downSum;
  final int? rightSum;
  final int? downLength;
  final int? rightLength;

  NumberSumsClue({
    required this.row,
    required this.col,
    this.downSum,
    this.rightSum,
    this.downLength,
    this.rightLength,
  });

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'downSum': downSum,
    'rightSum': rightSum,
    'downLength': downLength,
    'rightLength': rightLength,
  };

  factory NumberSumsClue.fromJson(Map<String, dynamic> json) {
    return NumberSumsClue(
      row: json['row'] as int,
      col: json['col'] as int,
      downSum: json['downSum'] as int?,
      rightSum: json['rightSum'] as int?,
      downLength: json['downLength'] as int?,
      rightLength: json['rightLength'] as int?,
    );
  }
}

class NumberSumsGenerator {
  final Random _random = Random();

  Map<String, dynamic> generatePuzzle(NumberSumsDifficulty difficulty) {
    int gridSize;
    double wrongRatio;

    switch (difficulty) {
      case NumberSumsDifficulty.easy:
        gridSize = 6;
        wrongRatio = 0.25;
        break;
      case NumberSumsDifficulty.medium:
        gridSize = 8;
        wrongRatio = 0.30;
        break;
      case NumberSumsDifficulty.hard:
        gridSize = 10;
        wrongRatio = 0.35;
        break;
    }

    return _generateEliminationPuzzle(gridSize, difficulty, wrongRatio);
  }

  Map<String, dynamic> _generateEliminationPuzzle(int size, NumberSumsDifficulty difficulty, double wrongRatio) {
    // cellTypes: 0 = clue/blocked, 1 = input
    List<List<int>> cellTypes = List.generate(size, (_) => List.filled(size, 0));
    List<List<int>> solution = List.generate(size, (_) => List.filled(size, 0));
    List<NumberSumsClue> clues = [];

    // Create a pattern of white cells
    _createPattern(cellTypes, size, difficulty);

    // Fill solution with valid numbers
    _fillSolution(cellTypes, solution, size);

    // Generate clues based on the solution
    clues = _generateClues(cellTypes, solution, size);

    // Create puzzle with wrong numbers (틀린 숫자가 섞인 퍼즐)
    final inputCells = <(int, int)>[];
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (cellTypes[row][col] == 1) {
          inputCells.add((row, col));
        }
      }
    }

    // 틀린 숫자 셀 결정
    int wrongCount = (inputCells.length * wrongRatio).round();
    wrongCount = max(wrongCount, 2);

    inputCells.shuffle(_random);
    List<List<bool>> wrongCells = List.generate(size, (_) => List.filled(size, false));

    // 퍼즐 보드 = 정답 복사 후 틀린 숫자 삽입
    List<List<int>> puzzle = solution.map((row) => List<int>.from(row)).toList();

    int addedWrong = 0;
    for (final (row, col) in inputCells) {
      if (addedWrong >= wrongCount) break;

      int correctValue = solution[row][col];

      // 다른 숫자로 교체
      List<int> wrongOptions = [];
      for (int n = 1; n <= 9; n++) {
        if (n != correctValue) wrongOptions.add(n);
      }
      wrongOptions.shuffle(_random);

      puzzle[row][col] = wrongOptions.first;
      wrongCells[row][col] = true;
      addedWrong++;
    }

    return {
      'solution': solution,
      'puzzle': puzzle,
      'cellTypes': cellTypes,
      'clues': clues.map((c) => c.toJson()).toList(),
      'wrongCells': wrongCells.map((row) => row.map((v) => v ? 1 : 0).toList()).toList(),
      'gridSize': size,
      'difficulty': difficulty.index,
    };
  }

  void _createPattern(List<List<int>> cellTypes, int size, NumberSumsDifficulty difficulty) {
    // First row and column are always clue cells
    for (int i = 0; i < size; i++) {
      cellTypes[0][i] = 0;
      cellTypes[i][0] = 0;
    }

    int minRun = 2;
    int maxRun;

    switch (difficulty) {
      case NumberSumsDifficulty.easy:
        maxRun = 4;
        break;
      case NumberSumsDifficulty.medium:
        maxRun = 5;
        break;
      case NumberSumsDifficulty.hard:
        maxRun = 6;
        break;
    }

    // Create horizontal runs
    for (int row = 1; row < size; row++) {
      int col = 1;
      while (col < size) {
        int remaining = size - col;
        if (remaining < minRun) {
          col = size;
          continue;
        }

        int runLength = minRun + _random.nextInt(min(maxRun - minRun + 1, remaining - minRun + 1));
        runLength = min(runLength, min(9, remaining));

        // Mark cells as input
        for (int i = 0; i < runLength; i++) {
          cellTypes[row][col + i] = 1;
        }

        col += runLength;

        // Add gap if there's enough space for another run
        if (col < size - minRun) {
          cellTypes[row][col] = 0;
          col++;
        } else {
          col = size;
        }
      }
    }

    // Ensure vertical runs are valid (at least minRun length)
    for (int col = 1; col < size; col++) {
      int runStart = -1;
      for (int row = 1; row <= size; row++) {
        if (row < size && cellTypes[row][col] == 1) {
          if (runStart == -1) runStart = row;
        } else {
          if (runStart != -1) {
            int runLength = row - runStart;
            if (runLength == 1) {
              // Single cell run - try to extend or remove
              if (runStart > 1 && cellTypes[runStart - 1][col] == 0) {
                // Check if we can extend up
                bool canExtend = false;
                if (runStart > 1) {
                  int checkRow = runStart - 1;
                  if (cellTypes[checkRow][col] == 0) {
                    // Check horizontal context
                    bool hasHorizontalRun = false;
                    for (int c = col - 1; c >= 0; c--) {
                      if (cellTypes[checkRow][c] == 1) {
                        hasHorizontalRun = true;
                        break;
                      }
                      if (cellTypes[checkRow][c] == 0) break;
                    }
                    if (!hasHorizontalRun) canExtend = true;
                  }
                }
                if (!canExtend) {
                  cellTypes[runStart][col] = 0;
                }
              } else {
                cellTypes[runStart][col] = 0;
              }
            }
            runStart = -1;
          }
        }
      }
    }
  }

  void _fillSolution(List<List<int>> cellTypes, List<List<int>> solution, int size) {
    // Use backtracking to fill valid numbers
    _backtrackFill(cellTypes, solution, size, 1, 1);
  }

  bool _backtrackFill(List<List<int>> cellTypes, List<List<int>> solution, int size, int row, int col) {
    if (row >= size) return true;

    int nextRow = col + 1 >= size ? row + 1 : row;
    int nextCol = col + 1 >= size ? 1 : col + 1;

    if (cellTypes[row][col] != 1) {
      return _backtrackFill(cellTypes, solution, size, nextRow, nextCol);
    }

    List<int> candidates = _getCandidates(cellTypes, solution, size, row, col);
    candidates.shuffle(_random);

    for (int num in candidates) {
      solution[row][col] = num;
      if (_backtrackFill(cellTypes, solution, size, nextRow, nextCol)) {
        return true;
      }
      solution[row][col] = 0;
    }

    return false;
  }

  List<int> _getCandidates(List<List<int>> cellTypes, List<List<int>> solution, int size, int row, int col) {
    Set<int> used = {};

    // Check horizontal run
    int hStart = col;
    while (hStart > 0 && cellTypes[row][hStart - 1] == 1) hStart--;
    int hEnd = col;
    while (hEnd < size - 1 && cellTypes[row][hEnd + 1] == 1) hEnd++;

    for (int c = hStart; c <= hEnd; c++) {
      if (solution[row][c] != 0) used.add(solution[row][c]);
    }

    // Check vertical run
    int vStart = row;
    while (vStart > 0 && cellTypes[vStart - 1][col] == 1) vStart--;
    int vEnd = row;
    while (vEnd < size - 1 && cellTypes[vEnd + 1][col] == 1) vEnd++;

    for (int r = vStart; r <= vEnd; r++) {
      if (solution[r][col] != 0) used.add(solution[r][col]);
    }

    return [1, 2, 3, 4, 5, 6, 7, 8, 9].where((n) => !used.contains(n)).toList();
  }

  List<NumberSumsClue> _generateClues(List<List<int>> cellTypes, List<List<int>> solution, int size) {
    Map<String, NumberSumsClue> clueMap = {};

    // Generate horizontal clues
    for (int row = 1; row < size; row++) {
      int col = 1;
      while (col < size) {
        if (cellTypes[row][col] == 1) {
          int startCol = col;
          int sum = 0;
          int length = 0;

          while (col < size && cellTypes[row][col] == 1) {
            sum += solution[row][col];
            length++;
            col++;
          }

          if (length >= 2) {
            int clueCol = startCol - 1;
            String key = '${row}_$clueCol';

            if (clueMap.containsKey(key)) {
              var existing = clueMap[key]!;
              clueMap[key] = NumberSumsClue(
                row: row,
                col: clueCol,
                downSum: existing.downSum,
                rightSum: sum,
                downLength: existing.downLength,
                rightLength: length,
              );
            } else {
              clueMap[key] = NumberSumsClue(
                row: row,
                col: clueCol,
                rightSum: sum,
                rightLength: length,
              );
            }
          }
        } else {
          col++;
        }
      }
    }

    // Generate vertical clues
    for (int col = 1; col < size; col++) {
      int row = 1;
      while (row < size) {
        if (cellTypes[row][col] == 1) {
          int startRow = row;
          int sum = 0;
          int length = 0;

          while (row < size && cellTypes[row][col] == 1) {
            sum += solution[row][col];
            length++;
            row++;
          }

          if (length >= 2) {
            int clueRow = startRow - 1;
            String key = '${clueRow}_$col';

            if (clueMap.containsKey(key)) {
              var existing = clueMap[key]!;
              clueMap[key] = NumberSumsClue(
                row: clueRow,
                col: col,
                downSum: sum,
                rightSum: existing.rightSum,
                downLength: length,
                rightLength: existing.rightLength,
              );
            } else {
              clueMap[key] = NumberSumsClue(
                row: clueRow,
                col: col,
                downSum: sum,
                downLength: length,
              );
            }
          }
        } else {
          row++;
        }
      }
    }

    return clueMap.values.toList();
  }

  /// 보드가 완성되었는지 확인 (모든 틀린 숫자 제거됨)
  static bool isBoardComplete(
    List<List<int>> currentBoard,
    List<List<int>> solution,
    List<List<int>> cellTypes,
    int gridSize,
  ) {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (cellTypes[row][col] == 1) {
          if (currentBoard[row][col] != solution[row][col]) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// 구버전 호환용
  static bool isValidMove(
    List<List<int>> board,
    List<List<int>> cellTypes,
    List<NumberSumsClue> clues,
    int row,
    int col,
    int number,
    int gridSize,
  ) {
    return true;
  }
}
