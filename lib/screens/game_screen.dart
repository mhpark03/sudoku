import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/sudoku_generator.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/number_pad.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  Difficulty _selectedDifficulty = Difficulty.medium;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _gameState = GameState.newGame(_selectedDifficulty);
    });
  }

  void _onCellTap(int row, int col) {
    setState(() {
      // 빠른 입력 모드일 때
      if (_gameState.isQuickInputMode) {
        // 고정 셀이 아니면 빠른 입력 숫자로 입력
        if (!_gameState.isFixed[row][col]) {
          List<List<int>> newBoard =
              _gameState.currentBoard.map((r) => List<int>.from(r)).toList();

          // 같은 숫자면 지우고, 다른 숫자면 입력
          if (newBoard[row][col] == _gameState.quickInputNumber) {
            newBoard[row][col] = 0;
          } else {
            newBoard[row][col] = _gameState.quickInputNumber!;
          }

          bool isComplete = SudokuGenerator.isBoardComplete(newBoard);

          _gameState = _gameState.copyWith(
            currentBoard: newBoard,
            selectedRow: row,
            selectedCol: col,
            isCompleted: isComplete,
          );

          if (isComplete) {
            _showCompletionDialog();
          }
        } else {
          // 고정 셀을 탭하면 선택만
          _gameState = _gameState.copyWith(selectedRow: row, selectedCol: col);
        }
      } else {
        // 일반 모드: 기존 로직
        if (_gameState.selectedRow == row && _gameState.selectedCol == col) {
          _gameState = _gameState.copyWith(clearSelection: true);
        } else {
          _gameState = _gameState.copyWith(selectedRow: row, selectedCol: col);
        }
      }
    });
  }

  void _onNumberTap(int number) {
    setState(() {
      // 빠른 입력 모드일 때: 숫자 선택/해제
      if (_gameState.isQuickInputMode) {
        if (_gameState.quickInputNumber == number) {
          // 같은 숫자를 다시 탭하면 빠른 입력 모드 해제
          _gameState = _gameState.copyWith(clearQuickInput: true);
        } else {
          // 다른 숫자 선택
          _gameState = _gameState.copyWith(quickInputNumber: number);
        }
        return;
      }

      // 일반 모드: 기존 로직
      if (!_gameState.hasSelection) return;

      int row = _gameState.selectedRow!;
      int col = _gameState.selectedCol!;

      if (_gameState.isFixed[row][col]) return;

      List<List<int>> newBoard =
          _gameState.currentBoard.map((r) => List<int>.from(r)).toList();
      newBoard[row][col] = number;

      bool isComplete = SudokuGenerator.isBoardComplete(newBoard);

      _gameState = _gameState.copyWith(
        currentBoard: newBoard,
        isCompleted: isComplete,
      );

      if (isComplete) {
        _showCompletionDialog();
      }
    });
  }

  void _onQuickInputToggle() {
    setState(() {
      if (_gameState.isQuickInputMode) {
        // 빠른 입력 모드 해제
        _gameState = _gameState.copyWith(clearQuickInput: true);
      } else {
        // 빠른 입력 모드 진입 (기본값 1)
        _gameState = _gameState.copyWith(quickInputNumber: 1);
      }
    });
  }

  void _onErase() {
    if (!_gameState.hasSelection) return;

    int row = _gameState.selectedRow!;
    int col = _gameState.selectedCol!;

    if (_gameState.isFixed[row][col]) return;

    setState(() {
      List<List<int>> newBoard =
          _gameState.currentBoard.map((r) => List<int>.from(r)).toList();
      newBoard[row][col] = 0;

      _gameState = _gameState.copyWith(currentBoard: newBoard);
    });
  }

  void _showHint() {
    if (!_gameState.hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('셀을 먼저 선택하세요')),
      );
      return;
    }

    int row = _gameState.selectedRow!;
    int col = _gameState.selectedCol!;

    if (_gameState.isFixed[row][col]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 채워진 칸입니다')),
      );
      return;
    }

    int correctValue = _gameState.solution[row][col];

    setState(() {
      List<List<int>> newBoard =
          _gameState.currentBoard.map((r) => List<int>.from(r)).toList();
      newBoard[row][col] = correctValue;

      bool isComplete = SudokuGenerator.isBoardComplete(newBoard);

      _gameState = _gameState.copyWith(
        currentBoard: newBoard,
        isCompleted: isComplete,
      );

      if (isComplete) {
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('축하합니다! 🎉'),
        content: const Text('스도쿠를 완성했습니다!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('새 게임'),
          ),
        ],
      ),
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('난이도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Difficulty.values.map((difficulty) {
            String label;
            switch (difficulty) {
              case Difficulty.easy:
                label = '쉬움';
                break;
              case Difficulty.medium:
                label = '보통';
                break;
              case Difficulty.hard:
                label = '어려움';
                break;
            }
            return ListTile(
              title: Text(label),
              leading: Icon(
                _selectedDifficulty == difficulty
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Colors.blue,
              ),
              onTap: () {
                setState(() {
                  _selectedDifficulty = difficulty;
                });
                Navigator.pop(context);
                _startNewGame();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getDifficultyText() {
    switch (_selectedDifficulty) {
      case Difficulty.easy:
        return '쉬움';
      case Difficulty.medium:
        return '보통';
      case Difficulty.hard:
        return '어려움';
    }
  }

  Widget _buildControls({required bool isLandscape}) {
    if (isLandscape) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _startNewGame,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('새 게임', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb, size: 16),
                  label: const Text('힌트', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            NumberPad(
              onNumberTap: _onNumberTap,
              onErase: _onErase,
              isCompact: true,
              quickInputNumber: _gameState.quickInputNumber,
              onQuickInputToggle: _onQuickInputToggle,
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _startNewGame,
                icon: const Icon(Icons.refresh),
                label: const Text('새 게임'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showHint,
                icon: const Icon(Icons.lightbulb),
                label: const Text('힌트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          NumberPad(
            onNumberTap: _onNumberTap,
            onErase: _onErase,
            isCompact: false,
            quickInputNumber: _gameState.quickInputNumber,
            onQuickInputToggle: _onQuickInputToggle,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('스도쿠'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        toolbarHeight: isLandscape ? 45 : kToolbarHeight,
        actions: [
          TextButton(
            onPressed: _showDifficultyDialog,
            child: Text(
              _getDifficultyText(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 8.0 : 16.0),
          child: isLandscape
              ? Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: SudokuBoard(
                            gameState: _gameState,
                            onCellTap: _onCellTap,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildControls(isLandscape: true),
                    ),
                  ],
                )
              : Column(
                  children: [
                    SudokuBoard(
                      gameState: _gameState,
                      onCellTap: _onCellTap,
                    ),
                    const SizedBox(height: 20),
                    _buildControls(isLandscape: false),
                  ],
                ),
        ),
      ),
    );
  }
}
