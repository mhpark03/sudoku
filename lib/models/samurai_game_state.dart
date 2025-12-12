import 'samurai_sudoku_generator.dart';

enum SamuraiDifficulty { easy, medium, hard, expert }

/// Isolate에서 실행할 퍼즐 생성 함수 (top-level 함수)
Map<String, dynamic> generateSamuraiPuzzleInIsolate(SamuraiDifficulty difficulty) {
  final generator = SamuraiSudokuGenerator();
  final solutions = generator.generateSolvedBoards();

  int emptyCells;
  switch (difficulty) {
    case SamuraiDifficulty.easy:
      emptyCells = 30;
      break;
    case SamuraiDifficulty.medium:
      emptyCells = 45;
      break;
    case SamuraiDifficulty.hard:
      emptyCells = 60;
      break;
    case SamuraiDifficulty.expert:
      emptyCells = 70;
      break;
  }

  final puzzles = generator.generatePuzzles(solutions, emptyCells);

  return {
    'solutions': solutions,
    'puzzles': puzzles,
    'difficulty': difficulty.index,
  };
}

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
  // 게임 통계
  int elapsedSeconds;
  int failureCount;

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
    this.elapsedSeconds = 0,
    this.failureCount = 0,
  });

  /// 동기적으로 새 게임 생성 (메인 스레드에서 실행, UI 블로킹 가능)
  factory SamuraiGameState.newGame(SamuraiDifficulty difficulty) {
    final data = generateSamuraiPuzzleInIsolate(difficulty);
    return SamuraiGameState.fromGeneratedData(data);
  }

  /// 생성된 데이터로부터 GameState 생성 (isolate에서 생성된 데이터 사용)
  factory SamuraiGameState.fromGeneratedData(Map<String, dynamic> data) {
    final solutions = (data['solutions'] as List)
        .map((board) => (board as List)
            .map((row) => List<int>.from(row as List))
            .toList())
        .toList();
    final puzzles = (data['puzzles'] as List)
        .map((board) => (board as List)
            .map((row) => List<int>.from(row as List))
            .toList())
        .toList();
    final difficulty = SamuraiDifficulty.values[data['difficulty'] as int];

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
    int? elapsedSeconds,
    int? failureCount,
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
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      failureCount: failureCount ?? this.failureCount,
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
        // 빈 셀(값이 0)에만 메모 적용
        if (currentBoards[board][row][col] == 0) {
          // 기존 메모 완전히 지우고 새로 계산
          Set<int> newNotes = <int>{};
          for (int num = 1; num <= 9; num++) {
            if (SamuraiSudokuGenerator.isValidMove(
                currentBoards[board], row, col, num)) {
              newNotes.add(num);
            }
          }
          notes[board][row][col] = newNotes;
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

  /// 값 입력 시 모든 관련 보드의 메모에서 해당 숫자 제거
  void removeNumberFromAllRelatedNotes(int board, int row, int col, int number) {
    // 1. 현재 보드의 같은 행/열/박스에서 제거
    _removeFromBoard(board, row, col, number);

    // 2. 겹치는 영역인 경우 다른 보드에서도 제거
    // 보드 0 우하단 <-> 보드 2 좌상단
    if (board == 0 && row >= 6 && col >= 6) {
      _removeFromBoard(2, row - 6, col - 6, number);
    } else if (board == 2 && row < 3 && col < 3) {
      _removeFromBoard(0, row + 6, col + 6, number);
    }

    // 보드 1 좌하단 <-> 보드 2 우상단
    if (board == 1 && row >= 6 && col < 3) {
      _removeFromBoard(2, row - 6, col + 6, number);
    } else if (board == 2 && row < 3 && col >= 6) {
      _removeFromBoard(1, row + 6, col - 6, number);
    }

    // 보드 2 좌하단 <-> 보드 3 우상단
    if (board == 2 && row >= 6 && col < 3) {
      _removeFromBoard(3, row - 6, col + 6, number);
    } else if (board == 3 && row < 3 && col >= 6) {
      _removeFromBoard(2, row + 6, col - 6, number);
    }

    // 보드 2 우하단 <-> 보드 4 좌상단
    if (board == 2 && row >= 6 && col >= 6) {
      _removeFromBoard(4, row - 6, col - 6, number);
    } else if (board == 4 && row < 3 && col < 3) {
      _removeFromBoard(2, row + 6, col + 6, number);
    }
  }

  /// 특정 보드의 같은 행/열/박스에서 숫자 제거
  void _removeFromBoard(int board, int row, int col, int number) {
    // 같은 행에서 제거
    for (int c = 0; c < 9; c++) {
      if (c != col) {
        notes[board][row][c].remove(number);
        // 해당 셀이 겹치는 영역이면 동기화
        _syncNoteRemovalToOverlap(board, row, c, number);
      }
    }

    // 같은 열에서 제거
    for (int r = 0; r < 9; r++) {
      if (r != row) {
        notes[board][r][col].remove(number);
        _syncNoteRemovalToOverlap(board, r, col, number);
      }
    }

    // 같은 3x3 박스에서 제거
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        int targetRow = boxRow + r;
        int targetCol = boxCol + c;
        if (targetRow != row || targetCol != col) {
          notes[board][targetRow][targetCol].remove(number);
          _syncNoteRemovalToOverlap(board, targetRow, targetCol, number);
        }
      }
    }
  }

  /// 메모 제거를 겹치는 보드에 동기화
  void _syncNoteRemovalToOverlap(int board, int row, int col, int number) {
    // 보드 0 우하단 <-> 보드 2 좌상단
    if (board == 0 && row >= 6 && col >= 6) {
      notes[2][row - 6][col - 6].remove(number);
    } else if (board == 2 && row < 3 && col < 3) {
      notes[0][row + 6][col + 6].remove(number);
    }

    // 보드 1 좌하단 <-> 보드 2 우상단
    if (board == 1 && row >= 6 && col < 3) {
      notes[2][row - 6][col + 6].remove(number);
    } else if (board == 2 && row < 3 && col >= 6) {
      notes[1][row + 6][col - 6].remove(number);
    }

    // 보드 2 좌하단 <-> 보드 3 우상단
    if (board == 2 && row >= 6 && col < 3) {
      notes[3][row - 6][col + 6].remove(number);
    } else if (board == 3 && row < 3 && col >= 6) {
      notes[2][row + 6][col - 6].remove(number);
    }

    // 보드 2 우하단 <-> 보드 4 좌상단
    if (board == 2 && row >= 6 && col >= 6) {
      notes[4][row - 6][col - 6].remove(number);
    } else if (board == 4 && row < 3 && col < 3) {
      notes[2][row + 6][col + 6].remove(number);
    }
  }

  /// 특정 보드에서 각 숫자가 몇 번 사용되었는지 카운트
  Map<int, int> getNumberCounts(int boardIndex) {
    final counts = <int, int>{};
    for (int num = 1; num <= 9; num++) {
      counts[num] = 0;
    }
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        int value = currentBoards[boardIndex][row][col];
        if (value != 0) {
          counts[value] = (counts[value] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  /// 특정 보드에서 모두 채워진 숫자들 (9번 사용된 숫자)
  Set<int> getCompletedNumbers(int boardIndex) {
    final counts = getNumberCounts(boardIndex);
    return counts.entries
        .where((entry) => entry.value >= 9)
        .map((entry) => entry.key)
        .toSet();
  }
}
