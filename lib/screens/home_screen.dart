import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/samurai_game_state.dart';
import 'game_screen.dart';
import 'samurai_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  onTap: () => _showRegularDifficultyDialog(context),
                ),
                const SizedBox(height: 20),
                _buildGameButton(
                  context,
                  title: '사무라이 스도쿠',
                  subtitle: '5개 보드가 겹친 스도쿠',
                  icon: Icons.apps,
                  color: Colors.deepPurple,
                  onTap: () => _showSamuraiDifficultyDialog(context),
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
