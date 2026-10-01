import 'dart:math';

import 'package:flutter/material.dart';

import '../models/sudoku_game.dart';

/// In-game help: how to play plus what every feature does.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('How to Play'), centerTitle: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Wide screens: even 2-column card grid.
          // Narrow screens: full-width list, as before.
          final contentWidth = min(constraints.maxWidth, 928.0);
          final wide = contentWidth > 700;
          final cardWidth = wide
              ? (contentWidth - 40 - 12) / 2
              : contentWidth - 40;

          final cards = <Widget>[
            _HelpCard(
              icon: Icons.grid_3x3_rounded,
              color: theme.colorScheme.primary,
              title: 'Goal',
              body:
                  'Fill the 9×9 grid so every row, column, and 3×3 box '
                  'contains the digits 1–9 exactly once. Cells given at the '
                  'start are locked and can\u2019t be changed.',
            ),
            _HelpCard(
              icon: Icons.touch_app_rounded,
              color: theme.colorScheme.primary,
              title: 'Entering numbers',
              body:
                  'Tap a cell, then tap a number on the pad below the board. '
                  'The small count under each number shows how many of that '
                  'digit are still missing. On a laptop or desktop you can '
                  'also just type 1–9, use Backspace to erase, and move '
                  'around with the arrow keys.',
            ),
            _HelpCard(
              icon: Icons.edit_outlined,
              color: theme.colorScheme.primary,
              title: 'Notes (pencil marks)',
              body:
                  'Turn on Notes mode, then tap numbers to jot them down as '
                  'small candidates inside a cell — perfect for tracking '
                  'possibilities. Tap a note again to remove it. Placing the '
                  'real digit clears the cell\u2019s notes automatically.',
            ),
            _HelpCard(
              icon: Icons.lightbulb_outline_rounded,
              color: theme.colorScheme.primary,
              title: 'Hints',
              body:
                  'A hint fills the selected cell with the correct digit and '
                  'locks it in. You get 3 hints per game on Easy and Medium. '
                  'Hints are disabled on Hard and Expert — no mercy there.',
            ),
            _HelpCard(
              icon: Icons.undo_rounded,
              color: theme.colorScheme.primary,
              title: 'Undo & erase',
              body:
                  'Undo steps back through every change you made, including '
                  'notes. Erase clears the selected cell (and its notes). '
                  'Keyboard shortcuts: U to undo, Backspace to erase.',
            ),
            _HelpCard(
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFE53935),
              title: 'Mistakes',
              body:
                  'A wrong digit turns red and counts as a mistake — the dots '
                  'in the top bar track them. Three mistakes and the game is '
                  'over, so double-check the row, column, and box first.',
            ),
            _HelpCard(
              icon: Icons.timer_outlined,
              color: theme.colorScheme.primary,
              title: 'Timer & pause',
              body:
                  'Your time runs while you play and pauses automatically '
                  'when the app goes to the background. Hit pause anytime to '
                  'hide the board and take a break.',
            ),
            _HelpCard(
              icon: Icons.signal_cellular_alt_rounded,
              color: theme.colorScheme.primary,
              title: 'Difficulties',
              body: Difficulty.values
                  .map((d) => '• ${d.label} — ${d.description.toLowerCase()}')
                  .join('\n'),
            ),
            _HelpCard(
              icon: Icons.keyboard_outlined,
              color: theme.colorScheme.primary,
              title: 'Keyboard shortcuts',
              body:
                  '1–9 place a digit · 0 / Backspace erases · Arrow keys move '
                  'the selection · U undo · N notes mode · H hint.',
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Center(
              child: SizedBox(
                width: contentWidth - 40,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: cards
                      .map((card) => SizedBox(width: cardWidth, child: card))
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _HelpCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
