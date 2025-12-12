import 'killer_sudoku_generator.dart';

enum KillerDifficulty { easy, medium, hard }

/// 케이지 정보
class Cage {
  final int sum; // 케이지 내 숫자들의 합
  final List<(int, int)> cells; // 케이지에 속한 셀 좌표들

  const Cage({
    required this.sum,
    required this.cells,
  });

  /// 케이지에 특정 셀이 포함되어 있는지 확인
  bool contains(int row, int col) {
    return cells.any((cell) => cell.$1 == row && cell.$2 == col);
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'sum': sum,
        'cells': cells.map((c) => [c.$1, c.$2]).toList(),
      };

  /// JSON 역직렬화
  factory Cage.fromJson(Map<String, dynamic> json) {
    return Cage(
      sum: json['sum'] as int,
      cells: (json['cells'] as List)
          .map((c) => ((c as List)[0] as int, c[1] as int))
          .toList(),
    );
  }
}

/// Isolate에서 실행할 퍼즐 생성 함수
Map<String, dynamic> generateKillerPuzzleInIsolate(KillerDifficulty difficulty) {
  final generator = KillerSudokuGenerator();
  final result = generator.generatePuzzle(difficulty);

  return {
    'solution': result['solution'],
    'puzzle': result['puzzle'],
    'cages': (result['cages'] as List<Cage>).map((c) => c.toJson()).toList(),
    'difficulty': difficulty.index,
  };
}

/// Undo를 위한 동작 기록
class KillerUndoAction {
  final int row;
  final int col;
  final int previousValue;
  final Set<int> previousNotes;
  final Map<String, Set<int>> affectedCellsNotes;

  KillerUndoAction({
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

class KillerGameState {
  final List<List<int>> solution;
  final List<List<int>> puzzle;
  final List<List<int>> currentBoard;
  final List<List<bool>> isFixed;
  final List<List<Set<int>>> notes;
  final List<Cage> cages;
  final KillerDifficulty difficulty;
  int? selectedRow;
  int? selectedCol;
  int? quickInputNumber;
  int mistakes;
  bool isCompleted;
  int elapsedSeconds;
  int failureCount;
  final List<KillerUndoAction> _undoHistory = [];
  static const int maxUndoCount = 10;

  KillerGameState({
    required this.solution,
    required this.puzzle,
    required this.currentBoard,
    required this.isFixed,
    required this.notes,
    required this.cages,
    required this.difficulty,
    this.selectedRow,
    this.selectedCol,
    this.quickInputNumber,
    this.mistakes = 0,
    this.isCompleted = false,
    this.elapsedSeconds = 0,
    this.failureCount = 0,
  });

  /// 생성된 데이터로부터 GameState 생성
  factory KillerGameState.fromGeneratedData(Map<String, dynamic> data) {
    final solution = (data['solution'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final puzzle = (data['puzzle'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final cages = (data['cages'] as List)
        .map((c) => Cage.fromJson(c as Map<String, dynamic>))
        .toList();
    final difficulty = KillerDifficulty.values[data['difficulty'] as int];

    final currentBoard = puzzle.map((row) => List<int>.from(row)).toList();
    final isFixed = puzzle
        .map((row) => row.map((cell) => cell != 0).toList())
        .toList();
    final notes = List.generate(
      9,
      (_) => List.generate(9, (_) => <int>{}),
    );

    return KillerGameState(
      solution: solution,
      puzzle: puzzle,
      currentBoard: currentBoard,
      isFixed: isFixed,
      notes: notes,
      cages: cages,
      difficulty: difficulty,
    );
  }

  KillerGameState copyWith({
    List<List<int>>? solution,
    List<List<int>>? puzzle,
    List<List<int>>? currentBoard,
    List<List<bool>>? isFixed,
    List<List<Set<int>>>? notes,
    List<Cage>? cages,
    KillerDifficulty? difficulty,
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
    return KillerGameState(
      solution: solution ?? this.solution,
      puzzle: puzzle ?? this.puzzle,
      currentBoard: currentBoard ?? this.currentBoard,
      isFixed: isFixed ?? this.isFixed,
      notes: notes ?? this.notes,
      cages: cages ?? this.cages,
      difficulty: difficulty ?? this.difficulty,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      quickInputNumber:
          clearQuickInput ? null : (quickInputNumber ?? this.quickInputNumber),
      mistakes: mistakes ?? this.mistakes,
      isCompleted: isCompleted ?? this.isCompleted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      failureCount: failureCount ?? this.failureCount,
    );
  }

  /// 특정 셀이 속한 케이지 찾기
  Cage? getCageForCell(int row, int col) {
    for (final cage in cages) {
      if (cage.contains(row, col)) {
        return cage;
      }
    }
    return null;
  }

  /// 케이지의 좌상단 셀 확인 (합계 표시용)
  bool isCageTopLeft(int row, int col) {
    final cage = getCageForCell(row, col);
    if (cage == null) return false;

    // 케이지의 셀들 중 가장 위에 있고, 같은 행에서 가장 왼쪽에 있는 셀
    int minRow = cage.cells.map((c) => c.$1).reduce((a, b) => a < b ? a : b);
    int minColInMinRow = cage.cells
        .where((c) => c.$1 == minRow)
        .map((c) => c.$2)
        .reduce((a, b) => a < b ? a : b);

    return row == minRow && col == minColInMinRow;
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

  /// 같은 행/열/박스/케이지의 메모에서 해당 숫자 삭제
  void removeNumberFromRelatedNotes(int row, int col, int number) {
    // 같은 행
    for (int c = 0; c < 9; c++) {
      if (c != col) {
        notes[row][c].remove(number);
      }
    }

    // 같은 열
    for (int r = 0; r < 9; r++) {
      if (r != row) {
        notes[r][col].remove(number);
      }
    }

    // 같은 3x3 박스
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

    // 같은 케이지
    final cage = getCageForCell(row, col);
    if (cage != null) {
      for (final cell in cage.cells) {
        if (cell.$1 != row || cell.$2 != col) {
          notes[cell.$1][cell.$2].remove(number);
        }
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
      // 같은 행
      for (int c = 0; c < 9; c++) {
        if (c != col && notes[row][c].contains(numberToInput)) {
          affectedNotes[KillerUndoAction.cellKey(row, c)] =
              Set<int>.from(notes[row][c]);
        }
      }
      // 같은 열
      for (int r = 0; r < 9; r++) {
        if (r != row && notes[r][col].contains(numberToInput)) {
          affectedNotes[KillerUndoAction.cellKey(r, col)] =
              Set<int>.from(notes[r][col]);
        }
      }
      // 같은 3x3 박스
      int boxRow = (row ~/ 3) * 3;
      int boxCol = (col ~/ 3) * 3;
      for (int r = boxRow; r < boxRow + 3; r++) {
        for (int c = boxCol; c < boxCol + 3; c++) {
          if ((r != row || c != col) && notes[r][c].contains(numberToInput)) {
            affectedNotes[KillerUndoAction.cellKey(r, c)] =
                Set<int>.from(notes[r][c]);
          }
        }
      }
      // 같은 케이지
      final cage = getCageForCell(row, col);
      if (cage != null) {
        for (final cell in cage.cells) {
          if ((cell.$1 != row || cell.$2 != col) &&
              notes[cell.$1][cell.$2].contains(numberToInput)) {
            affectedNotes[KillerUndoAction.cellKey(cell.$1, cell.$2)] =
                Set<int>.from(notes[cell.$1][cell.$2]);
          }
        }
      }
    }

    final action = KillerUndoAction(
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
      final (r, c) = KillerUndoAction.parseKey(entry.key);
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
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (currentBoard[row][col] == 0) {
          final Set<int> newNotes = <int>{};
          for (int num = 1; num <= 9; num++) {
            if (isValidMove(row, col, num)) {
              newNotes.add(num);
            }
          }
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

  /// 같은 케이지인지 확인
  bool isSameCage(int row, int col) {
    if (!hasSelection) return false;
    final selectedCage = getCageForCell(selectedRow!, selectedCol!);
    final cellCage = getCageForCell(row, col);
    if (selectedCage == null || cellCage == null) return false;
    return selectedCage == cellCage;
  }

  /// 유효한 입력인지 확인 (행/열/박스/케이지 중복 체크)
  bool isValidMove(int row, int col, int num) {
    if (num == 0) return true;

    // 행 검사
    for (int i = 0; i < 9; i++) {
      if (i != col && currentBoard[row][i] == num) return false;
    }

    // 열 검사
    for (int i = 0; i < 9; i++) {
      if (i != row && currentBoard[i][col] == num) return false;
    }

    // 3x3 박스 검사
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((boxRow + i != row || boxCol + j != col) &&
            currentBoard[boxRow + i][boxCol + j] == num) {
          return false;
        }
      }
    }

    // 케이지 검사 (같은 케이지 내 중복 금지)
    final cage = getCageForCell(row, col);
    if (cage != null) {
      for (final cell in cage.cells) {
        if ((cell.$1 != row || cell.$2 != col) &&
            currentBoard[cell.$1][cell.$2] == num) {
          return false;
        }
      }
    }

    return true;
  }

  /// 에러 여부 확인
  bool hasError(int row, int col) {
    int value = currentBoard[row][col];
    if (value == 0) return false;
    return !isValidMove(row, col, value);
  }

  /// 케이지 합계 에러 확인 (케이지가 완성되었을 때만)
  bool hasCageSumError(int row, int col) {
    final cage = getCageForCell(row, col);
    if (cage == null) return false;

    // 케이지 내 모든 셀이 채워졌는지 확인
    bool allFilled = true;
    int sum = 0;
    for (final cell in cage.cells) {
      if (currentBoard[cell.$1][cell.$2] == 0) {
        allFilled = false;
        break;
      }
      sum += currentBoard[cell.$1][cell.$2];
    }

    // 모두 채워졌으면 합계 확인
    if (allFilled) {
      return sum != cage.sum;
    }

    return false;
  }

  /// 보드가 완성되었는지 검사
  bool isBoardComplete() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (currentBoard[row][col] == 0) return false;
        if (!isValidMove(row, col, currentBoard[row][col])) return false;
      }
    }

    // 모든 케이지 합계 확인
    for (final cage in cages) {
      int sum = 0;
      for (final cell in cage.cells) {
        sum += currentBoard[cell.$1][cell.$2];
      }
      if (sum != cage.sum) return false;
    }

    return true;
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
