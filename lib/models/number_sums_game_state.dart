import 'number_sums_generator.dart';

/// Isolate에서 실행할 퍼즐 생성 함수 (top-level 함수)
Map<String, dynamic> generateNumberSumsPuzzleInIsolate(NumberSumsDifficulty difficulty) {
  final generator = NumberSumsGenerator();
  return generator.generatePuzzle(difficulty);
}

/// Undo를 위한 동작 기록
class NumberSumsUndoAction {
  final int row;
  final int col;
  final int previousValue;
  final Set<int> previousNotes;
  final Map<String, Set<int>> affectedCellsNotes;

  NumberSumsUndoAction({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.previousNotes,
    this.affectedCellsNotes = const {},
  });

  static String cellKey(int row, int col) => '${row}_$col';

  static (int, int) parseKey(String key) {
    final parts = key.split('_');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}

class NumberSumsGameState {
  final List<List<int>> solution;
  final List<List<int>> puzzle;
  final List<List<int>> currentBoard;
  final List<List<int>> cellTypes; // 0 = blocked, 1 = input
  final List<List<Set<int>>> notes;
  final List<NumberSumsClue> clues;
  final int gridSize;
  final NumberSumsDifficulty difficulty;
  int? selectedRow;
  int? selectedCol;
  int? quickInputNumber;
  int mistakes;
  bool isCompleted;
  int elapsedSeconds;
  int failureCount;
  final List<NumberSumsUndoAction> _undoHistory;
  static const int maxUndoCount = 10;

  NumberSumsGameState({
    required this.solution,
    required this.puzzle,
    required this.currentBoard,
    required this.cellTypes,
    required this.notes,
    required this.clues,
    required this.gridSize,
    required this.difficulty,
    this.selectedRow,
    this.selectedCol,
    this.quickInputNumber,
    this.mistakes = 0,
    this.isCompleted = false,
    this.elapsedSeconds = 0,
    this.failureCount = 0,
    List<NumberSumsUndoAction>? undoHistory,
  }) : _undoHistory = undoHistory ?? [];

  /// 생성된 데이터로부터 GameState 생성
  factory NumberSumsGameState.fromGeneratedData(Map<String, dynamic> data) {
    final gridSize = data['gridSize'] as int;
    final solution = (data['solution'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final puzzle = (data['puzzle'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final cellTypes = (data['cellTypes'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final clues = (data['clues'] as List)
        .map((c) => NumberSumsClue.fromJson(c as Map<String, dynamic>))
        .toList();
    final difficulty = NumberSumsDifficulty.values[data['difficulty'] as int];

    final currentBoard = puzzle.map((row) => List<int>.from(row)).toList();
    final notes = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => <int>{}),
    );

    return NumberSumsGameState(
      solution: solution,
      puzzle: puzzle,
      currentBoard: currentBoard,
      cellTypes: cellTypes,
      notes: notes,
      clues: clues,
      gridSize: gridSize,
      difficulty: difficulty,
    );
  }

  NumberSumsGameState copyWith({
    List<List<int>>? solution,
    List<List<int>>? puzzle,
    List<List<int>>? currentBoard,
    List<List<int>>? cellTypes,
    List<List<Set<int>>>? notes,
    List<NumberSumsClue>? clues,
    int? gridSize,
    NumberSumsDifficulty? difficulty,
    int? selectedRow,
    int? selectedCol,
    int? quickInputNumber,
    int? mistakes,
    bool? isCompleted,
    int? elapsedSeconds,
    int? failureCount,
    bool clearSelection = false,
    bool clearQuickInput = false,
  }) {
    return NumberSumsGameState(
      solution: solution ?? this.solution,
      puzzle: puzzle ?? this.puzzle,
      currentBoard: currentBoard ?? this.currentBoard,
      cellTypes: cellTypes ?? this.cellTypes,
      notes: notes ?? this.notes,
      clues: clues ?? this.clues,
      gridSize: gridSize ?? this.gridSize,
      difficulty: difficulty ?? this.difficulty,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      quickInputNumber:
          clearQuickInput ? null : (quickInputNumber ?? this.quickInputNumber),
      mistakes: mistakes ?? this.mistakes,
      isCompleted: isCompleted ?? this.isCompleted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      failureCount: failureCount ?? this.failureCount,
      undoHistory: _undoHistory,
    );
  }

  /// Check if cell is input type
  bool isInputCell(int row, int col) {
    return cellTypes[row][col] == 1;
  }

  /// Check if cell is fixed (initial puzzle value)
  bool isFixed(int row, int col) {
    return puzzle[row][col] != 0;
  }

  /// Get clue at position (if any)
  NumberSumsClue? getClueAt(int row, int col) {
    for (var clue in clues) {
      if (clue.row == row && clue.col == col) return clue;
    }
    return null;
  }

  /// Get horizontal run info for a cell
  (int startCol, int endCol) getHorizontalRun(int row, int col) {
    int startCol = col;
    while (startCol > 0 && cellTypes[row][startCol - 1] == 1) {
      startCol--;
    }
    int endCol = col;
    while (endCol < gridSize - 1 && cellTypes[row][endCol + 1] == 1) {
      endCol++;
    }
    return (startCol, endCol);
  }

  /// Get vertical run info for a cell
  (int startRow, int endRow) getVerticalRun(int row, int col) {
    int startRow = row;
    while (startRow > 0 && cellTypes[startRow - 1][col] == 1) {
      startRow--;
    }
    int endRow = row;
    while (endRow < gridSize - 1 && cellTypes[endRow + 1][col] == 1) {
      endRow++;
    }
    return (startRow, endRow);
  }

  /// Check if a value creates an error in horizontal or vertical run
  bool hasError(int row, int col) {
    int value = currentBoard[row][col];
    if (value == 0) return false;
    if (cellTypes[row][col] != 1) return false;

    // Check against solution
    if (value != solution[row][col]) {
      return true;
    }

    // Check horizontal run for duplicates
    final (hStart, hEnd) = getHorizontalRun(row, col);
    for (int c = hStart; c <= hEnd; c++) {
      if (c != col && currentBoard[row][c] == value) return true;
    }

    // Check vertical run for duplicates
    final (vStart, vEnd) = getVerticalRun(row, col);
    for (int r = vStart; r <= vEnd; r++) {
      if (r != row && currentBoard[r][col] == value) return true;
    }

    return false;
  }

  /// Check if cell is in the same run as selected cell
  bool isSameRun(int row, int col) {
    if (selectedRow == null || selectedCol == null) return false;
    if (cellTypes[row][col] != 1) return false;

    // Check horizontal run
    if (row == selectedRow) {
      final (hStart, hEnd) = getHorizontalRun(selectedRow!, selectedCol!);
      if (col >= hStart && col <= hEnd) return true;
    }

    // Check vertical run
    if (col == selectedCol) {
      final (vStart, vEnd) = getVerticalRun(selectedRow!, selectedCol!);
      if (row >= vStart && row <= vEnd) return true;
    }

    return false;
  }

  /// Check if the run containing a cell has a sum error
  bool hasRunSumError(int row, int col) {
    if (cellTypes[row][col] != 1) return false;

    // Check horizontal run
    final (hStart, hEnd) = getHorizontalRun(row, col);
    int clueCol = hStart - 1;
    if (clueCol >= 0) {
      var clue = getClueAt(row, clueCol);
      if (clue != null && clue.rightSum != null) {
        int sum = 0;
        bool allFilled = true;
        for (int c = hStart; c <= hEnd; c++) {
          if (currentBoard[row][c] == 0) {
            allFilled = false;
          } else {
            sum += currentBoard[row][c];
          }
        }
        if (allFilled && sum != clue.rightSum) return true;
        if (sum > clue.rightSum!) return true;
      }
    }

    // Check vertical run
    final (vStart, vEnd) = getVerticalRun(row, col);
    int clueRow = vStart - 1;
    if (clueRow >= 0) {
      var clue = getClueAt(clueRow, col);
      if (clue != null && clue.downSum != null) {
        int sum = 0;
        bool allFilled = true;
        for (int r = vStart; r <= vEnd; r++) {
          if (currentBoard[r][col] == 0) {
            allFilled = false;
          } else {
            sum += currentBoard[r][col];
          }
        }
        if (allFilled && sum != clue.downSum) return true;
        if (sum > clue.downSum!) return true;
      }
    }

    return false;
  }

  /// 메모 토글
  void toggleNote(int row, int col, int number) {
    if (currentBoard[row][col] != 0) return;
    if (cellTypes[row][col] != 1) return;

    if (notes[row][col].contains(number)) {
      notes[row][col].remove(number);
    } else {
      notes[row][col].add(number);
    }
  }

  /// 같은 런의 메모에서 해당 숫자 삭제
  void removeNumberFromRelatedNotes(int row, int col, int number) {
    // 같은 수평 런의 메모에서 삭제
    final (hStart, hEnd) = getHorizontalRun(row, col);
    for (int c = hStart; c <= hEnd; c++) {
      if (c != col) {
        notes[row][c].remove(number);
      }
    }

    // 같은 수직 런의 메모에서 삭제
    final (vStart, vEnd) = getVerticalRun(row, col);
    for (int r = vStart; r <= vEnd; r++) {
      if (r != row) {
        notes[r][col].remove(number);
      }
    }
  }

  /// 셀의 메모 지우기
  void clearNotes(int row, int col) {
    notes[row][col].clear();
  }

  /// 현재 상태를 Undo 히스토리에 저장
  void saveToUndoHistory(int row, int col, {int? numberToInput}) {
    Map<String, Set<int>> affectedNotes = {};

    if (numberToInput != null && numberToInput != 0) {
      // 같은 수평 런
      final (hStart, hEnd) = getHorizontalRun(row, col);
      for (int c = hStart; c <= hEnd; c++) {
        if (c != col && notes[row][c].contains(numberToInput)) {
          affectedNotes[NumberSumsUndoAction.cellKey(row, c)] =
              Set<int>.from(notes[row][c]);
        }
      }

      // 같은 수직 런
      final (vStart, vEnd) = getVerticalRun(row, col);
      for (int r = vStart; r <= vEnd; r++) {
        if (r != row && notes[r][col].contains(numberToInput)) {
          affectedNotes[NumberSumsUndoAction.cellKey(r, col)] =
              Set<int>.from(notes[r][col]);
        }
      }
    }

    final action = NumberSumsUndoAction(
      row: row,
      col: col,
      previousValue: currentBoard[row][col],
      previousNotes: Set<int>.from(notes[row][col]),
      affectedCellsNotes: affectedNotes,
    );
    _undoHistory.add(action);
    if (_undoHistory.length > maxUndoCount) {
      _undoHistory.removeAt(0);
    }
  }

  /// Undo 실행
  bool undo() {
    if (_undoHistory.isEmpty) return false;

    final action = _undoHistory.removeLast();
    currentBoard[action.row][action.col] = action.previousValue;
    notes[action.row][action.col] = Set<int>.from(action.previousNotes);

    for (final entry in action.affectedCellsNotes.entries) {
      final (r, c) = NumberSumsUndoAction.parseKey(entry.key);
      notes[r][c] = Set<int>.from(entry.value);
    }
    return true;
  }

  bool get canUndo => _undoHistory.isNotEmpty;
  int get undoCount => _undoHistory.length;

  void clearUndoHistory() {
    _undoHistory.clear();
  }

  /// 모든 빈 셀에 메모 자동 채우기
  void fillAllNotes() {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (cellTypes[row][col] == 1 && currentBoard[row][col] == 0) {
          final Set<int> newNotes = <int>{};
          for (int num = 1; num <= 9; num++) {
            if (_isValidCandidate(row, col, num)) {
              newNotes.add(num);
            }
          }
          notes[row][col] = newNotes;
        }
      }
    }
  }

  /// Check if a number is a valid candidate
  bool _isValidCandidate(int row, int col, int num) {
    return NumberSumsGenerator.isValidMove(
      currentBoard,
      cellTypes,
      clues,
      row,
      col,
      num,
      gridSize,
    );
  }

  bool get isQuickInputMode => quickInputNumber != null;
  bool get hasSelection => selectedRow != null && selectedCol != null;

  int? get selectedValue {
    if (!hasSelection) return null;
    return currentBoard[selectedRow!][selectedCol!];
  }

  bool isSelected(int row, int col) {
    return selectedRow == row && selectedCol == col;
  }

  bool isSameValue(int row, int col) {
    if (!hasSelection) return false;
    int cellValue = currentBoard[row][col];
    return cellValue != 0 && cellValue == selectedValue;
  }

  /// 각 숫자가 보드에서 몇 번 사용되었는지 카운트
  Map<int, int> getNumberCounts() {
    final counts = <int, int>{};
    for (int num = 1; num <= 9; num++) {
      counts[num] = 0;
    }

    // Count total input cells
    int totalInputCells = 0;
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (cellTypes[row][col] == 1) {
          totalInputCells++;
          int value = currentBoard[row][col];
          if (value != 0) {
            counts[value] = (counts[value] ?? 0) + 1;
          }
        }
      }
    }

    return counts;
  }

  /// 완성된 숫자들 (이 게임에서는 항상 빈 set 반환 - 숫자 제한 없음)
  Set<int> getCompletedNumbers() {
    return <int>{};
  }
}
