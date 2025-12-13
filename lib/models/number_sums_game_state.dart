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
}

/// 게임 모드
enum NumberSumsGameMode {
  select, // 선택 모드: 올바른 수 찾기
  remove, // 제거 모드: 틀린 수 제거
}

class NumberSumsGameState {
  final List<List<int>> solution;
  final List<List<int>> puzzle;
  final List<List<int>> currentBoard;
  final List<List<int>> cellTypes; // 0 = 헤더, 1 = 입력 셀
  final List<List<bool>> wrongCells;
  final List<List<bool>> markedCorrectCells; // 올바른 수로 표시된 셀
  final List<int> rowSums; // 각 행의 정답 합계
  final List<int> colSums; // 각 열의 정답 합계
  final int gridSize; // 전체 그리드 크기 (헤더 포함)
  final int gameSize; // 실제 게임 그리드 크기
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
    required this.markedCorrectCells,
    required this.rowSums,
    required this.colSums,
    required this.gridSize,
    required this.gameSize,
    required this.difficulty,
    this.selectedRow,
    this.selectedCol,
    this.mistakes = 0,
    this.isCompleted = false,
    this.elapsedSeconds = 0,
    this.failureCount = 0,
    List<NumberSumsUndoAction>? undoHistory,
  }) : _undoHistory = undoHistory ?? [];

  factory NumberSumsGameState.fromGeneratedData(Map<String, dynamic> data) {
    final gridSize = data['gridSize'] as int;
    final gameSize = data['gameSize'] as int;
    final solution = (data['solution'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final puzzle = (data['puzzle'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final cellTypes = (data['cellTypes'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final difficulty = NumberSumsDifficulty.values[data['difficulty'] as int];

    final wrongCellsData = data['wrongCells'] as List;
    final wrongCells = wrongCellsData
        .map((row) => (row as List).map((v) => v == 1).toList())
        .toList();

    final rowSums = List<int>.from(data['rowSums'] as List);
    final colSums = List<int>.from(data['colSums'] as List);

    final currentBoard = puzzle.map((row) => List<int>.from(row)).toList();

    // 정답 표시 셀 초기화
    final markedCorrectCells = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => false),
    );

    return NumberSumsGameState(
      solution: solution,
      puzzle: puzzle,
      currentBoard: currentBoard,
      cellTypes: cellTypes,
      wrongCells: wrongCells,
      markedCorrectCells: markedCorrectCells,
      rowSums: rowSums,
      colSums: colSums,
      gridSize: gridSize,
      gameSize: gameSize,
      difficulty: difficulty,
    );
  }

  NumberSumsGameState copyWith({
    List<List<int>>? solution,
    List<List<int>>? puzzle,
    List<List<int>>? currentBoard,
    List<List<int>>? cellTypes,
    List<List<bool>>? wrongCells,
    List<List<bool>>? markedCorrectCells,
    List<int>? rowSums,
    List<int>? colSums,
    int? gridSize,
    int? gameSize,
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
      markedCorrectCells: markedCorrectCells ?? this.markedCorrectCells,
      rowSums: rowSums ?? this.rowSums,
      colSums: colSums ?? this.colSums,
      gridSize: gridSize ?? this.gridSize,
      gameSize: gameSize ?? this.gameSize,
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

  bool isInputCell(int row, int col) {
    return cellTypes[row][col] == 1;
  }

  bool isWrongCell(int row, int col) {
    return wrongCells[row][col];
  }

  bool isMarkedCorrect(int row, int col) {
    return markedCorrectCells[row][col];
  }

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

  NumberSumsUndoAction? popFromUndoHistory() {
    if (_undoHistory.isEmpty) return null;

    final action = _undoHistory.removeLast();
    currentBoard[action.row][action.col] = action.previousValue;
    return action;
  }

  bool get canUndo => _undoHistory.isNotEmpty;

  bool get hasSelection => selectedRow != null && selectedCol != null;

  bool isSelected(int row, int col) {
    return selectedRow == row && selectedCol == col;
  }

  /// 남은 틀린 숫자 개수
  int get remainingWrongCount {
    int count = 0;
    for (int row = 1; row < gridSize; row++) {
      for (int col = 1; col < gridSize; col++) {
        if (wrongCells[row][col] && currentBoard[row][col] != 0) {
          count++;
        }
      }
    }
    return count;
  }

  /// 보드가 완성되었는지 확인
  bool checkCompletion() {
    return NumberSumsGenerator.isBoardComplete(
      currentBoard,
      solution,
      gridSize,
    );
  }
}
