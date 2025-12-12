import 'dart:math';
import 'killer_game_state.dart';

class KillerSudokuGenerator {
  final Random _random = Random();

  /// 킬러 스도쿠 퍼즐 생성
  Map<String, dynamic> generatePuzzle(KillerDifficulty difficulty) {
    // 1. 완성된 스도쿠 보드 생성
    List<List<int>> solution = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(solution);

    // 2. 케이지 생성
    List<Cage> cages = _generateCages(solution, difficulty);

    // 3. 난이도에 따라 힌트 개수 결정
    int hintCount;
    switch (difficulty) {
      case KillerDifficulty.easy:
        hintCount = 15; // 쉬움: 15개의 힌트
        break;
      case KillerDifficulty.medium:
        hintCount = 8; // 보통: 8개의 힌트
        break;
      case KillerDifficulty.hard:
        hintCount = 0; // 어려움: 힌트 없음
        break;
    }

    // 4. 퍼즐 생성 (힌트 셀만 남기고 나머지는 0)
    List<List<int>> puzzle = List.generate(9, (_) => List.filled(9, 0));

    if (hintCount > 0) {
      // 무작위로 힌트 셀 선택
      List<int> positions = List.generate(81, (i) => i)..shuffle(_random);
      for (int i = 0; i < hintCount && i < positions.length; i++) {
        int pos = positions[i];
        int row = pos ~/ 9;
        int col = pos % 9;
        puzzle[row][col] = solution[row][col];
      }
    }

    return {
      'solution': solution,
      'puzzle': puzzle,
      'cages': cages,
    };
  }

  /// 케이지 생성
  List<Cage> _generateCages(List<List<int>> solution, KillerDifficulty difficulty) {
    List<Cage> cages = [];
    List<List<bool>> assigned = List.generate(9, (_) => List.filled(9, false));

    // 케이지 크기 범위 (난이도에 따라)
    int minCageSize;
    int maxCageSize;
    switch (difficulty) {
      case KillerDifficulty.easy:
        minCageSize = 2;
        maxCageSize = 4;
        break;
      case KillerDifficulty.medium:
        minCageSize = 2;
        maxCageSize = 5;
        break;
      case KillerDifficulty.hard:
        minCageSize = 2;
        maxCageSize = 6;
        break;
    }

    // 모든 셀이 케이지에 할당될 때까지 반복
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (!assigned[row][col]) {
          // 새 케이지 생성
          List<(int, int)> cageCells = [];
          int targetSize = minCageSize + _random.nextInt(maxCageSize - minCageSize + 1);

          // BFS로 연결된 셀들 추가
          _buildCage(row, col, assigned, cageCells, targetSize, solution);

          if (cageCells.isNotEmpty) {
            // 케이지 합계 계산
            int sum = 0;
            for (final cell in cageCells) {
              sum += solution[cell.$1][cell.$2];
              assigned[cell.$1][cell.$2] = true;
            }
            cages.add(Cage(sum: sum, cells: cageCells));
          }
        }
      }
    }

    return cages;
  }

  /// BFS로 케이지 생성
  void _buildCage(int startRow, int startCol, List<List<bool>> assigned,
      List<(int, int)> cageCells, int targetSize, List<List<int>> solution) {
    if (assigned[startRow][startCol]) return;

    // 케이지에 사용된 숫자 추적 (중복 방지)
    Set<int> usedNumbers = {};

    // 후보 셀 목록 (현재 셀에서 시작)
    List<(int, int)> candidates = [(startRow, startCol)];

    while (cageCells.length < targetSize && candidates.isNotEmpty) {
      // 후보 중에서 무작위로 선택
      int idx = _random.nextInt(candidates.length);
      var (row, col) = candidates.removeAt(idx);

      if (assigned[row][col]) continue;

      int value = solution[row][col];

      // 케이지 내 중복 숫자 방지
      if (usedNumbers.contains(value)) continue;

      // 셀 추가
      cageCells.add((row, col));
      usedNumbers.add(value);
      assigned[row][col] = true;

      // 인접한 미할당 셀들을 후보에 추가
      List<(int, int)> neighbors = _getUnassignedNeighbors(row, col, assigned);
      for (var neighbor in neighbors) {
        if (!candidates.contains(neighbor)) {
          candidates.add(neighbor);
        }
      }
    }
  }

  /// 인접한 미할당 셀 목록 반환
  List<(int, int)> _getUnassignedNeighbors(int row, int col, List<List<bool>> assigned) {
    List<(int, int)> neighbors = [];

    // 상하좌우
    List<(int, int)> directions = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    for (var (dr, dc) in directions) {
      int newRow = row + dr;
      int newCol = col + dc;

      if (newRow >= 0 && newRow < 9 && newCol >= 0 && newCol < 9) {
        if (!assigned[newRow][newCol]) {
          neighbors.add((newRow, newCol));
        }
      }
    }

    // 무작위로 섞기
    neighbors.shuffle(_random);
    return neighbors;
  }

  /// 완성된 스도쿠 보드 생성
  bool _fillBoard(List<List<int>> board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board[row][col] == 0) {
          List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_random);
          for (int num in numbers) {
            if (_isValid(board, row, col, num)) {
              board[row][col] = num;
              if (_fillBoard(board)) {
                return true;
              }
              board[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// 유효한 배치인지 확인
  bool _isValid(List<List<int>> board, int row, int col, int num) {
    // 행 검사
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == num) return false;
    }

    // 열 검사
    for (int i = 0; i < 9; i++) {
      if (board[i][col] == num) return false;
    }

    // 3x3 박스 검사
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[boxRow + i][boxCol + j] == num) return false;
      }
    }

    return true;
  }
}
