import 'dart:math';

enum NumberSumsDifficulty { easy, medium, hard }

class NumberSumsGenerator {
  final Random _random = Random();

  Map<String, dynamic> generatePuzzle(NumberSumsDifficulty difficulty) {
    int gameSize;
    double fillRatio; // 정답 셀 비율

    switch (difficulty) {
      case NumberSumsDifficulty.easy:
        gameSize = 5;
        fillRatio = 0.6; // 60% 정답 셀
        break;
      case NumberSumsDifficulty.medium:
        gameSize = 6;
        fillRatio = 0.55;
        break;
      case NumberSumsDifficulty.hard:
        gameSize = 7;
        fillRatio = 0.5;
        break;
    }

    return _generateEliminationPuzzle(gameSize, difficulty, fillRatio);
  }

  Map<String, dynamic> _generateEliminationPuzzle(
      int gameSize, NumberSumsDifficulty difficulty, double fillRatio) {
    final int gridSize = gameSize + 1;

    // 1. 정답 패턴 생성 (어떤 셀에 정답 숫자가 있는지)
    // solution: 정답 숫자가 있는 셀만 값이 있고, 나머지는 0
    final solution = List.generate(
      gridSize,
      (row) => List.generate(gridSize, (col) => 0),
    );

    // cellTypes: 0 = 헤더, 1 = 정답 셀, 2 = 빈 셀 (틀린 숫자로 채워질)
    final cellTypes = List.generate(
      gridSize,
      (row) => List.generate(gridSize, (col) {
        if (row == 0 || col == 0) return 0; // 헤더
        return 1; // 일단 모두 입력 셀로
      }),
    );

    // 정답 셀 위치 결정
    final allCells = <(int, int)>[];
    for (int row = 1; row < gridSize; row++) {
      for (int col = 1; col < gridSize; col++) {
        allCells.add((row, col));
      }
    }

    int correctCellCount = (allCells.length * fillRatio).round();
    correctCellCount = max(correctCellCount, gameSize); // 최소 gameSize개

    allCells.shuffle(_random);
    final correctCells = allCells.take(correctCellCount).toSet();
    final emptyCells = allCells.skip(correctCellCount).toList();

    // 정답 셀에 1-9 숫자 배치 (행/열 내 중복 허용)
    for (final (row, col) in correctCells) {
      solution[row][col] = _random.nextInt(9) + 1;
    }

    // 2. 행/열 합계 계산 (정답 셀 숫자만)
    final rowSums = List<int>.filled(gridSize, 0);
    final colSums = List<int>.filled(gridSize, 0);

    for (int row = 1; row < gridSize; row++) {
      for (int col = 1; col < gridSize; col++) {
        rowSums[row] += solution[row][col];
        colSums[col] += solution[row][col];
      }
    }

    // 3. 퍼즐 보드 생성: 정답 복사 + 빈 셀에 틀린 숫자 채우기
    final puzzle = solution.map((row) => List<int>.from(row)).toList();
    final wrongCells = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => false),
    );

    // 모든 빈 셀에 틀린 숫자 채우기 (빈 칸이 없도록)
    for (final (row, col) in emptyCells) {
      // 틀린 숫자 생성 (1-9)
      puzzle[row][col] = _random.nextInt(9) + 1;
      wrongCells[row][col] = true;
    }

    return {
      'solution': solution,
      'puzzle': puzzle,
      'cellTypes': cellTypes,
      'wrongCells': wrongCells.map((row) => row.map((v) => v ? 1 : 0).toList()).toList(),
      'rowSums': rowSums,
      'colSums': colSums,
      'gridSize': gridSize,
      'gameSize': gameSize,
      'difficulty': difficulty.index,
    };
  }

  /// 보드가 완성되었는지 확인 (모든 틀린 숫자가 제거됨)
  static bool isBoardComplete(
    List<List<int>> currentBoard,
    List<List<int>> solution,
    int gridSize,
  ) {
    for (int row = 1; row < gridSize; row++) {
      for (int col = 1; col < gridSize; col++) {
        if (currentBoard[row][col] != solution[row][col]) {
          return false;
        }
      }
    }
    return true;
  }
}
