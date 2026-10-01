import 'dart:math';

import 'package:flutter/material.dart';

/// Difficulty levels with their display properties and removal counts.
enum Difficulty {
  easy('Easy', 30, 'Perfect for beginners', Color(0xFF4CAF50), Icons.sentiment_satisfied_alt),
  medium('Medium', 40, 'A balanced challenge', Color(0xFFFFA726), Icons.trending_up),
  hard('Hard', 50, 'For experienced players', Color(0xFFEF5350), Icons.local_fire_department),
  expert('Expert', 55, 'Only for the brave', Color(0xFFAB47BC), Icons.bolt);

  final String label;
  final int cellsToRemove;
  final String description;
  final Color color;
  final IconData icon;
  const Difficulty(this.label, this.cellsToRemove, this.description, this.color, this.icon);
}

/// Represents a single undoable action.
class CellAction {
  final int row;
  final int col;
  final int previousValue;
  final int newValue;
  final Set<int> previousNotes;

  const CellAction({
    required this.row,
    required this.col,
    required this.previousValue,
    required this.newValue,
    required this.previousNotes,
  });
}

/// Core Sudoku game state and logic.
class SudokuGame {
  late List<List<int>> board;
  late List<List<int>> solution;
  late List<List<bool>> given;
  late List<List<Set<int>>> notes;

  int selectedRow = -1;
  int selectedCol = -1;
  bool isNotesMode = false;
  int mistakes = 0;
  static const int maxMistakes = 3;
  bool isCompleted = false;
  bool isGameOver = false;
  final Difficulty difficulty;
  int hintsRemaining = 3;

  final List<CellAction> _undoStack = [];
  final Stopwatch _stopwatch = Stopwatch();
  final Random _random = Random();

  SudokuGame(this.difficulty) {
    _generateNewGame();
  }

  // ── Timer ──────────────────────────────────────────────────────────

  Duration get elapsed => _stopwatch.elapsed;
  bool get isPaused => !_stopwatch.isRunning;

  String get formattedTime {
    final d = _stopwatch.elapsed;
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void startTimer() => _stopwatch.start();
  void pauseTimer() => _stopwatch.stop();
  void resumeTimer() => _stopwatch.start();

  // ── Selection ──────────────────────────────────────────────────────

  void selectCell(int row, int col) {
    selectedRow = row;
    selectedCol = col;
  }

  void clearSelection() {
    selectedRow = -1;
    selectedCol = -1;
  }

  // ── Number entry ───────────────────────────────────────────────────

  /// Returns `true` if correct, `false` if mistake, `null` for notes/erase/noop.
  bool? setNumber(int num) {
    if (selectedRow == -1 || selectedCol == -1) return null;
    if (given[selectedRow][selectedCol]) return null;

    if (isNotesMode) {
      _pushUndo(num: 0);
      if (num == 0) {
        notes[selectedRow][selectedCol].clear();
      } else {
        final s = notes[selectedRow][selectedCol];
        s.contains(num) ? s.remove(num) : s.add(num);
      }
      board[selectedRow][selectedCol] = 0;
      return null;
    }

    _pushUndo(num: num);
    notes[selectedRow][selectedCol].clear();
    board[selectedRow][selectedCol] = num;

    if (num != 0 && num != solution[selectedRow][selectedCol]) {
      mistakes++;
      if (mistakes >= maxMistakes) isGameOver = true;
      return false;
    }

    if (num != 0) {
      _removeNotesForPlacement(selectedRow, selectedCol, num);
      _checkCompletion();
    }
    return num != 0 ? true : null;
  }

  void erase() {
    if (selectedRow == -1 || selectedCol == -1) return;
    if (given[selectedRow][selectedCol]) return;
    _pushUndo(num: 0);
    board[selectedRow][selectedCol] = 0;
    notes[selectedRow][selectedCol].clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    board[action.row][action.col] = action.previousValue;
    notes[action.row][action.col] = Set.from(action.previousNotes);
  }

  bool get canUndo => _undoStack.isNotEmpty;

  bool hint() {
    if (hintsRemaining <= 0) return false;
    if (selectedRow == -1 || selectedCol == -1) return false;
    if (given[selectedRow][selectedCol]) return false;
    if (board[selectedRow][selectedCol] == solution[selectedRow][selectedCol]) return false;

    final val = solution[selectedRow][selectedCol];
    board[selectedRow][selectedCol] = val;
    given[selectedRow][selectedCol] = true;
    notes[selectedRow][selectedCol].clear();
    hintsRemaining--;
    _removeNotesForPlacement(selectedRow, selectedCol, val);
    _checkCompletion();
    return true;
  }

  // ── Query helpers ──────────────────────────────────────────────────

  /// How many more of [num] are needed to fill all 9.
  int getRemainingCount(int num) {
    if (num == 0) return 0;
    int placed = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == num) placed++;
      }
    }
    return 9 - placed;
  }

  bool hasError(int row, int col) {
    final value = board[row][col];
    if (value == 0 || given[row][col]) return false;
    return value != solution[row][col];
  }

  bool isInSameGroup(int row, int col) {
    if (selectedRow == -1 || selectedCol == -1) return false;
    return row == selectedRow ||
        col == selectedCol ||
        ((row ~/ 3) == (selectedRow ~/ 3) && (col ~/ 3) == (selectedCol ~/ 3));
  }

  bool isSameNumber(int row, int col) {
    if (selectedRow == -1 || selectedCol == -1) return false;
    final selVal = board[selectedRow][selectedCol];
    return selVal != 0 && board[row][col] == selVal && !(row == selectedRow && col == selectedCol);
  }

  // ── Private helpers ────────────────────────────────────────────────

  void _pushUndo({required int num}) {
    _undoStack.add(CellAction(
      row: selectedRow,
      col: selectedCol,
      previousValue: board[selectedRow][selectedCol],
      newValue: num,
      previousNotes: Set.from(notes[selectedRow][selectedCol]),
    ));
  }

  void _checkCompletion() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] != solution[r][c]) return;
      }
    }
    isCompleted = true;
    _stopwatch.stop();
  }

  void _removeNotesForPlacement(int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      notes[row][i].remove(num);
      notes[i][col].remove(num);
    }
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        notes[r][c].remove(num);
      }
    }
  }

  // ── Puzzle generation ──────────────────────────────────────────────

  void _generateNewGame() {
    final result = _generatePuzzle(difficulty.cellsToRemove);
    board = result[0].map((row) => List<int>.from(row)).toList();
    solution = result[1].map((row) => List<int>.from(row)).toList();
    given = result[0].map((row) => row.map((v) => v != 0).toList()).toList();
    notes = List.generate(9, (_) => List.generate(9, (_) => <int>{}));
  }

  bool _isValid(List<List<int>> grid, int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (grid[row][i] == num) return false;
      if (grid[i][col] == num) return false;
    }
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (grid[r][c] == num) return false;
      }
    }
    return true;
  }

  bool _solve(List<List<int>> grid) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) {
          final nums = List.generate(9, (i) => i + 1)..shuffle(_random);
          for (final num in nums) {
            if (_isValid(grid, row, col, num)) {
              grid[row][col] = num;
              if (_solve(grid)) return true;
              grid[row][col] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  List<List<int>> _generateSolution() {
    final grid = List.generate(9, (_) => List.filled(9, 0));
    // Seed the diagonal boxes for faster generation
    for (int box = 0; box < 9; box += 3) {
      final nums = List.generate(9, (i) => i + 1)..shuffle(_random);
      int idx = 0;
      for (int r = box; r < box + 3; r++) {
        for (int c = box; c < box + 3; c++) {
          grid[r][c] = nums[idx++];
        }
      }
    }
    _solve(grid);
    return grid;
  }

  int _countSolutions(List<List<int>> grid, {int limit = 2}) {
    int count = 0;
    void inner(List<List<int>> g) {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (g[r][c] == 0) {
            for (int num = 1; num <= 9; num++) {
              if (_isValid(g, r, c, num)) {
                g[r][c] = num;
                inner(g);
                if (count >= limit) return;
                g[r][c] = 0;
              }
            }
            return;
          }
        }
      }
      count++;
    }
    inner(grid.map((row) => List<int>.from(row)).toList());
    return count;
  }

  List<List<List<int>>> _generatePuzzle(int cellsToRemove) {
    final sol = _generateSolution();
    final puzzle = sol.map((row) => List<int>.from(row)).toList();
    final cells = <Point<int>>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        cells.add(Point(r, c));
      }
    }
    cells.shuffle(_random);

    int removed = 0;
    for (final cell in cells) {
      if (removed >= cellsToRemove) break;
      final r = cell.x, c = cell.y;
      final backup = puzzle[r][c];
      puzzle[r][c] = 0;
      if (_countSolutions(puzzle, limit: 2) == 1) {
        removed++;
      } else {
        puzzle[r][c] = backup;
      }
    }
    return [puzzle, sol];
  }
}
