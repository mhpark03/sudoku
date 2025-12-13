import 'dart:math';

enum NumberSumsDifficulty { easy, medium, hard }

class NumberSumsGenerator {
  final Random _random = Random();

  Map<String, dynamic> generatePuzzle(NumberSumsDifficulty difficulty) {
    int gameSize;
    double fillRatio; // 정답 셀 비율
    int blockCount; // 블록 개수

    switch (difficulty) {
      case NumberSumsDifficulty.easy:
        gameSize = 5;
        fillRatio = 0.6; // 60% 정답 셀
        blockCount = 6;
        break;
      case NumberSumsDifficulty.medium:
        gameSize = 6;
        fillRatio = 0.55;
        blockCount = 8;
        break;
      case NumberSumsDifficulty.hard:
        gameSize = 7;
        fillRatio = 0.5;
        blockCount = 10;
        break;
    }

    return _generateEliminationPuzzle(gameSize, difficulty, fillRatio, blockCount);
  }

  Map<String, dynamic> _generateEliminationPuzzle(
      int gameSize, NumberSumsDifficulty difficulty, double fillRatio, int blockCount) {
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

    // 4. 블록 생성 (연결된 셀들을 그룹화)
    final blockIds = List.generate(
      gridSize,
      (row) => List.generate(gridSize, (col) => -1),
    );
    final blockSums = <int>[]; // 각 블록의 정답 합계

    _generateBlocks(blockIds, solution, gridSize, blockCount, blockSums);

    return {
      'solution': solution,
      'puzzle': puzzle,
      'cellTypes': cellTypes,
      'wrongCells': wrongCells.map((row) => row.map((v) => v ? 1 : 0).toList()).toList(),
      'rowSums': rowSums,
      'colSums': colSums,
      'blockIds': blockIds,
      'blockSums': blockSums,
      'gridSize': gridSize,
      'gameSize': gameSize,
      'difficulty': difficulty.index,
    };
  }

  /// 블록 생성 (연결된 셀들을 그룹화)
  void _generateBlocks(
    List<List<int>> blockIds,
    List<List<int>> solution,
    int gridSize,
    int blockCount,
    List<int> blockSums,
  ) {
    // 게임 영역의 모든 셀을 수집
    final unassigned = <(int, int)>[];
    for (int row = 1; row < gridSize; row++) {
      for (int col = 1; col < gridSize; col++) {
        unassigned.add((row, col));
      }
    }

    final totalCells = unassigned.length;
    final avgBlockSize = totalCells ~/ blockCount;

    int currentBlockId = 0;

    while (unassigned.isNotEmpty && currentBlockId < blockCount) {
      // 남은 블록 수
      int remainingBlocks = blockCount - currentBlockId;

      // 이 블록의 크기 결정
      int blockSize;
      if (remainingBlocks == 1) {
        blockSize = unassigned.length;
      } else {
        // 평균 크기 주변에서 랜덤하게
        int minSize = max(2, avgBlockSize - 2);
        int maxSize = min(unassigned.length - (remainingBlocks - 1) * 2, avgBlockSize + 2);
        maxSize = max(maxSize, minSize);
        blockSize = minSize + _random.nextInt(maxSize - minSize + 1);
      }

      // 시작점 선택
      final startIdx = _random.nextInt(unassigned.length);
      final start = unassigned[startIdx];
      unassigned.removeAt(startIdx);

      blockIds[start.$1][start.$2] = currentBlockId;
      final blockCells = [start];
      int blockSum = solution[start.$1][start.$2];

      // BFS로 인접 셀 추가
      while (blockCells.length < blockSize && unassigned.isNotEmpty) {
        // 현재 블록에 인접한 미할당 셀 찾기
        final adjacentCells = <(int, int)>[];
        for (final cell in blockCells) {
          final neighbors = [
            (cell.$1 - 1, cell.$2),
            (cell.$1 + 1, cell.$2),
            (cell.$1, cell.$2 - 1),
            (cell.$1, cell.$2 + 1),
          ];
          for (final neighbor in neighbors) {
            if (unassigned.contains(neighbor)) {
              adjacentCells.add(neighbor);
            }
          }
        }

        if (adjacentCells.isEmpty) break;

        // 인접 셀 중 하나 선택
        final nextCell = adjacentCells[_random.nextInt(adjacentCells.length)];
        unassigned.remove(nextCell);
        blockIds[nextCell.$1][nextCell.$2] = currentBlockId;
        blockCells.add(nextCell);
        blockSum += solution[nextCell.$1][nextCell.$2];
      }

      blockSums.add(blockSum);
      currentBlockId++;
    }

    // 남은 셀이 있으면 가장 가까운 블록에 할당
    while (unassigned.isNotEmpty) {
      final cell = unassigned.removeAt(0);

      // 인접한 블록 찾기
      int nearestBlockId = 0;
      final neighbors = [
        (cell.$1 - 1, cell.$2),
        (cell.$1 + 1, cell.$2),
        (cell.$1, cell.$2 - 1),
        (cell.$1, cell.$2 + 1),
      ];

      for (final neighbor in neighbors) {
        if (neighbor.$1 >= 1 && neighbor.$1 < gridSize &&
            neighbor.$2 >= 1 && neighbor.$2 < gridSize &&
            blockIds[neighbor.$1][neighbor.$2] >= 0) {
          nearestBlockId = blockIds[neighbor.$1][neighbor.$2];
          break;
        }
      }

      blockIds[cell.$1][cell.$2] = nearestBlockId;
      blockSums[nearestBlockId] += solution[cell.$1][cell.$2];
    }
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
