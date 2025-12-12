import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/sudoku_generator.dart';
import '../services/game_storage.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/game_control_panel.dart';

class GameScreen extends StatefulWidget {
  final Difficulty? initialDifficulty;
  final GameState? savedGameState;

  const GameScreen({
    super.key,
    this.initialDifficulty,
    this.savedGameState,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  late Difficulty _selectedDifficulty;
  bool _isLoading = true;
  final GlobalKey<GameControlPanelState> _controlPanelKey = GlobalKey();

  // 빠른 입력 모드 상태 (하이라이트용)
  bool _isQuickInputMode = false;
  int? _quickInputNumber;
  bool _isEraseMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.savedGameState != null) {
      // 저장된 게임 불러오기
      _gameState = widget.savedGameState!;
      _selectedDifficulty = _gameState.difficulty;
      _isLoading = false;
    } else {
      // 새 게임 시작
      _selectedDifficulty = widget.initialDifficulty ?? Difficulty.medium;
      _startNewGame();
    }
  }

  Future<void> _startNewGame() async {
    // 새 게임 시작 시 모든 저장된 게임 삭제
    await GameStorage.deleteAllGames();

    setState(() {
      _isLoading = true;
    });

    // 별도 isolate에서 퍼즐 생성 (메인 스레드 블로킹 방지)
    final data = await compute(
      generatePuzzleInIsolate,
      _selectedDifficulty,
    );

    if (mounted) {
      setState(() {
        _gameState = GameState.fromGeneratedData(data);
        _isLoading = false;
      });
      _saveGame();
    }
  }

  /// 게임 상태 저장
  void _saveGame() {
    if (!_gameState.isCompleted) {
      GameStorage.saveRegularGame(_gameState);
    } else {
      // 게임 완료 시 저장된 게임 삭제
      GameStorage.deleteRegularGame();
    }
  }

  void _onCellTap(int row, int col) {
    final controlState = _controlPanelKey.currentState;
    if (controlState == null) return;

    setState(() {
      // 지우기 모드일 때
      if (controlState.isEraseMode) {
        if (!_gameState.isFixed[row][col]) {
          if (_gameState.currentBoard[row][col] != 0) {
            // 값이 있으면 값 지우기
            List<List<int>> newBoard =
                _gameState.currentBoard.map((r) => List<int>.from(r)).toList();
            newBoard[row][col] = 0;
            _gameState = _gameState.copyWith(
              currentBoard: newBoard,
              selectedRow: row,
              selectedCol: col,
            );
          } else {
            // 값이 없으면 메모 지우기
            _gameState.clearNotes(row, col);
            _gameState = _gameState.copyWith(selectedRow: row, selectedCol: col);
          }
        } else {
          _gameState = _gameState.copyWith(selectedRow: row, selectedCol: col);
        }
      }
      // 빠른 입력 모드일 때
      else if (controlState.isQuickInputMode && controlState.quickInputNumber != null) {
        // 고정 셀이 아니면 빠른 입력 숫자로 입력
        if (!_gameState.isFixed[row][col]) {
          // 빠른 입력 + 메모 모드: 메모로 입력
          if (controlState.isNoteMode) {
            if (_gameState.currentBoard[row][col] == 0) {
              _gameState.toggleNote(row, col, controlState.quickInputNumber!);
              _gameState = _gameState.copyWith(selectedRow: row, selectedCol: col);
            }
          } else {
            // 빠른 입력 모드만: 일반 숫자 입력
            List<List<int>> newBoard =
                _gameState.currentBoard.map((r) => List<int>.from(r)).toList();

            // 같은 숫자면 지우고, 다른 숫자면 입력
            if (newBoard[row][col] == controlState.quickInputNumber) {
              newBoard[row][col] = 0;
            } else {
              int number = controlState.quickInputNumber!;
              newBoard[row][col] = number;

              // 유효한 입력이면 같은 행/열/박스의 메모에서 해당 숫자 삭제
              if (SudokuGenerator.isValidMove(newBoard, row, col, number)) {
                _gameState.removeNumberFromRelatedNotes(row, col, number);
                _gameState.clearNotes(row, col);
              }
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
    _saveGame();
  }

  void _onNumberTap(int number, bool isNoteMode) {
    setState(() {
      // 일반 모드: 기존 로직
      if (!_gameState.hasSelection) return;

      int row = _gameState.selectedRow!;
      int col = _gameState.selectedCol!;

      if (_gameState.isFixed[row][col]) return;

      // 메모 모드일 때
      if (isNoteMode) {
        if (_gameState.currentBoard[row][col] == 0) {
          _gameState.toggleNote(row, col, number);
        }
        return;
      }

      // 일반 입력 모드
      List<List<int>> newBoard =
          _gameState.currentBoard.map((r) => List<int>.from(r)).toList();
      newBoard[row][col] = number;

      // 유효한 입력이면 같은 행/열/박스의 메모에서 해당 숫자 삭제
      if (SudokuGenerator.isValidMove(newBoard, row, col, number)) {
        _gameState.removeNumberFromRelatedNotes(row, col, number);
        _gameState.clearNotes(row, col);
      }

      bool isComplete = SudokuGenerator.isBoardComplete(newBoard);

      _gameState = _gameState.copyWith(
        currentBoard: newBoard,
        isCompleted: isComplete,
      );

      if (isComplete) {
        _showCompletionDialog();
      }
    });
    _saveGame();
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
    _saveGame();
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

      // 같은 행/열/박스의 메모에서 해당 숫자 삭제
      _gameState.removeNumberFromRelatedNotes(row, col, correctValue);
      _gameState.clearNotes(row, col);

      bool isComplete = SudokuGenerator.isBoardComplete(newBoard);

      _gameState = _gameState.copyWith(
        currentBoard: newBoard,
        isCompleted: isComplete,
      );

      if (isComplete) {
        _showCompletionDialog();
      }
    });
    _saveGame();
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
              case Difficulty.expert:
                label = '달인';
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
      case Difficulty.expert:
        return '달인';
    }
  }

  Widget _buildControls({required bool isLandscape}) {
    return GameControlPanel(
      key: _controlPanelKey,
      onNumberTap: _onNumberTap,
      onErase: _onErase,
      onHint: _showHint,
      onFillAllNotes: _onFillAllNotes,
      onQuickInputModeChanged: (isQuickInput, number) {
        setState(() {
          _isQuickInputMode = isQuickInput;
          _quickInputNumber = number;
          // 빠른 입력 모드에서 숫자 선택 시 셀 선택 초기화
          if (isQuickInput && number != null) {
            _gameState = _gameState.copyWith(clearSelection: true);
          }
        });
      },
      onEraseModeChanged: (isErase) {
        setState(() {
          _isEraseMode = isErase;
        });
      },
      disabledNumbers: _gameState.getCompletedNumbers(),
      isCompact: isLandscape,
    );
  }

  void _onFillAllNotes() {
    setState(() {
      _gameState.fillAllNotes();
    });
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
          TextButton.icon(
            onPressed: _showDifficultyDialog,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            label: const Text(
              '새 게임',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('퍼즐 생성 중...'),
                ],
              ),
            )
          : SafeArea(
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
                            isQuickInputMode: _isQuickInputMode,
                            quickInputNumber: _quickInputNumber,
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
                      isQuickInputMode: _isQuickInputMode,
                      quickInputNumber: _quickInputNumber,
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
