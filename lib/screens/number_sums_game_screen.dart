import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/number_sums_game_state.dart';
import '../models/number_sums_generator.dart';
import '../services/game_storage.dart';
import '../widgets/number_sums_board.dart';

class NumberSumsGameScreen extends StatefulWidget {
  final NumberSumsDifficulty? initialDifficulty;
  final NumberSumsGameState? savedGameState;

  const NumberSumsGameScreen({
    super.key,
    this.initialDifficulty,
    this.savedGameState,
  });

  @override
  State<NumberSumsGameScreen> createState() => _NumberSumsGameScreenState();
}

class _NumberSumsGameScreenState extends State<NumberSumsGameScreen>
    with WidgetsBindingObserver {
  late NumberSumsGameState _gameState;
  late NumberSumsDifficulty _selectedDifficulty;
  bool _isLoading = true;

  // 게임 타이머 및 통계
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _failureCount = 0;
  bool _isPaused = false;
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.savedGameState != null) {
      _gameState = widget.savedGameState!;
      _selectedDifficulty = _gameState.difficulty;
      _elapsedSeconds = _gameState.elapsedSeconds;
      _failureCount = _gameState.failureCount;
      _isLoading = false;
      _startTimer();
    } else {
      _selectedDifficulty = widget.initialDifficulty ?? NumberSumsDifficulty.medium;
      _startNewGame();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!_isLoading && !_gameState.isCompleted) {
        setState(() {
          _isBackgrounded = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _isBackgrounded = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isBackgrounded && !_gameState.isCompleted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _startNewGame() async {
    await GameStorage.deleteAllGames();

    setState(() {
      _isLoading = true;
    });

    final data = await compute(
      generateNumberSumsPuzzleInIsolate,
      _selectedDifficulty,
    );

    if (mounted) {
      setState(() {
        _gameState = NumberSumsGameState.fromGeneratedData(data);
        _isLoading = false;
        _elapsedSeconds = 0;
        _failureCount = 0;
        _isPaused = false;
      });
      _startTimer();
      _saveGame();
    }
  }

  void _saveGame() {
    if (!_gameState.isCompleted) {
      _gameState.elapsedSeconds = _elapsedSeconds;
      _gameState.failureCount = _failureCount;
      GameStorage.saveNumberSumsGame(_gameState);
    } else {
      GameStorage.deleteNumberSumsGame();
    }
  }

  void _onCellTap(int row, int col) {
    if (_isPaused) return;

    // Only allow tapping input cells
    if (_gameState.cellTypes[row][col] != 1) return;

    setState(() {
      // 같은 셀을 다시 탭하면 숫자 선택 다이얼로그 표시
      if (_gameState.selectedRow == row && _gameState.selectedCol == col) {
        _showNumberPicker(row, col);
      } else {
        // 다른 셀 선택
        _gameState = _gameState.copyWith(selectedRow: row, selectedCol: col);
      }
    });
  }

  void _showNumberPicker(int row, int col) {
    if (_gameState.isFixed(row, col)) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '숫자 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(9, (index) {
                final number = index + 1;
                return _buildNumberButton(number, row, col);
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(int number, int row, int col) {
    final isCurrentValue = _gameState.currentBoard[row][col] == number;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _inputNumber(row, col, number);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isCurrentValue ? Colors.deepOrange.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentValue ? Colors.deepOrange : Colors.grey.shade300,
            width: isCurrentValue ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isCurrentValue ? Colors.deepOrange : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  void _inputNumber(int row, int col, int number) {
    setState(() {
      int correctValue = _gameState.solution[row][col];
      if (number != correctValue) {
        _failureCount++;
      }

      _gameState.saveToUndoHistory(row, col, numberToInput: number);

      List<List<int>> newBoard =
          _gameState.currentBoard.map((r) => List<int>.from(r)).toList();
      newBoard[row][col] = number;

      if (NumberSumsGenerator.isValidMove(
        newBoard,
        _gameState.cellTypes,
        _gameState.clues,
        row,
        col,
        number,
        _gameState.gridSize,
      )) {
        _gameState.removeNumberFromRelatedNotes(row, col, number);
        _gameState.clearNotes(row, col);
      }

      bool isComplete = NumberSumsGenerator.isBoardComplete(
        newBoard,
        _gameState.cellTypes,
        _gameState.clues,
        _gameState.gridSize,
      );

      _gameState = _gameState.copyWith(
        currentBoard: newBoard,
        isCompleted: isComplete,
      );

      if (isComplete) {
        _timer?.cancel();
        _showCompletionDialog();
      }
    });
    _saveGame();
  }

  void _onErase() {
    if (_isPaused) return;

    if (!_gameState.hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('셀을 먼저 선택하세요')),
      );
      return;
    }

    int row = _gameState.selectedRow!;
    int col = _gameState.selectedCol!;

    if (_gameState.isFixed(row, col)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('초기 값은 지울 수 없습니다')),
      );
      return;
    }

    if (_gameState.currentBoard[row][col] == 0) return;

    setState(() {
      _gameState.saveToUndoHistory(row, col);
      List<List<int>> newBoard =
          _gameState.currentBoard.map((r) => List<int>.from(r)).toList();
      newBoard[row][col] = 0;
      _gameState = _gameState.copyWith(currentBoard: newBoard);
    });
    _saveGame();
  }

  void _showCompletionDialog() {
    String timeStr = _formatTime(_elapsedSeconds);
    GameStorage.deleteNumberSumsGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('축하합니다!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('넘버 썸즈를 완성했습니다!'),
            const SizedBox(height: 16),
            Text('소요 시간: $timeStr'),
            Text('실패 횟수: $_failureCount회'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('난이도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NumberSumsDifficulty.values.map((difficulty) {
            String label;
            switch (difficulty) {
              case NumberSumsDifficulty.easy:
                label = '쉬움 (6x6)';
                break;
              case NumberSumsDifficulty.medium:
                label = '보통 (8x8)';
                break;
              case NumberSumsDifficulty.hard:
                label = '어려움 (10x10)';
                break;
            }
            return ListTile(
              title: Text(label),
              leading: Icon(
                _selectedDifficulty == difficulty
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Colors.deepOrange,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('넘버 썸즈'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
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
                  CircularProgressIndicator(color: Colors.deepOrange),
                  SizedBox(height: 16),
                  Text('퍼즐 생성 중...'),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // 상태 바
                  _buildStatusBar(),
                  // 게임 보드
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: _isPaused
                            ? _buildPausedOverlay()
                            : NumberSumsBoard(
                                gameState: _gameState,
                                onCellTap: _onCellTap,
                              ),
                      ),
                    ),
                  ),
                  // 간단한 컨트롤 버튼
                  _buildSimpleControls(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 타이머
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                _formatTime(_elapsedSeconds),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // 실패 횟수
          Row(
            children: [
              Icon(Icons.close, size: 20, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text(
                '$_failureCount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
          // 일시정지 버튼
          IconButton(
            onPressed: _togglePause,
            icon: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.deepOrange,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 선택 버튼 (숫자 입력)
          _buildControlButton(
            icon: Icons.edit_outlined,
            label: '선택',
            onTap: () {
              if (_gameState.hasSelection) {
                _showNumberPicker(_gameState.selectedRow!, _gameState.selectedCol!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('셀을 먼저 선택하세요')),
                );
              }
            },
          ),
          // 제거 버튼
          _buildControlButton(
            icon: Icons.backspace_outlined,
            label: '제거',
            onTap: _onErase,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_outline,
              size: 64,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            Text(
              '일시정지',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '재개 버튼을 눌러 계속하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
