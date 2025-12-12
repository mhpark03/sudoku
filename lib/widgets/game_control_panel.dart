import 'package:flutter/material.dart';
import 'number_pad.dart';

/// 일반 스도쿠와 사무라이 스도쿠에서 공통으로 사용하는 게임 컨트롤 패널
class GameControlPanel extends StatefulWidget {
  /// 숫자 탭 콜백 (isNoteMode 포함)
  final void Function(int number, bool isNoteMode) onNumberTap;

  /// 지우기 콜백
  final VoidCallback onErase;

  /// 힌트 콜백
  final VoidCallback onHint;

  /// 모든 메모 채우기 콜백
  final VoidCallback onFillAllNotes;

  /// 빠른 입력 모드 변경 콜백
  final void Function(bool isQuickInputMode, int? quickInputNumber)? onQuickInputModeChanged;

  /// 메모 모드 변경 콜백
  final void Function(bool isNoteMode)? onNoteModeChanged;

  /// 비활성화할 숫자들 (9개 모두 채워진 숫자)
  final Set<int> disabledNumbers;

  /// 컴팩트 모드 (가로 모드)
  final bool isCompact;

  /// 외부에서 빠른 입력 모드 초기값 설정
  final bool initialQuickInputMode;

  /// 외부에서 메모 모드 초기값 설정
  final bool initialNoteMode;

  const GameControlPanel({
    super.key,
    required this.onNumberTap,
    required this.onErase,
    required this.onHint,
    required this.onFillAllNotes,
    required this.disabledNumbers,
    this.onQuickInputModeChanged,
    this.onNoteModeChanged,
    this.isCompact = false,
    this.initialQuickInputMode = false,
    this.initialNoteMode = false,
  });

  @override
  State<GameControlPanel> createState() => GameControlPanelState();
}

class GameControlPanelState extends State<GameControlPanel> {
  late bool _isQuickInputMode;
  int? _quickInputNumber;
  late bool _isNoteMode;

  bool get isQuickInputMode => _isQuickInputMode;
  int? get quickInputNumber => _quickInputNumber;
  bool get isNoteMode => _isNoteMode;

  @override
  void initState() {
    super.initState();
    _isQuickInputMode = widget.initialQuickInputMode;
    _isNoteMode = widget.initialNoteMode;
  }

  /// 빠른 입력 모드 토글
  void toggleQuickInputMode() {
    setState(() {
      _isQuickInputMode = !_isQuickInputMode;
      if (!_isQuickInputMode) {
        _quickInputNumber = null;
      }
      // 빠른 입력과 메모 모드 동시 선택 가능
    });
    widget.onQuickInputModeChanged?.call(_isQuickInputMode, _quickInputNumber);
  }

  /// 메모 모드 토글
  void toggleNoteMode() {
    setState(() {
      _isNoteMode = !_isNoteMode;
      // 빠른 입력과 메모 모드 동시 선택 가능
    });
    widget.onNoteModeChanged?.call(_isNoteMode);
  }

  /// 빠른 입력 숫자 선택
  void selectQuickInputNumber(int? number) {
    setState(() {
      _quickInputNumber = number;
    });
    widget.onQuickInputModeChanged?.call(_isQuickInputMode, _quickInputNumber);
  }

  /// 빠른 입력 모드 해제
  void clearQuickInputMode() {
    setState(() {
      _isQuickInputMode = false;
      _quickInputNumber = null;
    });
    widget.onQuickInputModeChanged?.call(_isQuickInputMode, _quickInputNumber);
  }

  void _onNumberTap(int number) {
    if (_isQuickInputMode) {
      // 빠른 입력 모드: 숫자 선택/해제
      setState(() {
        if (_quickInputNumber == number) {
          _quickInputNumber = null;
        } else {
          _quickInputNumber = number;
        }
      });
      widget.onQuickInputModeChanged?.call(_isQuickInputMode, _quickInputNumber);
    } else {
      // 일반 모드: 상위 위젯에 전달
      widget.onNumberTap(number, _isNoteMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isQuickInputMode) _buildQuickInputGuide(),
            const SizedBox(height: 8),
            _buildControlButtons(),
            const SizedBox(height: 16),
            NumberPad(
              onNumberTap: _onNumberTap,
              onErase: widget.onErase,
              isCompact: true,
              quickInputNumber: _isQuickInputMode ? _quickInputNumber : null,
              onQuickInputToggle: null,
              disabledNumbers: widget.disabledNumbers,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_isQuickInputMode) _buildQuickInputGuide(),
        _buildControlButtons(),
        const SizedBox(height: 16),
        NumberPad(
          onNumberTap: _onNumberTap,
          onErase: widget.onErase,
          isCompact: false,
          quickInputNumber: _isQuickInputMode ? _quickInputNumber : null,
          onQuickInputToggle: null,
          disabledNumbers: widget.disabledNumbers,
        ),
      ],
    );
  }

  Widget _buildQuickInputGuide() {
    String guideText;
    if (_isQuickInputMode && _isNoteMode) {
      guideText = _quickInputNumber != null
          ? '숫자 $_quickInputNumber 선택됨 - 셀을 탭하여 메모 입력'
          : '아래에서 숫자를 먼저 선택하세요';
    } else {
      guideText = _quickInputNumber != null
          ? '숫자 $_quickInputNumber 선택됨 - 셀을 탭하여 입력'
          : '아래에서 숫자를 먼저 선택하세요';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isNoteMode ? Colors.amber.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isNoteMode ? Colors.amber.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: _isNoteMode ? Colors.amber.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            guideText,
            style: TextStyle(
              fontSize: 12,
              color: _isNoteMode ? Colors.amber.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Wrap(
      spacing: widget.isCompact ? 6 : 8,
      runSpacing: widget.isCompact ? 6 : 8,
      alignment: WrapAlignment.center,
      children: [
        _buildToggleButton(
          icon: Icons.flash_on,
          label: '빠른',
          isActive: _isQuickInputMode,
          activeColor: Colors.orange,
          onTap: toggleQuickInputMode,
        ),
        _buildToggleButton(
          icon: Icons.edit_note,
          label: '메모',
          isActive: _isNoteMode,
          activeColor: Colors.amber,
          onTap: toggleNoteMode,
        ),
        _buildFeatureButton(
          icon: Icons.grid_on,
          label: '모든 메모',
          onTap: widget.onFillAllNotes,
        ),
        _buildFeatureButton(
          icon: Icons.backspace_outlined,
          label: '지우기',
          onTap: widget.onErase,
          color: Colors.red,
        ),
        _buildFeatureButton(
          icon: Icons.lightbulb_outline,
          label: '힌트',
          onTap: widget.onHint,
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
          horizontal: widget.isCompact ? 12 : 16,
          vertical: widget.isCompact ? 6 : 8,
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
              size: widget.isCompact ? 16 : 18,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: widget.isCompact ? 12 : 14,
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
          horizontal: widget.isCompact ? 12 : 16,
          vertical: widget.isCompact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: widget.isCompact ? 16 : 18, color: color ?? Colors.blue),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.blue,
                fontWeight: FontWeight.w500,
                fontSize: widget.isCompact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
