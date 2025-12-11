import 'sudoku_generator.dart';

enum Difficulty { easy, medium, hard }

class GameState {
  final List<List<int>> solution;
  final List<List<int>> puzzle;
  final List<List<int>> currentBoard;
  final List<List<bool>> isFixed;
  final Difficulty difficulty;
  int? selectedRow;
  int? selectedCol;
  int mistakes;
  bool isCompleted;

  GameState({
    required this.solution,
    required this.puzzle,
    required this.currentBoard,
    required this.isFixed,
    required this.difficulty,
    this.selectedRow,
    this.selectedCol,
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

    return GameState(
      solution: solution,
      puzzle: puzzle,
      currentBoard: currentBoard,
      isFixed: isFixed,
      difficulty: difficulty,
    );
  }

  GameState copyWith({
    List<List<int>>? solution,
    List<List<int>>? puzzle,
    List<List<int>>? currentBoard,
    List<List<bool>>? isFixed,
    Difficulty? difficulty,
    int? selectedRow,
    int? selectedCol,
    int? mistakes,
    bool? isCompleted,
    bool clearSelection = false,
  }) {
    return GameState(
      solution: solution ?? this.solution,
      puzzle: puzzle ?? this.puzzle,
      currentBoard: currentBoard ?? this.currentBoard,
      isFixed: isFixed ?? this.isFixed,
      difficulty: difficulty ?? this.difficulty,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      mistakes: mistakes ?? this.mistakes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

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
