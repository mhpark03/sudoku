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

  NumberSumsUndoAction({
    required this.row,
    required this.col,
    required this.previousValue,
  });

  static String cellKey(int row, int col) => '${row}_$col';

  static (int, int) parseKey(String key) {
    final parts = key.split('_');
    return (int.parse(parts[0]), int.parse(parts[1]));
  }
}

class NumberSumsGameState {
  final List<List<int>> solution;
  final List<List<int>> puzzle; // 틀린 숫자가 포함된 초기 퍼즐
  final List<List<int>> currentBoard;
  final List<List<int>> cellTypes; // 0 = blocked, 1 = input
  final List<List<bool>> wrongCells; // 틀린 숫자 셀 표시
  final List<NumberSumsClue> clues;
  final int gridSize;
  final NumberSumsDifficulty difficulty;
  int? selectedRow;
  int? selectedCol;
  int mistakes;
  bool isCompleted;
  int elapsedSeconds;
  int failureCount;
  final List<NumberSumsUndoAction> _undoHistory;
  static const int maxUndoCount = 20;

  NumberSumsGameState({
    required this.solution,
    required this.puzzle,
    required this.currentBoard,
    required this.cellTypes,
    required this.wrongCells,
    required this.clues,
    required this.gridSize,
    required this.difficulty,
    this.selectedRow,
    this.selectedCol,
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

    // wrongCells 파싱
    final wrongCellsData = data['wrongCells'] as List?;
    final wrongCells = wrongCellsData != null
        ? (wrongCellsData as List)
            .map((row) => (row as List).map((v) => v == 1).toList())
            .toList()
        : List.generate(gridSize, (_) => List.filled(gridSize, false));

    final currentBoard = puzzle.map((row) => List<int>.from(row)).toList();

    return NumberSumsGameState(
      solution: solution,
      puzzle: puzzle,
      currentBoard: currentBoard,
      cellTypes: cellTypes,
      wrongCells: wrongCells,
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
    List<List<bool>>? wrongCells,
    List<NumberSumsClue>? clues,
    int? gridSize,
    NumberSumsDifficulty? difficulty,
    int? selectedRow,
    int? selectedCol,
    int? mistakes,
    bool? isCompleted,
    int? elapsedSeconds,
    int? failureCount,
    bool clearSelection = false,
  }) {
    return NumberSumsGameState(
      solution: solution ?? this.solution,
      puzzle: puzzle ?? this.puzzle,
      currentBoard: currentBoard ?? this.currentBoard,
      cellTypes: cellTypes ?? this.cellTypes,
      wrongCells: wrongCells ?? this.wrongCells,
      clues: clues ?? this.clues,
      gridSize: gridSize ?? this.gridSize,
      difficulty: difficulty ?? this.difficulty,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
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

  /// 이 셀이 틀린 숫자인지 확인
  bool isWrongCell(int row, int col) {
    return wrongCells[row][col];
  }

  /// 이 셀이 현재 정답 상태인지 (제거되지 않은 올바른 숫자)
  bool isCorrectCell(int row, int col) {
    if (cellTypes[row][col] != 1) return false;
    return currentBoard[row][col] == solution[row][col];
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

  /// 현재 상태를 Undo 히스토리에 저장
  void saveToUndoHistory(int row, int col) {
    final action = NumberSumsUndoAction(
      row: row,
      col: col,
      previousValue: currentBoard[row][col],
    );
    _undoHistory.add(action);
    if (_undoHistory.length > maxUndoCount) {
      _undoHistory.removeAt(0);
    }
  }

  /// Undo 히스토리에서 pop하고 액션 반환 (내부 상태도 복원)
  NumberSumsUndoAction? popFromUndoHistory() {
    if (_undoHistory.isEmpty) return null;

    final action = _undoHistory.removeLast();
    currentBoard[action.row][action.col] = action.previousValue;
    return action;
  }

  bool get canUndo => _undoHistory.isNotEmpty;
  int get undoCount => _undoHistory.length;

  void clearUndoHistory() {
    _undoHistory.clear();
  }

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

  /// 남은 틀린 숫자 개수
  int get remainingWrongCount {
    int count = 0;
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (wrongCells[row][col] && currentBoard[row][col] != 0) {
          count++;
        }
      }
    }
    return count;
  }

  /// 보드가 완성되었는지 확인 (모든 틀린 숫자가 제거됨)
  bool checkCompletion() {
    return NumberSumsGenerator.isBoardComplete(
      currentBoard,
      solution,
      cellTypes,
      gridSize,
    );
  }
}
