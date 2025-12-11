import 'sudoku_generator.dart';

enum Difficulty { easy, medium, hard }

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
  });

  factory GameState.newGame(Difficulty difficulty) {
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
        emptyCells = 55;
        break;
    }

    final puzzle = generator.generatePuzzle(solution, emptyCells);
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
        if (currentBoard[row][col] == 0) {
          notes[row][col].clear();
          for (int num = 1; num <= 9; num++) {
            if (SudokuGenerator.isValidMove(currentBoard, row, col, num)) {
              notes[row][col].add(num);
            }
          }
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
}
