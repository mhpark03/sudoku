import 'dart:math';

enum NumberSumsDifficulty { easy, medium, hard }

class NumberSumsGenerator {
  final Random _random = Random();

  Map<String, dynamic> generatePuzzle(NumberSumsDifficulty difficulty) {
    int gameSize; // 실제 게임 그리드 크기 (6x6 등)
    double wrongRatio;

    switch (difficulty) {
      case NumberSumsDifficulty.easy:
        gameSize = 5;
        wrongRatio = 0.25;
        break;
      case NumberSumsDifficulty.medium:
        gameSize = 6;
        wrongRatio = 0.30;
        break;
      case NumberSumsDifficulty.hard:
        gameSize = 7;
        wrongRatio = 0.35;
        break;
    }

    return _generateEliminationPuzzle(gameSize, difficulty, wrongRatio);
  }

  Map<String, dynamic> _generateEliminationPuzzle(
      int gameSize, NumberSumsDifficulty difficulty, double wrongRatio) {
    // 전체 그리드 크기 = gameSize + 1 (헤더 행/열 포함)
    final int gridSize = gameSize + 1;

    // 정답 보드 생성 (gameSize x gameSize, 1-9 랜덤)
    final solution = List.generate(
      gridSize,
      (row) => List.generate(gridSize, (col) {
        if (row == 0 || col == 0) return 0; // 헤더는 0
        return _random.nextInt(9) + 1; // 1-9
      }),
    );

    // cellTypes: 0 = 헤더/단서, 1 = 입력 셀
    final cellTypes = List.generate(
      gridSize,
      (row) => List.generate(gridSize, (col) {
        if (row == 0 || col == 0) return 0;
        return 1;
      }),
    );

    // 틀린 숫자 배치
    final wrongCells = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => false),
    );

    // 입력 셀 목록
    final inputCells = <(int, int)>[];
    for (int row = 1; row < gridSize; row++) {
      for (int col = 1; col < gridSize; col++) {
        inputCells.add((row, col));
      }
    }

    // 틀린 숫자 개수
    int wrongCount = (inputCells.length * wrongRatio).round();
    wrongCount = max(wrongCount, 2);

    // 퍼즐 보드 = 정답 복사
    final puzzle = solution.map((row) => List<int>.from(row)).toList();

    // 랜덤하게 틀린 숫자 배치
    inputCells.shuffle(_random);
    int addedWrong = 0;

    for (final (row, col) in inputCells) {
      if (addedWrong >= wrongCount) break;

      int correctValue = solution[row][col];

      // 다른 숫자로 교체
      List<int> wrongOptions = [];
      for (int n = 1; n <= 9; n++) {
        if (n != correctValue) wrongOptions.add(n);
      }
      wrongOptions.shuffle(_random);

      puzzle[row][col] = wrongOptions.first;
      wrongCells[row][col] = true;
      addedWrong++;
    }

    // 행 합계 계산 (각 행의 맞는 숫자 합)
    final rowSums = List<int>.filled(gridSize, 0);
    for (int row = 1; row < gridSize; row++) {
      int sum = 0;
      for (int col = 1; col < gridSize; col++) {
        sum += solution[row][col]; // 정답 기준 합계
      }
      rowSums[row] = sum;
    }

    // 열 합계 계산 (각 열의 맞는 숫자 합)
    final colSums = List<int>.filled(gridSize, 0);
    for (int col = 1; col < gridSize; col++) {
      int sum = 0;
      for (int row = 1; row < gridSize; row++) {
        sum += solution[row][col]; // 정답 기준 합계
      }
      colSums[col] = sum;
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
