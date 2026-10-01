import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sudoku_game.dart';
import 'help_screen.dart';
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
  Timer? _ticker;
  bool _isLoading = true;

  /// Guards against overlapping generations (latest wins).
  int _generation = 0;

  /// Focus for laptop/desktop keyboard input.
  final FocusNode _screenFocus = FocusNode();

  /// Hidden input that summons the Android/iOS touch keyboard.
  final FocusNode _softInputFocus = FocusNode();
  final TextEditingController _softInputController = TextEditingController();

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
    _ticker?.cancel();
    _screenFocus.dispose();
    _softInputFocus.dispose();
    _softInputController.dispose();
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
    // Cancel any previous ticker and invalidate in-flight generations.
    _ticker?.cancel();
    _ticker = null;
    final current = ++_generation;
    setState(() => _isLoading = true);
    // Generate off the UI thread (loading indicator stays responsive).
    SudokuGame.generate(widget.difficulty).then((newGame) {
      if (!mounted || current != _generation) return;
      newGame.startTimer();
      setState(() {
        game = newGame;
        _isLoading = false;
      });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_isLoading && !game.isPaused) setState(() {});
      });
    });
  }

  // ── Handlers ─────────────────────────────────────────────────────

  void _selectCell(int row, int col) {
    setState(() => game.selectCell(row, col));
    // On phones/tablets, selecting a cell summons the touch keyboard
    // via the hidden input; tapping a locked cell dismisses it.
    if (_isMobile) {
      if (game.selectedRow == -1) {
        _softInputFocus.unfocus();
        _screenFocus.requestFocus();
      } else {
        _softInputFocus.requestFocus();
      }
    }
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
    if (game.isPaused) _softInputFocus.unfocus();
  }

  // ── Keyboard input (laptop/desktop + touch keyboard) ─────────────

  /// Touch keyboards only exist on mobile – everywhere else the on-screen
  /// number pad plus the physical keyboard cover input.
  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Numpad keys on layouts where keyLabel isn't already the digit.
  static final _numpadDigits = <LogicalKeyboardKey, int>{
    LogicalKeyboardKey.numpad0: 0,
    LogicalKeyboardKey.numpad1: 1,
    LogicalKeyboardKey.numpad2: 2,
    LogicalKeyboardKey.numpad3: 3,
    LogicalKeyboardKey.numpad4: 4,
    LogicalKeyboardKey.numpad5: 5,
    LogicalKeyboardKey.numpad6: 6,
    LogicalKeyboardKey.numpad7: 7,
    LogicalKeyboardKey.numpad8: 8,
    LogicalKeyboardKey.numpad9: 9,
  };

  /// Handles laptop/desktop keyboard events: 1–9 to fill, 0/Backspace to
  /// erase, arrows to move selection, U/N/H for undo/notes/hint.
  KeyEventResult _onScreenKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _isLoading) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _erase();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveSelection(0, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveSelection(0, 1);
      return KeyEventResult.handled;
    }
    final numpadDigit = _numpadDigits[key];
    if (numpadDigit != null) {
      if (numpadDigit == 0) {
        _erase();
      } else {
        _setNumber(numpadDigit);
      }
      return KeyEventResult.handled;
    }
    if (key.keyLabel.length == 1) {
      final digit = int.tryParse(key.keyLabel);
      if (digit != null) {
        if (digit == 0) {
          _erase();
        } else {
          _setNumber(digit);
        }
        return KeyEventResult.handled;
      }
      switch (key.keyLabel.toLowerCase()) {
        case 'u':
          _undo();
          return KeyEventResult.handled;
        case 'n':
          _toggleNotes();
          return KeyEventResult.handled;
        case 'h':
          _hint();
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Moves the cell selection with the arrow keys (clamped to the board).
  void _moveSelection(int dRow, int dCol) {
    if (_isLoading || game.isCompleted || game.isGameOver) return;
    setState(() {
      if (game.selectedRow == -1 || game.selectedCol == -1) {
        game.selectedRow = 0;
        game.selectedCol = 0;
      } else {
        game.selectedRow = (game.selectedRow + dRow).clamp(0, 8);
        game.selectedCol = (game.selectedCol + dCol).clamp(0, 8);
      }
    });
  }

  /// Handles digits typed on the Android/iOS touch keyboard.
  void _onSoftInput(String text) {
    if (_isLoading || text.isEmpty) return;
    final digit = int.tryParse(text.characters.last);
    // Clear so the next keypress always counts as a change.
    // (Programmatic clears don't re-trigger onChanged.)
    _softInputController.clear();
    if (digit == null) return;
    if (digit == 0) {
      _erase();
    } else {
      _setNumber(digit);
    }
  }

  void _goBack() {
    if (!_isLoading) game.pauseTimer();
    Navigator.of(context).pop();
  }

  void _showHelp() {
    if (_isLoading) return;
    _softInputFocus.unfocus();
    game.pauseTimer();
    setState(() {});
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HelpScreen()))
        .then((_) {
          if (mounted && !_isLoading) {
            setState(() => game.resumeTimer());
          }
        });
  }

  void _showWinDialog() {
    _softInputFocus.unfocus();
    WinDialog.show(
      context,
      difficulty: game.difficulty,
      time: game.formattedTime,
      mistakes: game.mistakes,
      onNewGame: () {
        Navigator.of(context).pop(); // close dialog
        _startNewGame();
      },
      onHome: () {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(); // go home
      },
    );
  }

  void _showGameOverDialog() {
    _softInputFocus.unfocus();
    game.pauseTimer();
    GameOverDialog.show(
      context,
      onRetry: () {
        Navigator.of(context).pop(); // close dialog
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
      // Two-mode layout: tall screens get a full-width board with the
      // extra space distributed (no dead space); short windows (e.g. a
      // resized web app) shrink the board and scroll as a fallback.
      body: SafeArea(
        child: Focus(
          focusNode: _screenFocus,
          autofocus: true,
          onKeyEvent: _onScreenKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const maxContentWidth = 560.0;
              const minBoardSize = 260.0;
              // Height of header + gaps + action bar + number pad + margins.
              const chromeHeight = 320.0;

              // Single 16px margin on each side.
              final contentWidth =
                  (min(constraints.maxWidth, maxContentWidth + 32) - 32)
                      .clamp(0.0, maxContentWidth)
                      .toDouble();

              // Tall screen: full-width board, extra space distributed.
              // Short screen: shrink the board, scroll if it still overflows.
              final fullBoardFits =
                  contentWidth + chromeHeight <= constraints.maxHeight;
              final boardSize = fullBoardFits
                  ? contentWidth
                  : (constraints.maxHeight - chromeHeight)
                        .clamp(minBoardSize, maxContentWidth)
                        .toDouble();

              final header = GameHeader(
                difficulty: game.difficulty,
                formattedTime: game.formattedTime,
                mistakes: game.mistakes,
                maxMistakes: SudokuGame.maxMistakes,
                isPaused: game.isPaused,
                onPause: _togglePause,
                onBack: _goBack,
                onHelp: _showHelp,
              );
              final boardArea = SizedBox.square(
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
              );
              final actions = ActionBar(
                onUndo: _undo,
                onErase: _erase,
                onToggleNotes: _toggleNotes,
                onHint: _hint,
                isNotesActive: game.isNotesMode,
                canUndo: game.canUndo,
                hintsRemaining: game.hintsRemaining,
              );
              final pad = NumberPad(
                onNumberSelected: _setNumber,
                getRemainingCount: game.getRemainingCount,
              );
              // Hidden input that summons the Android/iOS touch keyboard.
              // Zero visual footprint.
              final hiddenInput = <Widget>[
                if (_isMobile)
                  SizedBox(
                    width: 1,
                    height: 1,
                    child: TextField(
                      focusNode: _softInputFocus,
                      controller: _softInputController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: _onSoftInput,
                    ),
                  ),
              ];

              if (fullBoardFits) {
                // Spread content across the full height – no dead space.
                return Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      children: [
                        header,
                        const Spacer(),
                        boardArea,
                        const SizedBox(height: 24),
                        actions,
                        const SizedBox(height: 20),
                        pad,
                        const Spacer(flex: 2),
                        ...hiddenInput,
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      children: [
                        header,
                        const SizedBox(height: 12),
                        boardArea,
                        const SizedBox(height: 24),
                        actions,
                        const SizedBox(height: 20),
                        pad,
                        const SizedBox(height: 8),
                        ...hiddenInput,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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
