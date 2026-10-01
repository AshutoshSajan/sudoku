import 'package:flutter/material.dart';

/// A row of icon action buttons: Undo, Erase, Notes, Hint.
class ActionBar extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onErase;
  final VoidCallback onToggleNotes;
  final VoidCallback onHint;
  final bool isNotesActive;
  final bool canUndo;
  final int hintsRemaining;

  const ActionBar({
    super.key,
    required this.onUndo,
    required this.onErase,
    required this.onToggleNotes,
    required this.onHint,
    required this.isNotesActive,
    required this.canUndo,
    required this.hintsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.undo_rounded,
          label: 'Undo',
          onTap: canUndo ? onUndo : null,
          color: theme.colorScheme.onSurface,
        ),
        _ActionButton(
          icon: Icons.backspace_outlined,
          label: 'Erase',
          onTap: onErase,
          color: theme.colorScheme.onSurface,
        ),
        _ActionButton(
          icon: Icons.edit_outlined,
          label: 'Notes',
          onTap: onToggleNotes,
          isActive: isNotesActive,
          color: isNotesActive ? primary : theme.colorScheme.onSurface,
          activeBackgroundColor: primary.withAlpha(25),
        ),
        _ActionButton(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Hint',
          onTap: hintsRemaining > 0 ? onHint : null,
          badge: '$hintsRemaining',
          color: theme.colorScheme.onSurface,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final Color color;
  final Color? activeBackgroundColor;
  final String? badge;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    required this.color,
    this.activeBackgroundColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 150),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? activeBackgroundColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 24, color: color),
                  if (badge != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withAlpha(isEnabled ? 180 : 80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
