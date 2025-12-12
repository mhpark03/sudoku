import 'sudoku_generator.dart';

enum Difficulty { easy, medium, hard, expert }

/// Isolate에서 실행할 퍼즐 생성 함수 (top-level 함수)
Map<String, dynamic> generatePuzzleInIsolate(Difficulty difficulty) {
  final generator = SudokuGenerator();
  final solution = generator.generateSolvedBoard();

  int emptyCells;
  switch (difficulty) {
    case Difficulty.easy:
      emptyCells = 30;
      break;
    case Difficulty.medium:
      emptyCells = 45;
      break;
    case Difficulty.hard:
      emptyCells = 60;
      break;
    case Difficulty.expert:
      emptyCells = 70;
      break;
  }

  final puzzle = generator.generatePuzzle(solution, emptyCells);

  return {
    'solution': solution,
    'puzzle': puzzle,
    'difficulty': difficulty.index,
  };
}

class GameState {
  final List<List<int>> solution;
  final List<List<int>> puzzle;
  final List<List<int>> currentBoard;
  final List<List<bool>> isFixed;
  final List<List<Set<int>>> notes; // 메모 기능
  final Difficulty difficulty;
  int? selectedRow;
  int? selectedCol;
  int? quickInputNumber; // 빠른 입력 모드에서 선택된 숫자
  int mistakes;
  bool isCompleted;
  // 게임 통계
  int elapsedSeconds;
  int failureCount;

  GameState({
    required this.solution,
    required this.puzzle,
    required this.currentBoard,
    required this.isFixed,
    required this.notes,
    required this.difficulty,
    this.selectedRow,
    this.selectedCol,
    this.quickInputNumber,
    this.mistakes = 0,
    this.isCompleted = false,
    this.elapsedSeconds = 0,
    this.failureCount = 0,
  });

  /// 동기적으로 새 게임 생성 (메인 스레드에서 실행, UI 블로킹 가능)
  factory GameState.newGame(Difficulty difficulty) {
    final data = generatePuzzleInIsolate(difficulty);
    return GameState.fromGeneratedData(data);
  }

  /// 생성된 데이터로부터 GameState 생성 (isolate에서 생성된 데이터 사용)
  factory GameState.fromGeneratedData(Map<String, dynamic> data) {
    final solution = (data['solution'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final puzzle = (data['puzzle'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final difficulty = Difficulty.values[data['difficulty'] as int];

    final currentBoard = puzzle.map((row) => List<int>.from(row)).toList();
    final isFixed = puzzle
        .map((row) => row.map((cell) => cell != 0).toList())
        .toList();
    // 메모 초기화: 9x9 각각 빈 Set
    final notes = List.generate(
      9,
      (_) => List.generate(9, (_) => <int>{}),
    );

    return GameState(
      solution: solution,
      puzzle: puzzle,
      currentBoard: currentBoard,
      isFixed: isFixed,
      notes: notes,
      difficulty: difficulty,
    );
  }

  GameState copyWith({
    List<List<int>>? solution,
    List<List<int>>? puzzle,
    List<List<int>>? currentBoard,
    List<List<bool>>? isFixed,
    List<List<Set<int>>>? notes,
    Difficulty? difficulty,
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
    return GameState(
      solution: solution ?? this.solution,
      puzzle: puzzle ?? this.puzzle,
      currentBoard: currentBoard ?? this.currentBoard,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? this.notes,
      difficulty: difficulty ?? this.difficulty,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      quickInputNumber: clearQuickInput ? null : (quickInputNumber ?? this.quickInputNumber),
      mistakes: mistakes ?? this.mistakes,
      isCompleted: isCompleted ?? this.isCompleted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      failureCount: failureCount ?? this.failureCount,
    );
  }

  /// 메모 토글
  void toggleNote(int row, int col, int number) {
    if (currentBoard[row][col] != 0) return;
    if (isFixed[row][col]) return;

    if (notes[row][col].contains(number)) {
      notes[row][col].remove(number);
    } else {
      notes[row][col].add(number);
    }
  }

  /// 같은 행/열/박스의 메모에서 해당 숫자 삭제
  void removeNumberFromRelatedNotes(int row, int col, int number) {
    // 같은 행의 메모에서 삭제
    for (int c = 0; c < 9; c++) {
      if (c != col) {
        notes[row][c].remove(number);
      }
    }

    // 같은 열의 메모에서 삭제
    for (int r = 0; r < 9; r++) {
      if (r != row) {
        notes[r][col].remove(number);
      }
    }

    // 같은 3x3 박스의 메모에서 삭제
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        int targetRow = boxRow + r;
        int targetCol = boxCol + c;
        if (targetRow != row || targetCol != col) {
          notes[targetRow][targetCol].remove(number);
        }
      }
    }
  }

  /// 셀의 메모 지우기
  void clearNotes(int row, int col) {
    notes[row][col].clear();
  }

  /// 모든 빈 셀에 메모 자동 채우기
  void fillAllNotes() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        // 빈 셀(값이 0)에만 메모 적용
        if (currentBoard[row][col] == 0) {
          // 새로운 Set 생성하여 유효한 숫자 추가
          final Set<int> newNotes = <int>{};
          for (int num = 1; num <= 9; num++) {
            if (SudokuGenerator.isValidMove(currentBoard, row, col, num)) {
              newNotes.add(num);
            }
          }
          // 무조건 새 Set으로 교체 (기존 메모 무시)
          notes[row][col] = newNotes;
        }
      }
    }
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

  bool isSameRowOrCol(int row, int col) {
    if (!hasSelection) return false;
    return selectedRow == row || selectedCol == col;
  }

  bool isSameBox(int row, int col) {
    if (!hasSelection) return false;
    int selectedBoxRow = (selectedRow! ~/ 3) * 3;
    int selectedBoxCol = (selectedCol! ~/ 3) * 3;
    int cellBoxRow = (row ~/ 3) * 3;
    int cellBoxCol = (col ~/ 3) * 3;
    return selectedBoxRow == cellBoxRow && selectedBoxCol == cellBoxCol;
  }

  bool isSameValue(int row, int col) {
    if (!hasSelection) return false;
    int cellValue = currentBoard[row][col];
    return cellValue != 0 && cellValue == selectedValue;
  }

  bool hasError(int row, int col) {
    int value = currentBoard[row][col];
    if (value == 0) return false;
    return !SudokuGenerator.isValidMove(currentBoard, row, col, value);
  }

  /// 각 숫자가 보드에서 몇 번 사용되었는지 카운트
  Map<int, int> getNumberCounts() {
    final counts = <int, int>{};
    for (int num = 1; num <= 9; num++) {
      counts[num] = 0;
    }
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        int value = currentBoard[row][col];
        if (value != 0) {
          counts[value] = (counts[value] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  /// 모두 채워진 숫자들 (9번 사용된 숫자)
  Set<int> getCompletedNumbers() {
    final counts = getNumberCounts();
    return counts.entries
        .where((entry) => entry.value >= 9)
        .map((entry) => entry.key)
        .toSet();
  }
}
