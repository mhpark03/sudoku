import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/samurai_game_state.dart';
import '../services/game_storage.dart';
import 'game_screen.dart';
import 'samurai_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// 일반 스도쿠 시작 (저장된 게임 확인)
  void _startRegularGame(BuildContext context) async {
    final hasSavedGame = await GameStorage.hasRegularGame();

    if (hasSavedGame && context.mounted) {
      _showContinueOrNewDialog(
        context,
        title: '일반 스도쿠',
        onContinue: () async {
          final savedGame = await GameStorage.loadRegularGame();
          if (savedGame != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameScreen(savedGameState: savedGame),
              ),
            );
          }
        },
        onNewGame: () => _showRegularDifficultyDialog(context),
      );
    } else {
      _showRegularDifficultyDialog(context);
    }
  }

  /// 사무라이 스도쿠 시작 (저장된 게임 확인)
  void _startSamuraiGame(BuildContext context) async {
    final hasSavedGame = await GameStorage.hasSamuraiGame();

    if (hasSavedGame && context.mounted) {
      _showContinueOrNewDialog(
        context,
        title: '사무라이 스도쿠',
        onContinue: () async {
          final savedGame = await GameStorage.loadSamuraiGame();
          if (savedGame != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SamuraiGameScreen(savedGameState: savedGame),
              ),
            );
          }
        },
        onNewGame: () => _showSamuraiDifficultyDialog(context),
      );
    } else {
      _showSamuraiDifficultyDialog(context);
    }
  }

  /// 계속하기/새 게임 선택 다이얼로그
  void _showContinueOrNewDialog(
    BuildContext context, {
    required String title,
    required VoidCallback onContinue,
    required VoidCallback onNewGame,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('저장된 게임이 있습니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onNewGame();
            },
            child: const Text('새 게임'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onContinue();
            },
            child: const Text('계속하기'),
          ),
        ],
      ),
    );
  }

  void _showRegularDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('난이도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyTile(context, '쉬움', Difficulty.easy),
            _buildDifficultyTile(context, '보통', Difficulty.medium),
            _buildDifficultyTile(context, '어려움', Difficulty.hard),
            _buildDifficultyTile(context, '달인', Difficulty.expert),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyTile(
      BuildContext context, String label, Difficulty difficulty) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.play_arrow, color: Colors.green),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(initialDifficulty: difficulty),
          ),
        );
      },
    );
  }

  void _showSamuraiDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('난이도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSamuraiDifficultyTile(context, '쉬움', SamuraiDifficulty.easy),
            _buildSamuraiDifficultyTile(
                context, '보통', SamuraiDifficulty.medium),
            _buildSamuraiDifficultyTile(context, '어려움', SamuraiDifficulty.hard),
            _buildSamuraiDifficultyTile(
                context, '달인', SamuraiDifficulty.expert),
          ],
        ),
      ),
    );
  }

  Widget _buildSamuraiDifficultyTile(
      BuildContext context, String label, SamuraiDifficulty difficulty) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.play_arrow, color: Colors.deepPurple),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SamuraiGameScreen(initialDifficulty: difficulty),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '스도쿠',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                _buildGameButton(
                  context,
                  title: '일반 스도쿠',
                  subtitle: '9x9 클래식 스도쿠',
                  icon: Icons.grid_3x3,
                  color: Colors.green,
                  onTap: () => _startRegularGame(context),
                ),
                const SizedBox(height: 20),
                _buildGameButton(
                  context,
                  title: '사무라이 스도쿠',
                  subtitle: '5개 보드가 겹친 스도쿠',
                  icon: Icons.apps,
                  color: Colors.deepPurple,
                  onTap: () => _startSamuraiGame(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
