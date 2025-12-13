import 'dart:math';

enum NumberSumsDifficulty { easy, medium, hard }

/// Represents a clue cell in the Number Sums puzzle
/// A clue cell has a down sum (for the column below) and/or right sum (for the row to the right)
class NumberSumsClue {
  final int row;
  final int col;
  final int? downSum;  // Sum for cells below this clue
  final int? rightSum; // Sum for cells to the right of this clue

  NumberSumsClue({
    required this.row,
    required this.col,
    this.downSum,
    this.rightSum,
  });

  Map<String, dynamic> toJson() => {
    'row': row,
    'col': col,
    'downSum': downSum,
    'rightSum': rightSum,
  };

  factory NumberSumsClue.fromJson(Map<String, dynamic> json) {
    return NumberSumsClue(
      row: json['row'] as int,
      col: json['col'] as int,
      downSum: json['downSum'] as int?,
      rightSum: json['rightSum'] as int?,
    );
  }
}

/// Cell type in Number Sums puzzle
enum CellType {
  blocked,  // Black cell (no input)
  clue,     // Clue cell with sums
  input,    // White cell for user input
}

class NumberSumsGenerator {
  final Random _random = Random();

  /// Generate a Number Sums puzzle
  Map<String, dynamic> generatePuzzle(NumberSumsDifficulty difficulty) {
    int gridSize;
    int minRunLength, maxRunLength;

    switch (difficulty) {
      case NumberSumsDifficulty.easy:
        gridSize = 6;
        minRunLength = 2;
        maxRunLength = 3;
        break;
      case NumberSumsDifficulty.medium:
        gridSize = 8;
        minRunLength = 2;
        maxRunLength = 4;
        break;
      case NumberSumsDifficulty.hard:
        gridSize = 10;
        minRunLength = 2;
        maxRunLength = 5;
        break;
    }

    // Generate a valid puzzle
    return _generateValidPuzzle(gridSize, minRunLength, maxRunLength, difficulty);
  }

  Map<String, dynamic> _generateValidPuzzle(
    int size,
    int minRunLength,
    int maxRunLength,
    NumberSumsDifficulty difficulty,
  ) {
    // Cell types: 0 = blocked, 1 = input
    List<List<int>> cellTypes = List.generate(size, (_) => List.filled(size, 0));
    List<List<int>> solution = List.generate(size, (_) => List.filled(size, 0));
    List<NumberSumsClue> clues = [];

    // First row and column are always blocked/clue cells
    for (int i = 0; i < size; i++) {
      cellTypes[0][i] = 0;
      cellTypes[i][0] = 0;
    }

    // Generate horizontal runs with solutions
    List<_Run> horizontalRuns = [];
    for (int row = 1; row < size; row++) {
      int col = 1;
      while (col < size) {
        // Decide run length
        int remainingCols = size - col;
        if (remainingCols < minRunLength) {
          col = size;
          continue;
        }

        int maxLen = min(maxRunLength, min(9, remainingCols));
        int runLength = minRunLength + _random.nextInt(maxLen - minRunLength + 1);
        runLength = min(runLength, remainingCols);

        // Generate unique digits for this run
        List<int> digits = _generateUniqueDigits(runLength);

        // Place the run
        _Run run = _Run(row: row, startCol: col, length: runLength, isHorizontal: true);
        horizontalRuns.add(run);

        for (int i = 0; i < runLength; i++) {
          cellTypes[row][col + i] = 1;
          solution[row][col + i] = digits[i];
        }

        col += runLength;

        // Add a gap (blocked cell) before next run if there's space
        if (col < size) {
          cellTypes[row][col] = 0;
          col++;
        }
      }
    }

    // Now we need to create vertical consistency
    // For each column, identify vertical runs and ensure they have valid sums
    List<_Run> verticalRuns = [];
    for (int col = 1; col < size; col++) {
      int row = 1;
      while (row < size) {
        if (cellTypes[row][col] == 1) {
          // Start of a vertical run
          int startRow = row;
          while (row < size && cellTypes[row][col] == 1) {
            row++;
          }
          int length = row - startRow;

          if (length >= minRunLength) {
            // Check if values in this column are unique
            Set<int> values = {};
            bool hasDuplicate = false;
            for (int r = startRow; r < startRow + length; r++) {
              if (values.contains(solution[r][col])) {
                hasDuplicate = true;
                break;
              }
              values.add(solution[r][col]);
            }

            if (hasDuplicate) {
              // Regenerate values for this vertical run
              List<int> newDigits = _generateUniqueDigits(length);
              for (int i = 0; i < length; i++) {
                solution[startRow + i][col] = newDigits[i];
              }
            }

            verticalRuns.add(_Run(row: startRow, startCol: col, length: length, isHorizontal: false));
          }
        } else {
          row++;
        }
      }
    }

    // Validate and fix horizontal runs after vertical adjustments
    for (var run in horizontalRuns) {
      Set<int> values = {};
      bool hasDuplicate = false;
      for (int i = 0; i < run.length; i++) {
        int val = solution[run.row][run.startCol + i];
        if (values.contains(val)) {
          hasDuplicate = true;
          break;
        }
        values.add(val);
      }

      if (hasDuplicate) {
        List<int> newDigits = _generateUniqueDigits(run.length);
        for (int i = 0; i < run.length; i++) {
          solution[run.row][run.startCol + i] = newDigits[i];
        }
      }
    }

    // Create clue cells
    // For each horizontal run, add clue to the left
    for (var run in horizontalRuns) {
      int sum = 0;
      for (int i = 0; i < run.length; i++) {
        sum += solution[run.row][run.startCol + i];
      }

      // Find or create clue cell
      int clueCol = run.startCol - 1;
      int existingIdx = clues.indexWhere((c) => c.row == run.row && c.col == clueCol);

      if (existingIdx >= 0) {
        // Update existing clue with right sum
        var existing = clues[existingIdx];
        clues[existingIdx] = NumberSumsClue(
          row: existing.row,
          col: existing.col,
          downSum: existing.downSum,
          rightSum: sum,
        );
      } else {
        clues.add(NumberSumsClue(
          row: run.row,
          col: clueCol,
          rightSum: sum,
        ));
      }
    }

    // For each vertical run, add clue above
    for (var run in verticalRuns) {
      int sum = 0;
      for (int i = 0; i < run.length; i++) {
        sum += solution[run.row + i][run.startCol];
      }

      // Find or create clue cell
      int clueRow = run.row - 1;
      int existingIdx = clues.indexWhere((c) => c.row == clueRow && c.col == run.startCol);

      if (existingIdx >= 0) {
        // Update existing clue with down sum
        var existing = clues[existingIdx];
        clues[existingIdx] = NumberSumsClue(
          row: existing.row,
          col: existing.col,
          downSum: sum,
          rightSum: existing.rightSum,
        );
      } else {
        clues.add(NumberSumsClue(
          row: clueRow,
          col: run.startCol,
          downSum: sum,
        ));
      }
    }

    // Create puzzle (empty input cells)
    List<List<int>> puzzle = List.generate(size, (r) =>
      List.generate(size, (c) => cellTypes[r][c] == 1 ? 0 : solution[r][c])
    );

    return {
      'solution': solution,
      'puzzle': puzzle,
      'cellTypes': cellTypes,
      'clues': clues.map((c) => c.toJson()).toList(),
      'gridSize': size,
      'difficulty': difficulty.index,
    };
  }

  /// Generate unique random digits 1-9
  List<int> _generateUniqueDigits(int count) {
    if (count > 9) count = 9;
    List<int> digits = List.generate(9, (i) => i + 1)..shuffle(_random);
    return digits.sublist(0, count);
  }

  /// Check if a move is valid (no duplicates in the same run)
  static bool isValidMove(
    List<List<int>> board,
    List<List<int>> cellTypes,
    List<NumberSumsClue> clues,
    int row,
    int col,
    int num,
    int gridSize,
  ) {
    if (num == 0) return true;
    if (cellTypes[row][col] != 1) return false;

    // Check horizontal run
    int startCol = col;
    while (startCol > 0 && cellTypes[row][startCol - 1] == 1) {
      startCol--;
    }
    int endCol = col;
    while (endCol < gridSize - 1 && cellTypes[row][endCol + 1] == 1) {
      endCol++;
    }

    for (int c = startCol; c <= endCol; c++) {
      if (c != col && board[row][c] == num) return false;
    }

    // Check vertical run
    int startRow = row;
    while (startRow > 0 && cellTypes[startRow - 1][col] == 1) {
      startRow--;
    }
    int endRow = row;
    while (endRow < gridSize - 1 && cellTypes[endRow + 1][col] == 1) {
      endRow++;
    }

    for (int r = startRow; r <= endRow; r++) {
      if (r != row && board[r][col] == num) return false;
    }

    return true;
  }

  /// Check if the board is complete and valid
  static bool isBoardComplete(
    List<List<int>> board,
    List<List<int>> cellTypes,
    List<NumberSumsClue> clues,
    int gridSize,
  ) {
    // Check all input cells are filled
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (cellTypes[row][col] == 1 && board[row][col] == 0) {
          return false;
        }
      }
    }

    // Check all clue sums
    for (var clue in clues) {
      // Check right sum
      if (clue.rightSum != null) {
        int sum = 0;
        int col = clue.col + 1;
        while (col < gridSize && cellTypes[clue.row][col] == 1) {
          sum += board[clue.row][col];
          col++;
        }
        if (sum != clue.rightSum) return false;
      }

      // Check down sum
      if (clue.downSum != null) {
        int sum = 0;
        int row = clue.row + 1;
        while (row < gridSize && cellTypes[row][clue.col] == 1) {
          sum += board[row][clue.col];
          row++;
        }
        if (sum != clue.downSum) return false;
      }
    }

    return true;
  }
}

class _Run {
  final int row;
  final int startCol;
  final int length;
  final bool isHorizontal;

  _Run({
    required this.row,
    required this.startCol,
    required this.length,
    required this.isHorizontal,
  });
}
