import 'package:flutter/material.dart';

/// 게임 상태 표시 바 (시간, 실패 횟수, 일시정지 버튼)
class GameStatusBar extends StatelessWidget {
  /// 경과 시간 (초)
  final int elapsedSeconds;

  /// 실패 횟수
  final int failureCount;

  /// 일시정지 상태
  final bool isPaused;

  /// 일시정지 토글 콜백
  final VoidCallback onPauseToggle;

  /// 컴팩트 모드 (가로 모드)
  final bool isCompact;

  const GameStatusBar({
    super.key,
    required this.elapsedSeconds,
    required this.failureCount,
    required this.isPaused,
    required this.onPauseToggle,
    this.isCompact = false,
  });

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 시간 표시
          _buildStatusItem(
            icon: Icons.timer_outlined,
            label: _formatTime(elapsedSeconds),
            color: Colors.blue,
          ),
          // 구분선
          Container(
            width: 1,
            height: isCompact ? 20 : 24,
            color: Colors.grey.shade300,
          ),
          // 실패 횟수
          _buildStatusItem(
            icon: Icons.close,
            label: '$failureCount',
            color: Colors.red,
          ),
          // 구분선
          Container(
            width: 1,
            height: isCompact ? 20 : 24,
            color: Colors.grey.shade300,
          ),
          // 일시정지 버튼
          InkWell(
            onTap: onPauseToggle,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: isCompact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: isPaused ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    size: isCompact ? 16 : 20,
                    color: isPaused ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  SizedBox(width: isCompact ? 2 : 4),
                  Text(
                    isPaused ? '재개' : '정지',
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 13,
                      fontWeight: FontWeight.w500,
                      color: isPaused ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isCompact ? 16 : 20,
          color: color,
        ),
        SizedBox(width: isCompact ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 13 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
