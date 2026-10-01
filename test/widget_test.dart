import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sudoku/main.dart';
import 'package:sudoku/screens/help_screen.dart';
import 'package:sudoku/widgets/action_bar.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SudokuApp());
    expect(find.text('Sudoku'), findsWidgets);
  });

  testWidgets('Home shows all four difficulty cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SudokuApp());
    for (final label in ['Easy', 'Medium', 'Hard', 'Expert']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('Help button opens the how-to-play screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SudokuApp());
    await tester.tap(find.byTooltip('How to play'));
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(find.text('Notes (pencil marks)'), findsOneWidget);
  });

  testWidgets('Action bar exposes tooltips for every action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionBar(
            onUndo: () {},
            onErase: () {},
            onToggleNotes: () {},
            onHint: () {},
            isNotesActive: false,
            canUndo: true,
            hintsRemaining: 3,
          ),
        ),
      ),
    );
    expect(find.byType(Tooltip), findsNWidgets(4));
    expect(find.byTooltip('Undo last move (U)'), findsOneWidget);
    expect(find.byTooltip('Reveal a cell (H)'), findsOneWidget);
  });
}
