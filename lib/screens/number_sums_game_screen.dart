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
      _selectedDifficulty =
          widget.initialDifficulty ?? NumberSumsDifficulty.medium;
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
    if (_gameState.cellTypes[row][col] != 1) return;
    if (_gameState.currentBoard[row][col] == 0) return; // 이미 제거된 셀

    setState(() {
      _gameState = _gameState.copyWith(selectedRow: row, selectedCol: col);
    });
  }

  void _onErase() {
    if (_isPaused) return;
    if (!_gameState.hasSelection) return;

    int row = _gameState.selectedRow!;
    int col = _gameState.selectedCol!;

    if (_gameState.currentBoard[row][col] == 0) return; // 이미 비어있음

    setState(() {
      // Undo 저장
      _gameState.saveToUndoHistory(row, col);

      // 올바른 숫자를 지웠는지 확인
      bool isWrong = _gameState.isWrongCell(row, col);
      if (!isWrong) {
        // 올바른 숫자를 지움 -> 실패!
        _failureCount++;
      }

      // 숫자 제거
      List<List<int>> newBoard =
          _gameState.currentBoard.map((r) => List<int>.from(r)).toList();
      newBoard[row][col] = 0;

      // 완성 체크
      bool isComplete = NumberSumsGenerator.isBoardComplete(
        newBoard,
        _gameState.solution,
        _gameState.cellTypes,
        _gameState.gridSize,
      );

      _gameState = _gameState.copyWith(
        currentBoard: newBoard,
        isCompleted: isComplete,
        clearSelection: true,
      );

      if (isComplete) {
        _timer?.cancel();
        _showCompletionDialog();
      }
    });
    _saveGame();
  }

  void _onUndo() {
    if (_isPaused) return;

    final undoItem = _gameState.popFromUndoHistory();
    if (undoItem != null) {
      setState(() {
        _gameState = _gameState.copyWith(
          selectedRow: undoItem.row,
          selectedCol: undoItem.col,
        );
      });
      _saveGame();
    }
  }

  void _showCompletionDialog() {
    String timeStr = _formatTime(_elapsedSeconds);
    GameStorage.deleteNumberSumsGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('축하합니다!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('모든 틀린 숫자를 제거했습니다!'),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: 8),
                Text('소요 시간: $timeStr'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.close, size: 18, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Text('실패 횟수: $_failureCount회'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDifficultyDialog();
            },
            child: const Text('새 게임'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          '넘버 썸즈',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showDifficultyDialog,
            icon: const Icon(Icons.refresh),
            tooltip: '새 게임',
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
                  Text(
                    '퍼즐 생성 중...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  _buildStatusBar(),
                  const SizedBox(height: 8),
                  _buildHelpText(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
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
                  _buildToolBar(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                _formatTime(_elapsedSeconds),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          // Difficulty
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getDifficultyLabel(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.deepOrange,
              ),
            ),
          ),
          // Failure count
          Row(
            children: [
              Icon(Icons.close, size: 20, color: Colors.red.shade300),
              const SizedBox(width: 4),
              Text(
                '$_failureCount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade300,
                ),
              ),
            ],
          ),
          // Pause button
          IconButton(
            onPressed: _togglePause,
            icon: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    final remainingWrong = _gameState.remainingWrongCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '틀린 숫자를 찾아서 지우세요! (남은 개수: $remainingWrong)',
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getDifficultyLabel() {
    switch (_selectedDifficulty) {
      case NumberSumsDifficulty.easy:
        return '쉬움';
      case NumberSumsDifficulty.medium:
        return '보통';
      case NumberSumsDifficulty.hard:
        return '어려움';
    }
  }

  Widget _buildToolBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            icon: Icons.undo,
            label: '되돌리기',
            onTap: _onUndo,
          ),
          _buildToolButton(
            icon: Icons.backspace_outlined,
            label: '지우기',
            onTap: _onErase,
            isHighlighted: _gameState.hasSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isHighlighted
              ? Colors.deepOrange.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted
              ? Border.all(color: Colors.deepOrange, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isHighlighted ? Colors.deepOrange : Colors.white70,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? Colors.deepOrange : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pause_circle_outline,
                size: 64,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                '일시정지',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '재개 버튼을 눌러 계속하세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
