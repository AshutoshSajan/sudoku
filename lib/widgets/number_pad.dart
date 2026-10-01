import 'package:flutter/material.dart';

/// Modern number pad (1-9) displayed as a single row of rounded buttons,
/// each showing the remaining count as a small badge.
class NumberPad extends StatelessWidget {
  final void Function(int num) onNumberSelected;
  final int Function(int num) getRemainingCount;

  const NumberPad({
    super.key,
    required this.onNumberSelected,
    required this.getRemainingCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(9, (i) {
        final num = i + 1;
        final remaining = getRemainingCount(num);
        final isDisabled = remaining == 0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: isDisabled ? null : () => onNumberSelected(num),
              child: AnimatedOpacity(
                opacity: isDisabled ? 0.25 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: isDark
                            ? primary.withAlpha(25)
                            : primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$num',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
