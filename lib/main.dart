import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const SudokuApp());

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SudokuGame(),
    );
  }
}

class SudokuGame extends StatefulWidget {
  const SudokuGame({super.key});

  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> {
  List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
  List<List<int>> solution = List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> given = List.generate(9, (_) => List.filled(9, false));
  List<List<int>> initialBoard = List.generate(9, (_) => List.filled(9, 0));

  int selectedRow = -1;
  int selectedCol = -1;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  // ---------- Sudoku logic ----------
  bool _isValid(List<List<int>> grid, int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (grid[row][i] == num) return false;
      if (grid[i][col] == num) return false;
    }
    int br = (row ~/ 3) * 3;
    int bc = (col ~/ 3) * 3;
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
          List<int> nums = List.generate(9, (i) => i + 1)..shuffle(_random);
          for (int num in nums) {
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
    List<List<int>> grid = List.generate(9, (_) => List.filled(9, 0));
    for (int box = 0; box < 9; box += 3) {
      List<int> nums = List.generate(9, (i) => i + 1)..shuffle(_random);
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
    void countSolve(List<List<int>> g) {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (g[r][c] == 0) {
            for (int num = 1; num <= 9; num++) {
              if (_isValid(g, r, c, num)) {
                g[r][c] = num;
                countSolve(g);
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
    countSolve(grid.map((row) => List<int>.from(row)).toList());
    return count;
  }

  List<List<List<int>>> _generatePuzzle([int difficulty = 40]) {
    List<List<int>> sol = _generateSolution();
    List<List<int>> puzzle = sol.map((row) => List<int>.from(row)).toList();
    List<Point<int>> cells = [];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        cells.add(Point(r, c));
      }
    }
    cells.shuffle(_random);
    int removed = 0;
    for (var cell in cells) {
      if (removed >= difficulty) break;
      int r = cell.x, c = cell.y;
      int backup = puzzle[r][c];
      puzzle[r][c] = 0;
      if (_countSolutions(puzzle, limit: 2) == 1) {
        removed++;
      } else {
        puzzle[r][c] = backup;
      }
    }
    return [puzzle, sol];
  }

  void _newGame() {
    var result = _generatePuzzle(40);
    List<List<int>> puzzle = result[0];
    List<List<int>> sol = result[1];
    setState(() {
      board = puzzle.map((row) => List<int>.from(row)).toList();
      solution = sol.map((row) => List<int>.from(row)).toList();
      given = puzzle.map((row) => row.map((v) => v != 0).toList()).toList();
      initialBoard = puzzle.map((row) => List<int>.from(row)).toList();
      selectedRow = -1;
      selectedCol = -1;
    });
  }

  void _resetGame() {
    setState(() {
      board = initialBoard.map((row) => List<int>.from(row)).toList();
      given = initialBoard.map((row) => row.map((v) => v != 0).toList()).toList();
      selectedRow = -1;
      selectedCol = -1;
    });
  }

  void _checkSolution() {
    bool correct = true;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] != solution[r][c]) {
          correct = false;
          break;
        }
      }
      if (!correct) break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? '✅ Perfect! All correct.' : '❌ Not solved yet. Keep going!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _giveHint() {
    if (selectedRow == -1 || selectedCol == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a cell first.')),
      );
      return;
    }
    int r = selectedRow, c = selectedCol;
    if (given[r][c]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This cell is fixed.')),
      );
      return;
    }
    int val = solution[r][c];
    setState(() {
      board[r][c] = val;
      given[r][c] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hint: $val')),
    );
  }

  void _selectCell(int row, int col) {
    setState(() {
      if (!given[row][col]) {
        selectedRow = row;
        selectedCol = col;
      } else {
        selectedRow = -1;
        selectedCol = -1;
      }
    });
  }

  void _setNumber(int num) {
    if (selectedRow == -1 || selectedCol == -1) return;
    int r = selectedRow, c = selectedCol;
    if (given[r][c]) return;
    setState(() {
      board[r][c] = num;
    });
    // check if solved
    bool solved = true;
    for (int rr = 0; rr < 9; rr++) {
      for (int cc = 0; cc < 9; cc++) {
        if (board[rr][cc] != solution[rr][cc]) {
          solved = false;
          break;
        }
      }
      if (!solved) break;
    }
    if (solved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Solved! Congratulations!')),
      );
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Board(
                  board: board,
                  given: given,
                  selectedRow: selectedRow,
                  selectedCol: selectedCol,
                  onCellTap: _selectCell,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _newGame, child: const Text('New')),
                ElevatedButton(onPressed: _checkSolution, child: const Text('Check')),
                ElevatedButton(onPressed: _giveHint, child: const Text('Hint')),
                ElevatedButton(onPressed: _resetGame, child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: 16),
            NumPad(onNumberSelected: _setNumber),
          ],
        ),
      ),
    );
  }
}

class Board extends StatelessWidget {
  final List<List<int>> board;
  final List<List<bool>> given;
  final int selectedRow;
  final int selectedCol;
  final Function(int, int) onCellTap;

  const Board({
    super.key,
    required this.board,
    required this.given,
    required this.selectedRow,
    required this.selectedCol,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 9,
          childAspectRatio: 1,
        ),
        itemCount: 81,
        itemBuilder: (context, index) {
          int row = index ~/ 9;
          int col = index % 9;
          int value = board[row][col];
          bool isGiven = given[row][col];
          bool isSelected = (row == selectedRow && col == selectedCol);
          // Determine error
          bool error = false;
          if (!isGiven && value != 0) {
            // Check duplicates in row, col, box
            for (int i = 0; i < 9; i++) {
              if (i != col && board[row][i] == value) { error = true; break; }
              if (i != row && board[i][col] == value) { error = true; break; }
            }
            if (!error) {
              int br = (row ~/ 3) * 3;
              int bc = (col ~/ 3) * 3;
              for (int r = br; r < br + 3; r++) {
                for (int c = bc; c < bc + 3; c++) {
                  if ((r != row || c != col) && board[r][c] == value) {
                    error = true;
                    break;
                  }
                }
                if (error) break;
              }
            }
          }
          // Highlight same number
          bool sameNumber = false;
          if (selectedRow != -1 && selectedCol != -1) {
            int selVal = board[selectedRow][selectedCol];
            if (selVal != 0 && value == selVal && !(row == selectedRow && col == selectedCol)) {
              sameNumber = true;
            }
          }
          // Border styling for 3x3 boxes
          BoxDecoration decoration = BoxDecoration(
            color: isSelected
                ? Colors.lightBlue[200]
                : sameNumber
                    ? Colors.lightBlue[50]
                    : (error ? Colors.red[100] : Colors.white),
            border: Border(
              right: (col + 1) % 3 == 0 && col != 8
                  ? const BorderSide(color: Colors.black, width: 2)
                  : const BorderSide(color: Colors.grey, width: 0.5),
              bottom: (row + 1) % 3 == 0 && row != 8
                  ? const BorderSide(color: Colors.black, width: 2)
                  : const BorderSide(color: Colors.grey, width: 0.5),
              left: col == 0 ? const BorderSide(color: Colors.black, width: 0.5) : BorderSide.none,
              top: row == 0 ? const BorderSide(color: Colors.black, width: 0.5) : BorderSide.none,
            ),
          );

          return GestureDetector(
            onTap: () => onCellTap(row, col),
            child: Container(
              decoration: decoration,
              alignment: Alignment.center,
              child: value != 0
                  ? Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: isGiven ? FontWeight.bold : FontWeight.normal,
                        color: isGiven ? Colors.black : (error ? Colors.red : Colors.blue),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class NumPad extends StatelessWidget {
  final Function(int) onNumberSelected;

  const NumPad({super.key, required this.onNumberSelected});

  @override
  Widget build(BuildContext context) {
    List<int> numbers = [1,2,3,4,5,6,7,8,9,0]; // 0 represents erase
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: numbers.map((num) {
        return SizedBox(
          width: 44,
          height: 44,
          child: ElevatedButton(
            onPressed: () => onNumberSelected(num),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              backgroundColor: num == 0 ? Colors.red[100] : null,
            ),
            child: Text(
              num == 0 ? '✕' : '$num',
              style: TextStyle(fontSize: 20, color: num == 0 ? Colors.red : null),
            ),
          ),
        );
      }).toList(),
    );
  }
}