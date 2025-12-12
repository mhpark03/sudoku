import 'package:flutter/material.dart';
import 'number_pad.dart';

/// 일반 스도쿠와 사무라이 스도쿠에서 공통으로 사용하는 게임 컨트롤 패널
class GameControlPanel extends StatelessWidget {
  /// 숫자 탭 콜백
  final void Function(int number) onNumberTap;

  /// 지우기 콜백
  final VoidCallback onErase;

  /// 힌트 콜백
  final VoidCallback onHint;

  /// 모든 메모 채우기 콜백
  final VoidCallback onFillAllNotes;

  /// 빠른 입력 모드 토글 콜백
  final VoidCallback onQuickInputToggle;

  /// 메모 모드 토글 콜백
  final VoidCallback onNoteModeToggle;

  /// 빠른 입력 모드 활성화 여부
  final bool isQuickInputMode;

  /// 빠른 입력에서 선택된 숫자
  final int? quickInputNumber;

  /// 메모 모드 활성화 여부
  final bool isNoteMode;

  /// 비활성화할 숫자들 (9개 모두 채워진 숫자)
  final Set<int> disabledNumbers;

  /// 컴팩트 모드 (가로 모드)
  final bool isCompact;

  const GameControlPanel({
    super.key,
    required this.onNumberTap,
    required this.onErase,
    required this.onHint,
    required this.onFillAllNotes,
    required this.onQuickInputToggle,
    required this.onNoteModeToggle,
    required this.isQuickInputMode,
    required this.quickInputNumber,
    required this.isNoteMode,
    required this.disabledNumbers,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isQuickInputMode) _buildQuickInputGuide(),
            const SizedBox(height: 8),
            _buildControlButtons(),
            const SizedBox(height: 16),
            NumberPad(
              onNumberTap: onNumberTap,
              onErase: onErase,
              isCompact: true,
              quickInputNumber: isQuickInputMode ? quickInputNumber : null,
              onQuickInputToggle: null,
              disabledNumbers: disabledNumbers,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (isQuickInputMode) _buildQuickInputGuide(),
        _buildControlButtons(),
        const SizedBox(height: 16),
        NumberPad(
          onNumberTap: onNumberTap,
          onErase: onErase,
          isCompact: false,
          quickInputNumber: isQuickInputMode ? quickInputNumber : null,
          onQuickInputToggle: null,
          disabledNumbers: disabledNumbers,
        ),
      ],
    );
  }

  Widget _buildQuickInputGuide() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text(
            quickInputNumber != null
                ? '숫자 $quickInputNumber 선택됨 - 셀을 탭하여 입력'
                : '아래에서 숫자를 먼저 선택하세요',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Wrap(
      spacing: isCompact ? 6 : 8,
      runSpacing: isCompact ? 6 : 8,
      alignment: WrapAlignment.center,
      children: [
        _buildToggleButton(
          icon: Icons.flash_on,
          label: '빠른',
          isActive: isQuickInputMode,
          activeColor: Colors.orange,
          onTap: onQuickInputToggle,
        ),
        _buildToggleButton(
          icon: Icons.edit_note,
          label: '메모',
          isActive: isNoteMode,
          activeColor: Colors.amber,
          onTap: onNoteModeToggle,
        ),
        _buildFeatureButton(
          icon: Icons.grid_on,
          label: '모든 메모',
          onTap: onFillAllNotes,
        ),
        _buildFeatureButton(
          icon: Icons.lightbulb_outline,
          label: '힌트',
          onTap: onHint,
          color: Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isCompact ? 16 : 18,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: isCompact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isCompact ? 16 : 18, color: color ?? Colors.blue),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.blue,
                fontWeight: FontWeight.w500,
                fontSize: isCompact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
