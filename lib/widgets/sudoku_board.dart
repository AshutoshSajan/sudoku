import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A modern 9×9 Sudoku board with rounded corners, 3×3 box borders,
/// selection highlighting, error display, and pencil-mark notes.
class SudokuBoard extends StatelessWidget {
  final List<List<int>> board;
  final List<List<bool>> given;
  final List<List<Set<int>>> notes;
  final int selectedRow;
  final int selectedCol;
  final bool Function(int row, int col) hasError;
  final bool Function(int row, int col) isInSameGroup;
  final bool Function(int row, int col) isSameNumber;
  final void Function(int row, int col) onCellTap;

  const SudokuBoard({
    super.key,
    required this.board,
    required this.given,
    required this.notes,
    required this.selectedRow,
    required this.selectedCol,
    required this.hasError,
    required this.isInSameGroup,
    required this.isSameNumber,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.boxBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(
                Theme.of(context).brightness == Brightness.dark ? 40 : 20,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
              childAspectRatio: 1,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              final row = index ~/ 9;
              final col = index % 9;
              return _buildCell(context, row, col, colors);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context,
    int row,
    int col,
    BoardColors colors,
  ) {
    final value = board[row][col];
    final isGiven = given[row][col];
    final isSelected = (row == selectedRow && col == selectedCol);
    final error = hasError(row, col);
    final highlighted = isInSameGroup(row, col);
    final sameNum = isSameNumber(row, col);
    final cellNotes = notes[row][col];

    // Determine cell background color (priority order)
    Color bgColor;
    if (isSelected) {
      bgColor = colors.selectedCell;
    } else if (error) {
      bgColor = colors.errorCell;
    } else if (sameNum) {
      bgColor = colors.sameNumberCell;
    } else if (highlighted) {
      bgColor = colors.highlightedCell;
    } else {
      bgColor = colors.background;
    }

    // Build cell borders — thicker at 3×3 boundaries
    final border = Border(
      right: col == 8
          ? BorderSide.none
          : (col + 1) % 3 == 0
          ? BorderSide(color: colors.boxBorder, width: 1.5)
          : BorderSide(color: colors.cellBorder, width: 0.5),
      bottom: row == 8
          ? BorderSide.none
          : (row + 1) % 3 == 0
          ? BorderSide(color: colors.boxBorder, width: 1.5)
          : BorderSide(color: colors.cellBorder, width: 0.5),
    );

    // Determine text style
    TextStyle? textStyle;
    if (value != 0) {
      textStyle = TextStyle(
        fontSize: 20,
        fontWeight: isGiven ? FontWeight.w700 : FontWeight.w500,
        color: isGiven
            ? colors.givenText
            : error
            ? colors.errorText
            : colors.userText,
      );
    }

    return GestureDetector(
      onTap: () => onCellTap(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(color: bgColor, border: border),
        alignment: Alignment.center,
        child: value != 0
            ? Text('$value', style: textStyle)
            : cellNotes.isNotEmpty
            ? _buildNotes(cellNotes, colors)
            : null,
      ),
    );
  }

  Widget _buildNotes(Set<int> cellNotes, BoardColors colors) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: List.generate(9, (i) {
          final num = i + 1;
          return Center(
            child: cellNotes.contains(num)
                ? Text(
                    '$num',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: colors.notesText,
                      height: 1,
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }),
      ),
    );
  }
}
