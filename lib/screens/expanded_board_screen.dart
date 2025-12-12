import 'dart:async';
import 'package:flutter/material.dart';
import '../models/samurai_game_state.dart';
import '../models/samurai_sudoku_generator.dart';
import '../widgets/game_control_panel.dart';
import '../widgets/game_status_bar.dart';

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
  final GlobalKey<GameControlPanelState> _controlPanelKey = GlobalKey();

  // 빠른 입력 모드 상태 (하이라이트용)
  bool _isQuickInputMode = false;
  int? _quickInputNumber;
  bool _isEraseMode = false;

  // 게임 타이머 및 통계
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _failureCount = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    selectedRow = widget.initialRow;
    selectedCol = widget.initialCol;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Widget _buildPausedOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_outline,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              '일시정지',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '재개 버튼을 눌러 계속하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
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
      ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(board, isFixed, notes)
            : _buildPortraitLayout(board, isFixed, notes),
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
          // 게임 상태 표시 바
          GameStatusBar(
            elapsedSeconds: _elapsedSeconds,
            failureCount: _failureCount,
            isPaused: _isPaused,
            onPauseToggle: _togglePause,
          ),
          const SizedBox(height: 12),
          // 9x9 보드 또는 일시정지 오버레이
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _isPaused
                    ? _buildPausedOverlay()
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        child: _buildGrid(board, isFixed, notes),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 공통 게임 컨트롤 패널
          GameControlPanel(
            key: _controlPanelKey,
            onNumberTap: _onNumberTap,
            onErase: _onErase,
            onHint: _onHint,
            onFillAllNotes: _onFillAllNotes,
            onQuickInputModeChanged: (isQuickInput, number) {
              setState(() {
                _isQuickInputMode = isQuickInput;
                _quickInputNumber = number;
                // 빠른 입력 모드에서 숫자 선택 시 셀 선택 초기화
                if (isQuickInput && number != null) {
                  selectedRow = null;
                  selectedCol = null;
                }
              });
            },
            onEraseModeChanged: (isErase) {
              setState(() {
                _isEraseMode = isErase;
              });
            },
            disabledNumbers: widget.gameState.getCompletedNumbers(widget.boardIndex),
            isCompact: false,
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
          // 9x9 보드 또는 일시정지 오버레이
          Expanded(
            flex: 1,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _isPaused
                    ? _buildPausedOverlay()
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        child: _buildGrid(board, isFixed, notes),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 오른쪽: 상태 바 + 컨트롤 패널
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // 게임 상태 표시 바 (컴팩트)
                GameStatusBar(
                  elapsedSeconds: _elapsedSeconds,
                  failureCount: _failureCount,
                  isPaused: _isPaused,
                  onPauseToggle: _togglePause,
                  isCompact: true,
                ),
                const SizedBox(height: 8),
                // 공통 게임 컨트롤 패널
                Expanded(
                  child: GameControlPanel(
                    key: _controlPanelKey,
                    onNumberTap: _onNumberTap,
                    onErase: _onErase,
                    onHint: _onHint,
                    onFillAllNotes: _onFillAllNotes,
                    onQuickInputModeChanged: (isQuickInput, number) {
                      setState(() {
                        _isQuickInputMode = isQuickInput;
                        _quickInputNumber = number;
                        // 빠른 입력 모드에서 숫자 선택 시 셀 선택 초기화
                        if (isQuickInput && number != null) {
                          selectedRow = null;
                          selectedCol = null;
                        }
                      });
                    },
                    onEraseModeChanged: (isErase) {
                      setState(() {
                        _isEraseMode = isErase;
                      });
                    },
                    disabledNumbers: widget.gameState.getCompletedNumbers(widget.boardIndex),
                    isCompact: true,
                  ),
                ),
              ],
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
      color: Colors.grey.shade800,
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

    // 빠른 입력 모드에서 선택된 숫자와 같은 값을 가진 셀 하이라이트
    bool isQuickInputHighlight = _isQuickInputMode &&
        _quickInputNumber != null &&
        value != 0 &&
        value == _quickInputNumber;
    // 메모에 선택된 숫자가 포함된 셀 하이라이트 (빠른 입력 모드 또는 일반 모드)
    bool isNoteHighlight = _shouldHighlightNote(value, cellNotes);
    // 일반 모드에서는 선택된 셀과 같은 값 하이라이트
    bool isSameValue = !_isQuickInputMode &&
        selectedRow != null &&
        selectedCol != null &&
        value != 0 &&
        value == board[selectedRow!][selectedCol!];

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = Colors.blue.shade300;
    } else if (isQuickInputHighlight) {
      // 숫자가 결정된 셀: 진한 파란색
      backgroundColor = Colors.blue.shade200;
    } else if (isNoteHighlight) {
      // 메모에 포함된 셀: 연한 녹색
      backgroundColor = Colors.green.shade100;
    } else if (isSameValue) {
      backgroundColor = Colors.blue.shade200;
    } else if (!_isQuickInputMode && (isSameRowOrCol || isSameBox)) {
      // 빠른 입력 모드에서는 행/열/박스 하이라이트 비활성화
      backgroundColor = Colors.blue.shade50;
    } else {
      backgroundColor = Colors.white;
    }

    Color textColor = Colors.black;

    return GestureDetector(
      onTap: () => _onCellTap(row, col, fixed),
      child: SizedBox.expand(
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
                  : null,
        ),
      ),
    );
  }

  void _onCellTap(int row, int col, bool isFixed) {
    // 일시정지 상태에서는 입력 차단
    if (_isPaused) return;

    final controlState = _controlPanelKey.currentState;

    setState(() {
      // 지우기 모드일 때
      if (controlState != null && controlState.isEraseMode) {
        if (!isFixed) {
          if (widget.gameState.currentBoards[widget.boardIndex][row][col] != 0) {
            // 값이 있으면 값 지우기
            widget.onValueChanged(widget.boardIndex, row, col, 0);
          } else {
            // 값이 없으면 메모 지우기
            widget.gameState.clearNotes(widget.boardIndex, row, col);
          }
        }
        selectedRow = row;
        selectedCol = col;
      }
      // 빠른 입력 모드일 때
      else if (controlState != null && controlState.isQuickInputMode && controlState.quickInputNumber != null) {
        if (!isFixed) {
          // 빠른 입력 + 메모 모드: 메모로 입력
          if (controlState.isNoteMode) {
            if (widget.gameState.currentBoards[widget.boardIndex][row][col] == 0) {
              widget.onNoteToggle(widget.boardIndex, row, col, controlState.quickInputNumber!);
            }
            selectedRow = row;
            selectedCol = col;
          } else {
            // 빠른 입력 모드만: 일반 숫자 입력
            // 현재 보드를 복사하여 유효성 검사
            final board = widget.gameState.currentBoards[widget.boardIndex];
            final testBoard = board.map((r) => List<int>.from(r)).toList();
            testBoard[row][col] = controlState.quickInputNumber!;

            bool isValid = SamuraiSudokuGenerator.isValidMove(
                testBoard, row, col, controlState.quickInputNumber!);

            if (isValid) {
              widget.onValueChanged(
                  widget.boardIndex, row, col, controlState.quickInputNumber!);
              _showFeedback(true);
              _checkCompletion();
            } else {
              _showFeedback(false);
            }

            selectedRow = row;
            selectedCol = col;
          }
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
    // 실패 시 횟수 증가
    if (!isCorrect) {
      setState(() {
        _failureCount++;
      });
    }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        // 너비와 높이 중 작은 값을 사용하여 오버플로우 방지
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final cellSize = size / 3;
        final fontSize = (cellSize * 0.55).clamp(6.0, 12.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (col) {
                int num = row * 3 + col + 1;
                bool hasNote = cellNotes.contains(num);
                return SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: Center(
                    child: Text(
                      hasNote ? num.toString() : '',
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        );
      },
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

  /// 메모 하이라이트 여부 판단
  /// 빠른 입력 모드: quickInputNumber가 메모에 포함된 경우
  /// 일반 모드: 선택된 셀의 숫자가 메모에 포함된 경우
  bool _shouldHighlightNote(int cellValue, Set<int> cellNotes) {
    // 현재 셀에 값이 있으면 하이라이트 안함
    if (cellValue != 0) return false;

    // 메모가 없으면 하이라이트 안함
    if (cellNotes.isEmpty) return false;

    if (_isQuickInputMode) {
      // 빠른 입력 모드
      if (_quickInputNumber == null) return false;
      return cellNotes.contains(_quickInputNumber);
    } else {
      // 일반 모드: 선택된 셀의 숫자가 메모에 포함된 경우
      if (selectedRow == null || selectedCol == null) return false;
      int selectedValue = widget.gameState.currentBoards[widget.boardIndex]
          [selectedRow!][selectedCol!];
      if (selectedValue == 0) return false;
      return cellNotes.contains(selectedValue);
    }
  }

  void _onNumberTap(int number, bool isNoteMode) {
    // 일시정지 상태에서는 입력 차단
    if (_isPaused) return;

    if (selectedRow == null || selectedCol == null) return;
    if (widget.gameState.isFixed[widget.boardIndex][selectedRow!][selectedCol!]) {
      return;
    }

    if (isNoteMode) {
      widget.onNoteToggle(widget.boardIndex, selectedRow!, selectedCol!, number);
    } else {
      // 유효성 검사
      final board = widget.gameState.currentBoards[widget.boardIndex];
      final testBoard = board.map((r) => List<int>.from(r)).toList();
      testBoard[selectedRow!][selectedCol!] = number;

      bool isValid = SamuraiSudokuGenerator.isValidMove(
          testBoard, selectedRow!, selectedCol!, number);

      if (isValid) {
        widget.onValueChanged(widget.boardIndex, selectedRow!, selectedCol!, number);
        _showFeedback(true);
        _checkCompletion();
      } else {
        _showFeedback(false);
      }
    }
    setState(() {});
  }

  void _onErase() {
    // 일시정지 상태에서는 입력 차단
    if (_isPaused) return;

    final controlState = _controlPanelKey.currentState;

    if (controlState != null && controlState.isQuickInputMode) {
      controlState.selectQuickInputNumber(null);
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

  void _onFillAllNotes() {
    // 일시정지 상태에서는 입력 차단
    if (_isPaused) return;

    setState(() {
      widget.gameState.fillAllNotes(widget.boardIndex);
    });
  }

  void _onHint() {
    // 일시정지 상태에서는 입력 차단
    if (_isPaused) return;

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
