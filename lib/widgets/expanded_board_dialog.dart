import 'package:flutter/material.dart';
import '../models/samurai_game_state.dart';
import '../models/samurai_sudoku_generator.dart';

class ExpandedBoardDialog extends StatefulWidget {
  final SamuraiGameState gameState;
  final int boardIndex;
  final int? initialRow;
  final int? initialCol;
  final Function(int board, int row, int col, int value) onValueChanged;
  final Function(int board, int row, int col) onHint;
  final Function(int board, int row, int col, int number) onNoteToggle;
  final Function(int board) onFillAllNotes;

  const ExpandedBoardDialog({
    super.key,
    required this.gameState,
    required this.boardIndex,
    this.initialRow,
    this.initialCol,
    required this.onValueChanged,
    required this.onHint,
    required this.onNoteToggle,
    required this.onFillAllNotes,
  });

  @override
  State<ExpandedBoardDialog> createState() => _ExpandedBoardDialogState();
}

class _ExpandedBoardDialogState extends State<ExpandedBoardDialog> {
  int? selectedRow;
  int? selectedCol;
  bool isNoteMode = false; // 빠른 입력 모드 (메모 모드)

  @override
  void initState() {
    super.initState();
    selectedRow = widget.initialRow;
    selectedCol = widget.initialCol;
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.gameState.currentBoards[widget.boardIndex];
    final isFixed = widget.gameState.isFixed[widget.boardIndex];
    final notes = widget.gameState.notes[widget.boardIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '보드 ${widget.boardIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // 빠른 입력 토글
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isNoteMode ? Colors.orange : Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isNoteMode = !isNoteMode;
                            });
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_note,
                                color: isNoteMode ? Colors.white : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '메모',
                                style: TextStyle(
                                  color: isNoteMode ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 9x9 보드
            Padding(
              padding: const EdgeInsets.all(10),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    children: List.generate(9, (row) {
                      return Expanded(
                        child: Row(
                          children: List.generate(9, (col) {
                            return Expanded(
                              child: _buildCell(board, isFixed, notes, row, col),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            // 기능 버튼들
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureButton(
                    icon: Icons.grid_on,
                    label: '모든 메모',
                    onTap: () {
                      widget.onFillAllNotes(widget.boardIndex);
                      setState(() {});
                    },
                  ),
                  _buildFeatureButton(
                    icon: Icons.lightbulb_outline,
                    label: '힌트',
                    onTap: _onHint,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 숫자 패드
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: _buildNumberPad(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color ?? Colors.blue),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(
    List<List<int>> board,
    List<List<bool>> isFixed,
    List<List<Set<int>>> notes,
    int row,
    int col,
  ) {
    int value = board[row][col];
    bool fixed = isFixed[row][col];
    Set<int> cellNotes = notes[row][col];
    bool isSelected = selectedRow == row && selectedCol == col;
    bool isHighlighted = (selectedRow == row || selectedCol == col) ||
        _isSameBox(row, col);
    bool isSameValue = selectedRow != null &&
        selectedCol != null &&
        value != 0 &&
        value == board[selectedRow!][selectedCol!];
    bool hasError = value != 0 &&
        !SamuraiSudokuGenerator.isValidMove(board, row, col, value);
    bool isOverlap =
        widget.gameState.isOverlapRegion(widget.boardIndex, row, col);

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.blue.shade300;
    } else if (isSameValue) {
      backgroundColor = Colors.blue.shade100;
    } else if (isHighlighted) {
      backgroundColor = Colors.blue.shade50;
    } else if (isOverlap) {
      backgroundColor = Colors.yellow.shade100;
    } else {
      backgroundColor = Colors.white;
    }

    Color textColor;
    if (hasError) {
      textColor = Colors.red;
    } else if (fixed) {
      textColor = Colors.black;
    } else {
      textColor = Colors.blue.shade700;
    }

    bool rightBorder = (col + 1) % 3 == 0 && col != 8;
    bool bottomBorder = (row + 1) % 3 == 0 && row != 8;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedRow == row && selectedCol == col) {
            selectedRow = null;
            selectedCol = null;
          } else {
            selectedRow = row;
            selectedCol = col;
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            right: BorderSide(
              color: rightBorder ? Colors.black : Colors.grey.shade300,
              width: rightBorder ? 2 : 0.5,
            ),
            bottom: BorderSide(
              color: bottomBorder ? Colors.black : Colors.grey.shade300,
              width: bottomBorder ? 2 : 0.5,
            ),
            left: BorderSide(color: Colors.grey.shade300, width: 0.5),
            top: BorderSide(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        child: value != 0
            ? Center(
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: fixed ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              )
            : cellNotes.isNotEmpty
                ? _buildNotesGrid(cellNotes)
                : const SizedBox(),
      ),
    );
  }

  Widget _buildNotesGrid(Set<int> cellNotes) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (index) {
          int num = index + 1;
          bool hasNote = cellNotes.contains(num);
          return Center(
            child: Text(
              hasNote ? num.toString() : '',
              style: TextStyle(
                fontSize: 9,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isSameBox(int row, int col) {
    if (selectedRow == null || selectedCol == null) return false;
    int selectedBoxRow = (selectedRow! ~/ 3) * 3;
    int selectedBoxCol = (selectedCol! ~/ 3) * 3;
    int cellBoxRow = (row ~/ 3) * 3;
    int cellBoxCol = (col ~/ 3) * 3;
    return selectedBoxRow == cellBoxRow && selectedBoxCol == cellBoxCol;
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) => _buildNumberButton(index + 1)),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...List.generate(4, (index) => _buildNumberButton(index + 6)),
            _buildEraseButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(int number) {
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _onNumberTap(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: isNoteMode ? Colors.orange.shade50 : Colors.blue.shade50,
          foregroundColor: isNoteMode ? Colors.orange.shade700 : Colors.blue.shade700,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          number.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEraseButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: _onErase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade700,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Icon(Icons.backspace, size: 20),
      ),
    );
  }

  void _onNumberTap(int number) {
    if (selectedRow == null || selectedCol == null) return;
    if (widget.gameState.isFixed[widget.boardIndex][selectedRow!][selectedCol!]) {
      return;
    }

    if (isNoteMode) {
      // 메모 모드: 메모 토글
      widget.onNoteToggle(widget.boardIndex, selectedRow!, selectedCol!, number);
    } else {
      // 일반 모드: 값 입력
      widget.onValueChanged(widget.boardIndex, selectedRow!, selectedCol!, number);
    }
    setState(() {});
  }

  void _onErase() {
    if (selectedRow == null || selectedCol == null) return;
    if (widget.gameState.isFixed[widget.boardIndex][selectedRow!][selectedCol!]) {
      return;
    }

    // 값이 있으면 값 삭제, 없으면 메모 삭제
    if (widget.gameState.currentBoards[widget.boardIndex][selectedRow!][selectedCol!] != 0) {
      widget.onValueChanged(widget.boardIndex, selectedRow!, selectedCol!, 0);
    } else {
      widget.gameState.clearNotes(widget.boardIndex, selectedRow!, selectedCol!);
    }
    setState(() {});
  }

  void _onHint() {
    if (selectedRow == null || selectedCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('셀을 먼저 선택하세요')),
      );
      return;
    }

    if (widget.gameState.isFixed[widget.boardIndex][selectedRow!][selectedCol!]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 채워진 칸입니다')),
      );
      return;
    }

    widget.onHint(widget.boardIndex, selectedRow!, selectedCol!);
    setState(() {});
  }
}
