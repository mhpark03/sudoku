import 'samurai_sudoku_generator.dart';

enum SamuraiDifficulty { easy, medium, hard }

class SamuraiGameState {
  final List<List<List<int>>> solutions;
  final List<List<List<int>>> puzzles;
  final List<List<List<int>>> currentBoards;
  final List<List<List<bool>>> isFixed;
  // 메모: 각 셀에 대한 후보 숫자 Set (5개 보드 x 9행 x 9열)
  final List<List<List<Set<int>>>> notes;
  final SamuraiDifficulty difficulty;
  int selectedBoard;
  int? selectedRow;
  int? selectedCol;
  bool isCompleted;

  SamuraiGameState({
    required this.solutions,
    required this.puzzles,
    required this.currentBoards,
    required this.isFixed,
    required this.notes,
    required this.difficulty,
    this.selectedBoard = 2,
    this.selectedRow,
    this.selectedCol,
    this.isCompleted = false,
  });

  factory SamuraiGameState.newGame(SamuraiDifficulty difficulty) {
    final generator = SamuraiSudokuGenerator();
    final solutions = generator.generateSolvedBoards();

    int emptyCells;
    switch (difficulty) {
      case SamuraiDifficulty.easy:
        emptyCells = 30;
        break;
      case SamuraiDifficulty.medium:
        emptyCells = 40;
        break;
      case SamuraiDifficulty.hard:
        emptyCells = 50;
        break;
    }

    final puzzles = generator.generatePuzzles(solutions, emptyCells);
    final currentBoards = puzzles
        .map((board) => board.map((row) => List<int>.from(row)).toList())
        .toList();
    final isFixed = puzzles
        .map((board) =>
            board.map((row) => row.map((cell) => cell != 0).toList()).toList())
        .toList();

    // 메모 초기화: 5개 보드 x 9행 x 9열, 각각 빈 Set
    final notes = List.generate(
      5,
      (_) => List.generate(
        9,
        (_) => List.generate(9, (_) => <int>{}),
      ),
    );

    return SamuraiGameState(
      solutions: solutions,
      puzzles: puzzles,
      currentBoards: currentBoards,
      isFixed: isFixed,
      notes: notes,
      difficulty: difficulty,
    );
  }

  SamuraiGameState copyWith({
    List<List<List<int>>>? solutions,
    List<List<List<int>>>? puzzles,
    List<List<List<int>>>? currentBoards,
    List<List<List<bool>>>? isFixed,
    List<List<List<Set<int>>>>? notes,
    SamuraiDifficulty? difficulty,
    int? selectedBoard,
    int? selectedRow,
    int? selectedCol,
    bool? isCompleted,
    bool clearSelection = false,
  }) {
    return SamuraiGameState(
      solutions: solutions ?? this.solutions,
      puzzles: puzzles ?? this.puzzles,
      currentBoards: currentBoards ?? this.currentBoards,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? this.notes,
      difficulty: difficulty ?? this.difficulty,
      selectedBoard: selectedBoard ?? this.selectedBoard,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get hasSelection => selectedRow != null && selectedCol != null;

  int? get selectedValue {
    if (!hasSelection) return null;
    return currentBoards[selectedBoard][selectedRow!][selectedCol!];
  }

  bool isSelectedCell(int board, int row, int col) {
    return selectedBoard == board &&
        selectedRow == row &&
        selectedCol == col;
  }

  bool isSameRowOrCol(int board, int row, int col) {
    if (!hasSelection || selectedBoard != board) return false;
    return selectedRow == row || selectedCol == col;
  }

  bool isSameBox(int board, int row, int col) {
    if (!hasSelection || selectedBoard != board) return false;
    int selectedBoxRow = (selectedRow! ~/ 3) * 3;
    int selectedBoxCol = (selectedCol! ~/ 3) * 3;
    int cellBoxRow = (row ~/ 3) * 3;
    int cellBoxCol = (col ~/ 3) * 3;
    return selectedBoxRow == cellBoxRow && selectedBoxCol == cellBoxCol;
  }

  bool isSameValue(int board, int row, int col) {
    if (!hasSelection) return false;
    int cellValue = currentBoards[board][row][col];
    return cellValue != 0 && cellValue == selectedValue;
  }

  bool hasError(int board, int row, int col) {
    int value = currentBoards[board][row][col];
    if (value == 0) return false;
    return !SamuraiSudokuGenerator.isValidMove(
        currentBoards[board], row, col, value);
  }

  /// 겹치는 영역인지 확인
  bool isOverlapRegion(int board, int row, int col) {
    switch (board) {
      case 0:
        return row >= 6 && col >= 6;
      case 1:
        return row >= 6 && col < 3;
      case 2:
        return (row < 3 && col < 3) ||
            (row < 3 && col >= 6) ||
            (row >= 6 && col < 3) ||
            (row >= 6 && col >= 6);
      case 3:
        return row < 3 && col >= 6;
      case 4:
        return row < 3 && col < 3;
      default:
        return false;
    }
  }

  /// 값 입력 시 겹치는 영역 동기화
  void syncOverlapValue(int board, int row, int col, int value) {
    // 보드 0 우하단 <-> 보드 2 좌상단
    if (board == 0 && row >= 6 && col >= 6) {
      currentBoards[2][row - 6][col - 6] = value;
      if (value != 0) notes[2][row - 6][col - 6].clear();
    } else if (board == 2 && row < 3 && col < 3) {
      currentBoards[0][row + 6][col + 6] = value;
      if (value != 0) notes[0][row + 6][col + 6].clear();
    }

    // 보드 1 좌하단 <-> 보드 2 우상단
    if (board == 1 && row >= 6 && col < 3) {
      currentBoards[2][row - 6][col + 6] = value;
      if (value != 0) notes[2][row - 6][col + 6].clear();
    } else if (board == 2 && row < 3 && col >= 6) {
      currentBoards[1][row + 6][col - 6] = value;
      if (value != 0) notes[1][row + 6][col - 6].clear();
    }

    // 보드 2 좌하단 <-> 보드 3 우상단
    if (board == 2 && row >= 6 && col < 3) {
      currentBoards[3][row - 6][col + 6] = value;
      if (value != 0) notes[3][row - 6][col + 6].clear();
    } else if (board == 3 && row < 3 && col >= 6) {
      currentBoards[2][row + 6][col - 6] = value;
      if (value != 0) notes[2][row + 6][col - 6].clear();
    }

    // 보드 2 우하단 <-> 보드 4 좌상단
    if (board == 2 && row >= 6 && col >= 6) {
      currentBoards[4][row - 6][col - 6] = value;
      if (value != 0) notes[4][row - 6][col - 6].clear();
    } else if (board == 4 && row < 3 && col < 3) {
      currentBoards[2][row + 6][col + 6] = value;
      if (value != 0) notes[2][row + 6][col + 6].clear();
    }
  }

  /// 메모 동기화 (겹치는 영역)
  void syncOverlapNotes(int board, int row, int col, Set<int> noteSet) {
    if (board == 0 && row >= 6 && col >= 6) {
      notes[2][row - 6][col - 6] = Set.from(noteSet);
    } else if (board == 2 && row < 3 && col < 3) {
      notes[0][row + 6][col + 6] = Set.from(noteSet);
    }

    if (board == 1 && row >= 6 && col < 3) {
      notes[2][row - 6][col + 6] = Set.from(noteSet);
    } else if (board == 2 && row < 3 && col >= 6) {
      notes[1][row + 6][col - 6] = Set.from(noteSet);
    }

    if (board == 2 && row >= 6 && col < 3) {
      notes[3][row - 6][col + 6] = Set.from(noteSet);
    } else if (board == 3 && row < 3 && col >= 6) {
      notes[2][row + 6][col - 6] = Set.from(noteSet);
    }

    if (board == 2 && row >= 6 && col >= 6) {
      notes[4][row - 6][col - 6] = Set.from(noteSet);
    } else if (board == 4 && row < 3 && col < 3) {
      notes[2][row + 6][col + 6] = Set.from(noteSet);
    }
  }

  /// 메모 토글 (숫자 추가/제거)
  void toggleNote(int board, int row, int col, int number) {
    if (currentBoards[board][row][col] != 0) return;
    if (isFixed[board][row][col]) return;

    if (notes[board][row][col].contains(number)) {
      notes[board][row][col].remove(number);
    } else {
      notes[board][row][col].add(number);
    }
    syncOverlapNotes(board, row, col, notes[board][row][col]);
  }

  /// 모든 메모 자동 채우기 (특정 보드)
  void fillAllNotes(int board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (currentBoards[board][row][col] == 0 && !isFixed[board][row][col]) {
          notes[board][row][col].clear();
          for (int num = 1; num <= 9; num++) {
            if (SamuraiSudokuGenerator.isValidMove(
                currentBoards[board], row, col, num)) {
              notes[board][row][col].add(num);
            }
          }
          syncOverlapNotes(board, row, col, notes[board][row][col]);
        }
      }
    }
  }

  /// 셀의 메모 가져오기
  Set<int> getNotes(int board, int row, int col) {
    return notes[board][row][col];
  }

  /// 셀의 메모 지우기
  void clearNotes(int board, int row, int col) {
    notes[board][row][col].clear();
    syncOverlapNotes(board, row, col, notes[board][row][col]);
  }
}
