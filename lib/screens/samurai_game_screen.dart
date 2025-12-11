import 'package:flutter/material.dart';
import '../models/samurai_game_state.dart';
import '../models/samurai_sudoku_generator.dart';
import '../widgets/samurai_board.dart';
import 'expanded_board_screen.dart';

class SamuraiGameScreen extends StatefulWidget {
  const SamuraiGameScreen({super.key});

  @override
  State<SamuraiGameScreen> createState() => _SamuraiGameScreenState();
}

class _SamuraiGameScreenState extends State<SamuraiGameScreen> {
  late SamuraiGameState _gameState;
  SamuraiDifficulty _selectedDifficulty = SamuraiDifficulty.medium;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  Future<void> _startNewGame() async {
    setState(() {
      _isLoading = true;
    });

    // 생성이 무거우므로 비동기 처리
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _gameState = SamuraiGameState.newGame(_selectedDifficulty);
      _isLoading = false;
    });
  }

  void _onBoardSelect(int boardIndex) {
    setState(() {
      _gameState = _gameState.copyWith(
        selectedBoard: boardIndex,
        clearSelection: true,
      );
    });
  }

  void _onCellTap(int board, int row, int col) {
    // 셀 탭 시 확대 다이얼로그 표시
    _showExpandedBoard(board, row, col);
  }

  void _showExpandedBoard(int board, int? row, int? col) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpandedBoardScreen(
          gameState: _gameState,
          boardIndex: board,
          initialRow: row,
          initialCol: col,
          onValueChanged: (b, r, c, value) {
            setState(() {
              _gameState.currentBoards[b][r][c] = value;
              _gameState.syncOverlapValue(b, r, c, value);
              // 값 입력 시 해당 셀의 메모 삭제
              if (value != 0) {
                _gameState.clearNotes(b, r, c);
              }
            });
          },
          onHint: (b, r, c) {
            int correctValue = _gameState.solutions[b][r][c];
            setState(() {
              _gameState.currentBoards[b][r][c] = correctValue;
              _gameState.syncOverlapValue(b, r, c, correctValue);
              _gameState.clearNotes(b, r, c);
            });
          },
          onNoteToggle: (b, r, c, number) {
            setState(() {
              _gameState.toggleNote(b, r, c, number);
            });
          },
          onFillAllNotes: (b) {
            setState(() {
              _gameState.fillAllNotes(b);
            });
          },
          onComplete: () {
            _showCompletionDialog();
          },
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('축하합니다! 🎉'),
        content: const Text('사무라이 스도쿠를 완성했습니다!'),
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
          children: SamuraiDifficulty.values.map((difficulty) {
            String label;
            switch (difficulty) {
              case SamuraiDifficulty.easy:
                label = '쉬움';
                break;
              case SamuraiDifficulty.medium:
                label = '보통';
                break;
              case SamuraiDifficulty.hard:
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
      case SamuraiDifficulty.easy:
        return '쉬움';
      case SamuraiDifficulty.medium:
        return '보통';
      case SamuraiDifficulty.hard:
        return '어려움';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('사무라이 스도쿠'),
        backgroundColor: Colors.deepPurple,
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
                padding: EdgeInsets.all(isLandscape ? 4.0 : 8.0),
                child: isLandscape
                    ? _buildLandscapeLayout()
                    : _buildPortraitLayout(),
              ),
            ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // 안내 텍스트
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '셀을 탭하면 편집 화면으로 이동합니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        // 사무라이 보드
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: SamuraiBoard(
                gameState: _gameState,
                onCellTap: _onCellTap,
                onBoardSelect: _onBoardSelect,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 컨트롤 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _startNewGame(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('새 게임'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // 사무라이 보드
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Text(
                '셀을 탭하면 편집 화면으로 이동합니다',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: SamuraiBoard(
                      gameState: _gameState,
                      onCellTap: _onCellTap,
                      onBoardSelect: _onBoardSelect,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 컨트롤
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _startNewGame(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('새 게임', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
