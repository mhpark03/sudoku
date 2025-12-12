import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/samurai_game_state.dart';
import '../services/game_storage.dart';
import 'game_screen.dart';
import 'samurai_game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasRegularSavedGame = false;
  bool _hasSamuraiSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGames();
  }

  Future<void> _checkSavedGames() async {
    final hasRegular = await GameStorage.hasRegularGame();
    final hasSamurai = await GameStorage.hasSamuraiGame();

    if (mounted) {
      setState(() {
        _hasRegularSavedGame = hasRegular;
        _hasSamuraiSavedGame = hasSamurai;
      });
    }
  }

  /// 저장된 일반 스도쿠 이어하기
  void _continueRegularGame() async {
    final savedGame = await GameStorage.loadRegularGame();
    if (savedGame != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(savedGameState: savedGame),
        ),
      );
      // 게임에서 돌아온 후 저장된 게임 상태 다시 확인
      _checkSavedGames();
    }
  }

  /// 저장된 사무라이 스도쿠 이어하기
  void _continueSamuraiGame() async {
    final savedGame = await GameStorage.loadSamuraiGame();
    if (savedGame != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SamuraiGameScreen(savedGameState: savedGame),
        ),
      );
      // 게임에서 돌아온 후 저장된 게임 상태 다시 확인
      _checkSavedGames();
    }
  }

  /// 일반 스도쿠 새 게임
  void _startRegularGame() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(initialDifficulty: Difficulty.medium),
      ),
    );
    _checkSavedGames();
  }

  /// 사무라이 스도쿠 새 게임
  void _startSamuraiGame() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SamuraiGameScreen(initialDifficulty: SamuraiDifficulty.medium),
      ),
    );
    _checkSavedGames();
  }

  void _showRegularDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('난이도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyTile('쉬움', Difficulty.easy),
            _buildDifficultyTile('보통', Difficulty.medium),
            _buildDifficultyTile('어려움', Difficulty.hard),
            _buildDifficultyTile('달인', Difficulty.expert),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyTile(String label, Difficulty difficulty) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.play_arrow, color: Colors.green),
      onTap: () async {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(initialDifficulty: difficulty),
          ),
        );
        _checkSavedGames();
      },
    );
  }

  void _showSamuraiDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('난이도 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSamuraiDifficultyTile('쉬움', SamuraiDifficulty.easy),
            _buildSamuraiDifficultyTile('보통', SamuraiDifficulty.medium),
            _buildSamuraiDifficultyTile('어려움', SamuraiDifficulty.hard),
          ],
        ),
      ),
    );
  }

  Widget _buildSamuraiDifficultyTile(String label, SamuraiDifficulty difficulty) {
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.play_arrow, color: Colors.deepPurple),
      onTap: () async {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SamuraiGameScreen(initialDifficulty: difficulty),
          ),
        );
        _checkSavedGames();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedGame = _hasRegularSavedGame || _hasSamuraiSavedGame;

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
            child: SingleChildScrollView(
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
                  const SizedBox(height: 40),

                  // 이어하기 섹션 (저장된 게임이 있는 경우에만 표시)
                  if (hasSavedGame) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const Text(
                            '이어하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_hasRegularSavedGame)
                            _buildContinueButton(
                              title: '일반 스도쿠',
                              icon: Icons.grid_3x3,
                              color: Colors.green,
                              onTap: _continueRegularGame,
                            ),
                          if (_hasRegularSavedGame && _hasSamuraiSavedGame)
                            const SizedBox(height: 12),
                          if (_hasSamuraiSavedGame)
                            _buildContinueButton(
                              title: '사무라이 스도쿠',
                              icon: Icons.apps,
                              color: Colors.deepPurple,
                              onTap: _continueSamuraiGame,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white38)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '새 게임',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white38)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 새 게임 버튼들
                  _buildGameButton(
                    title: '일반 스도쿠',
                    subtitle: '9x9 클래식 스도쿠',
                    icon: Icons.grid_3x3,
                    color: Colors.green,
                    onTap: _showRegularDifficultyDialog,
                  ),
                  const SizedBox(height: 20),
                  _buildGameButton(
                    title: '사무라이 스도쿠',
                    subtitle: '5개 보드가 겹친 스도쿠',
                    icon: Icons.apps,
                    color: Colors.deepPurple,
                    onTap: _showSamuraiDifficultyDialog,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.play_circle_filled, size: 28, color: Colors.white),
              const SizedBox(width: 12),
              Icon(icon, size: 24, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameButton({
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
