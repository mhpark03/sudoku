import 'package:flutter/material.dart';
import '../models/samurai_game_state.dart';
import '../models/samurai_sudoku_generator.dart';
import '../widgets/number_pad.dart';

class ExpandedBoardScreen extends StatefulWidget {
  final SamuraiGameState gameState;
  final int boardIndex;
  final int? initialRow;
  final int? initialCol;
  final Function(int board, int row, int col, int value) onValueChanged;
  final Function(int board, int row, int col) onHint;
  final Function(int board, int row, int col, int number) onNoteToggle;
  final Function(int board) onFillAllNotes;
  final VoidCallback? onComplete;

  const ExpandedBoardScreen({
    super.key,
    required this.gameState,
    required this.boardIndex,
    this.initialRow,
    this.initialCol,
    required this.onValueChanged,
    required this.onHint,
    required this.onNoteToggle,
    required this.onFillAllNotes,
    this.onComplete,
  });

  @override
  State<ExpandedBoardScreen> createState() => _ExpandedBoardScreenState();
}

class _ExpandedBoardScreenState extends State<ExpandedBoardScreen> {
  int? selectedRow;
  int? selectedCol;
  bool isNoteMode = false; // 메모 모드
  bool isQuickInputMode = false; // 빠른 입력 모드
  int? quickInputNumber; // 빠른 입력에서 선택된 숫자

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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: Text('보드 ${widget.boardIndex + 1}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        toolbarHeight: isLandscape ? 45 : kToolbarHeight,
        actions: [
          // 빠른 입력 토글
          _buildAppBarToggle(
            icon: Icons.flash_on,
            label: '빠른',
            isActive: isQuickInputMode,
            onTap: () {
              setState(() {
                isQuickInputMode = !isQuickInputMode;
                if (!isQuickInputMode) {
                  quickInputNumber = null;
                }
                if (isQuickInputMode) {
                  isNoteMode = false;
                }
              });
            },
          ),
          const SizedBox(width: 4),
          // 메모 모드 토글
          _buildAppBarToggle(
            icon: Icons.edit_note,
            label: '메모',
            isActive: isNoteMode,
            onTap: () {
              setState(() {
                isNoteMode = !isNoteMode;
                if (isNoteMode) {
                  isQuickInputMode = false;
                  quickInputNumber = null;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(board, isFixed, notes)
            : _buildPortraitLayout(board, isFixed, notes),
      ),
    );
  }

  Widget _buildAppBarToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.orange : Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    List<List<int>> board,
    List<List<bool>> isFixed,
    List<List<Set<int>>> notes,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 빠른 입력 모드 안내
          if (isQuickInputMode) _buildQuickInputGuide(),
          // 9x9 보드
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: _buildGrid(board, isFixed, notes),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 기능 버튼들
          Row(
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
          const SizedBox(height: 16),
          // 숫자 패드
          NumberPad(
            onNumberTap: _onNumberTap,
            onErase: _onErase,
            isCompact: false,
            quickInputNumber: isQuickInputMode ? quickInputNumber : null,
            onQuickInputToggle: null, // AppBar에서 토글하므로 여기서는 null
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    List<List<int>> board,
    List<List<bool>> isFixed,
    List<List<Set<int>>> notes,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // 9x9 보드
          Expanded(
            flex: 1,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                  child: _buildGrid(board, isFixed, notes),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 컨트롤
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 빠른 입력 모드 안내
                  if (isQuickInputMode) _buildQuickInputGuide(),
                  const SizedBox(height: 8),
                  // 기능 버튼들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeatureButton(
                        icon: Icons.grid_on,
                        label: '모든 메모',
                        onTap: () {
                          widget.onFillAllNotes(widget.boardIndex);
                          setState(() {});
                        },
                        compact: true,
                      ),
                      const SizedBox(width: 8),
                      _buildFeatureButton(
                        icon: Icons.lightbulb_outline,
                        label: '힌트',
                        onTap: _onHint,
                        color: Colors.orange,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 숫자 패드
                  NumberPad(
                    onNumberTap: _onNumberTap,
                    onErase: _onErase,
                    isCompact: true,
                    quickInputNumber: isQuickInputMode ? quickInputNumber : null,
                    onQuickInputToggle: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildGrid(
    List<List<int>> board,
    List<List<bool>> isFixed,
    List<List<Set<int>>> notes,
  ) {
    return Container(
      color: Colors.black,
      child: Column(
        children: List.generate(9, (row) {
          return Expanded(
            child: Row(
              children: List.generate(9, (col) {
                double rightPadding = (col == 2 || col == 5) ? 2 : 1;
                double bottomPadding = (row == 2 || row == 5) ? 2 : 1;
                if (col == 8) rightPadding = 0;
                if (row == 8) bottomPadding = 0;

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: rightPadding,
                      bottom: bottomPadding,
                    ),
                    child: _buildCell(board, isFixed, notes, row, col),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool compact = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 16 : 18, color: color ?? Colors.blue),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.blue,
                fontWeight: FontWeight.w500,
                fontSize: compact ? 12 : 14,
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
    bool isSameRowOrCol = selectedRow != null &&
        selectedCol != null &&
        (selectedRow == row || selectedCol == col);
    bool isSameBox = _isSameBox(row, col);
    bool isSameValue = selectedRow != null &&
        selectedCol != null &&
        value != 0 &&
        value == board[selectedRow!][selectedCol!];
    bool isQuickInputValue =
        isQuickInputMode && quickInputNumber != null && value == quickInputNumber;
    bool hasError =
        value != 0 && !SamuraiSudokuGenerator.isValidMove(board, row, col, value);

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.blue.shade300;
    } else if (isQuickInputValue) {
      backgroundColor = Colors.orange.shade200;
    } else if (isSameValue) {
      backgroundColor = Colors.blue.shade200;
    } else if (isSameRowOrCol || isSameBox) {
      backgroundColor = Colors.blue.shade50;
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

    return GestureDetector(
      onTap: () => _onCellTap(row, col, fixed),
      child: Container(
        color: backgroundColor,
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

  void _onCellTap(int row, int col, bool isFixed) {
    setState(() {
      if (isQuickInputMode && quickInputNumber != null) {
        if (!isFixed) {
          final solution = widget.gameState.solutions[widget.boardIndex];
          bool isCorrect = solution[row][col] == quickInputNumber;

          if (isCorrect) {
            widget.onValueChanged(
                widget.boardIndex, row, col, quickInputNumber!);
            _showFeedback(true);
            _checkCompletion();
          } else {
            _showFeedback(false);
          }

          selectedRow = row;
          selectedCol = col;
        } else {
          selectedRow = row;
          selectedCol = col;
        }
      } else {
        if (selectedRow == row && selectedCol == col) {
          selectedRow = null;
          selectedCol = null;
        } else {
          selectedRow = row;
          selectedCol = col;
        }
      }
    });
  }

  void _checkCompletion() {
    bool isComplete = SamuraiSudokuGenerator.areAllBoardsComplete(
        widget.gameState.currentBoards);
    if (isComplete) {
      Navigator.pop(context);
      widget.onComplete?.call();
    }
  }

  void _showFeedback(bool isCorrect) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(isCorrect ? '정답입니다!' : '틀렸습니다!'),
          ],
        ),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
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

  void _onNumberTap(int number) {
    if (isQuickInputMode) {
      setState(() {
        if (quickInputNumber == number) {
          quickInputNumber = null;
        } else {
          quickInputNumber = number;
        }
      });
      return;
    }

    if (selectedRow == null || selectedCol == null) return;
    if (widget.gameState.isFixed[widget.boardIndex][selectedRow!][selectedCol!]) {
      return;
    }

    if (isNoteMode) {
      widget.onNoteToggle(widget.boardIndex, selectedRow!, selectedCol!, number);
    } else {
      widget.onValueChanged(widget.boardIndex, selectedRow!, selectedCol!, number);
      _checkCompletion();
    }
    setState(() {});
  }

  void _onErase() {
    if (isQuickInputMode) {
      setState(() {
        quickInputNumber = null;
      });
      return;
    }

    if (selectedRow == null || selectedCol == null) return;
    if (widget.gameState.isFixed[widget.boardIndex][selectedRow!][selectedCol!]) {
      return;
    }

    if (widget.gameState.currentBoards[widget.boardIndex][selectedRow!][selectedCol!] !=
        0) {
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
    _checkCompletion();
    setState(() {});
  }
}
