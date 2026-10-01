import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sudoku_game.dart';
import '../widgets/sudoku_board.dart';
import '../widgets/number_pad.dart';
import '../widgets/action_bar.dart';
import '../widgets/game_header.dart';
import '../widgets/win_dialog.dart';

/// Main gameplay screen that assembles the board, controls, and game state.
class GameScreen extends StatefulWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late SudokuGame game;
  late Timer _ticker;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Generate puzzle after the first frame so the loading UI can show
    WidgetsBinding.instance.addPostFrameCallback((_) => _startNewGame());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_isLoading) game.pauseTimer();
    _ticker.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isLoading) return;
    if (state == AppLifecycleState.paused) {
      game.pauseTimer();
      setState(() {});
    }
  }

  void _startNewGame() {
    setState(() => _isLoading = true);
    // Use a microtask to allow the loading indicator to render
    Future.microtask(() {
      final newGame = SudokuGame(widget.difficulty);
      newGame.startTimer();
      if (mounted) {
        setState(() {
          game = newGame;
          _isLoading = false;
        });
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isLoading && !game.isPaused) setState(() {});
    });
  }

  // ── Handlers ─────────────────────────────────────────────────────

  void _selectCell(int row, int col) {
    setState(() => game.selectCell(row, col));
  }

  void _setNumber(int num) {
    if (_isLoading || game.isCompleted || game.isGameOver) return;
    setState(() {
      final result = game.setNumber(num);
      if (game.isCompleted) {
        _showWinDialog();
      } else if (game.isGameOver) {
        _showGameOverDialog();
      } else if (result == false) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _erase() => setState(() => game.erase());
  void _undo() => setState(() => game.undo());
  void _toggleNotes() => setState(() => game.isNotesMode = !game.isNotesMode);

  void _hint() {
    setState(() {
      final success = game.hint();
      if (!success && game.hintsRemaining <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              game.difficulty.allowsHints
                  ? 'No hints remaining'
                  : 'Hints are disabled on ${game.difficulty.label}',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      if (game.isCompleted) _showWinDialog();
    });
  }

  void _togglePause() {
    setState(() {
      game.isPaused ? game.resumeTimer() : game.pauseTimer();
    });
  }

  void _goBack() {
    if (!_isLoading) game.pauseTimer();
    Navigator.of(context).pop();
  }

  void _showWinDialog() {
    WinDialog.show(
      context,
      difficulty: game.difficulty,
      time: game.formattedTime,
      mistakes: game.mistakes,
      onNewGame: () {
        Navigator.of(context).pop(); // close dialog
        _ticker.cancel();
        _startNewGame();
      },
      onHome: () {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(); // go home
      },
    );
  }

  void _showGameOverDialog() {
    game.pauseTimer();
    GameOverDialog.show(
      context,
      onRetry: () {
        Navigator.of(context).pop(); // close dialog
        _ticker.cancel();
        _startNewGame();
      },
      onHome: () {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(); // go home
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Generating puzzle…',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // LayoutBuilder + scroll fallback: the board shrinks to fit short
      // windows (e.g. a resized web app) and the column scrolls if the
      // window gets too small, so the full board stays reachable.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Vertical space taken by header + controls + spacing.
            const reservedHeight = 330.0;
            const maxContentWidth = 560.0;
            const minBoardSize = 260.0;

            final contentWidth = (constraints.maxWidth - 32)
                .clamp(0.0, maxContentWidth)
                .toDouble();
            final boardSize = min(
              contentWidth,
              constraints.maxHeight - reservedHeight,
            ).clamp(minBoardSize, maxContentWidth).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      // ── Header ──
                      GameHeader(
                        difficulty: game.difficulty,
                        formattedTime: game.formattedTime,
                        mistakes: game.mistakes,
                        maxMistakes: SudokuGame.maxMistakes,
                        isPaused: game.isPaused,
                        onPause: _togglePause,
                        onBack: _goBack,
                      ),

                      const SizedBox(height: 12),

                      // ── Board ──
                      SizedBox.square(
                        dimension: boardSize,
                        child: game.isPaused
                            ? _buildPausedPlaceholder(context)
                            : SudokuBoard(
                                board: game.board,
                                given: game.given,
                                notes: game.notes,
                                selectedRow: game.selectedRow,
                                selectedCol: game.selectedCol,
                                hasError: game.hasError,
                                isInSameGroup: game.isInSameGroup,
                                isSameNumber: game.isSameNumber,
                                onCellTap: _selectCell,
                              ),
                      ),

                      const SizedBox(height: 24),

                      // ── Action Bar ──
                      ActionBar(
                        onUndo: _undo,
                        onErase: _erase,
                        onToggleNotes: _toggleNotes,
                        onHint: _hint,
                        isNotesActive: game.isNotesMode,
                        canUndo: game.canUndo,
                        hintsRemaining: game.hintsRemaining,
                      ),

                      const SizedBox(height: 20),

                      // ── Number Pad ──
                      NumberPad(
                        onNumberSelected: _setNumber,
                        getRemainingCount: game.getRemainingCount,
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Placeholder shown when the game is paused (kept square by its parent).
  Widget _buildPausedPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withAlpha(60),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'Game Paused',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _togglePause,
              child: const Text('Resume'),
            ),
          ],
        ),
      ),
    );
  }
}
