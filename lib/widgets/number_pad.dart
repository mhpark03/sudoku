import 'package:flutter/material.dart';

class NumberPad extends StatelessWidget {
  final Function(int) onNumberTap;
  final VoidCallback onErase;
  final bool isCompact;

  const NumberPad({
    super.key,
    required this.onNumberTap,
    required this.onErase,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = isCompact ? 36.0 : 60.0;
    final fontSize = isCompact ? 16.0 : 24.0;
    final iconSize = isCompact ? 16.0 : 24.0;
    final spacing = isCompact ? 4.0 : 10.0;

    if (isCompact) {
      // 가로 모드: 3x3 + 지우기 버튼 그리드
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.all(spacing / 2),
                child: _buildNumberButton(index + 1, buttonSize, fontSize),
              );
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.all(spacing / 2),
                child: _buildNumberButton(index + 4, buttonSize, fontSize),
              );
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.all(spacing / 2),
                child: _buildNumberButton(index + 7, buttonSize, fontSize),
              );
            }),
          ),
          Padding(
            padding: EdgeInsets.all(spacing / 2),
            child: _buildEraseButton(buttonSize * 2 + spacing, buttonSize, iconSize),
          ),
        ],
      );
    } else {
      // 세로 모드: 기존 레이아웃
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return _buildNumberButton(index + 1, buttonSize, fontSize);
            }),
          ),
          SizedBox(height: spacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...List.generate(4, (index) {
                return _buildNumberButton(index + 6, buttonSize, fontSize);
              }),
              _buildEraseButton(buttonSize, buttonSize, iconSize),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildNumberButton(int number, double size, double fontSize) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () => onNumberTap(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade50,
          foregroundColor: Colors.blue.shade700,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          number.toString(),
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEraseButton(double width, double height, double iconSize) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onErase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Icon(Icons.backspace, size: iconSize),
      ),
    );
  }
}
