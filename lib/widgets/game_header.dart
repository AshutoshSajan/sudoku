import 'package:flutter/material.dart';
import '../models/sudoku_game.dart';

/// Top header bar showing difficulty badge, timer, mistake indicators, and a pause button.
class GameHeader extends StatelessWidget {
  final Difficulty difficulty;
  final String formattedTime;
  final int mistakes;
  final int maxMistakes;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onBack;

  const GameHeader({
    super.key,
    required this.difficulty,
    required this.formattedTime,
    required this.mistakes,
    required this.maxMistakes,
    required this.isPaused,
    required this.onPause,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              fixedSize: const Size(40, 40),
            ),
          ),

          const Spacer(),

          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: difficulty.color.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              difficulty.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: difficulty.color,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Timer
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
              const SizedBox(width: 4),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Mistake indicators
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(maxMistakes, (i) {
              final isFilled = i < mistakes;
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? const Color(0xFFE53935)
                        : theme.colorScheme.onSurface.withAlpha(40),
                  ),
                ),
              );
            }),
          ),

          const Spacer(),

          // Pause button
          IconButton(
            onPressed: onPause,
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
              fixedSize: const Size(40, 40),
            ),
          ),
        ],
      ),
    );
  }
}
