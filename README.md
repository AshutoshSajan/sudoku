# Sudoku

A beautiful, modern Sudoku puzzle game built with Flutter. Play on Android,
iOS, web, Windows, macOS, and Linux from a single codebase.

## Features

- **4 difficulty levels** — Easy, Medium, Hard, Expert (30/40/50/55 cells removed)
- **Unique-solution puzzles** — every generated puzzle is verified to have exactly
  one solution
- **Pencil-mark notes** — jot down candidates with notes mode
- **Undo support** — full move history with undo
- **Hints** — 3 per game on Easy and Medium; disabled on Hard and Expert
- **Mistake limit** — 3 mistakes ends the game
- **Timer with pause** — auto-pauses when the app goes to background
- **Dark / light theme** — follows the system, toggleable from the home screen
- **Responsive layout** — the board shrinks to fit short windows (e.g. resized
  web app) and scrolls as a fallback, so the full board is always reachable
- **Error highlighting** — conflicting entries, same-row/column/box grouping,
  and same-number highlighting

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x (Dart ^3.13.2)
- For Android builds: Android Studio + SDK
- For web: Chrome (or any Chromium browser)

### Install dependencies

```sh
flutter pub get
```

### Run

```sh
# Web
flutter run -d chrome

# Linux desktop
flutter run -d linux

# Android (device or emulator)
flutter run

# List all connected devices first
flutter devices
```

### Build release

```sh
flutter build web
flutter build apk
flutter build linux
```

### Verify

```sh
flutter analyze
flutter test
```

## Project Structure

```text
lib/
├── main.dart              # App entry point, theme mode state
├── models/
│   └── sudoku_game.dart   # Game state, puzzle generation, solver, rules
├── screens/
│   ├── home_screen.dart   # Landing screen with difficulty selection
│   └── game_screen.dart   # Gameplay screen (board + controls + state)
├── theme/
│   └── app_theme.dart     # Light/dark Material 3 themes, board colors
└── widgets/
    ├── sudoku_board.dart  # 9×9 board with selection/error/notes rendering
    ├── number_pad.dart    # 1–9 entry pad with remaining-count badges
    ├── action_bar.dart    # Undo, erase, notes toggle, hint
    ├── game_header.dart   # Difficulty, timer, mistakes, pause/back
    └── win_dialog.dart    # Win and game-over dialogs
test/
└── widget_test.dart       # App launch test
```

## How Puzzles Are Generated

1. A complete valid grid is generated via randomized backtracking.
2. Cells are removed one by one (per-difficulty count), keeping a removal only
   if the puzzle still has exactly one solution (verified with a capped solver).

## Rules Refresher

Fill the 9×9 grid so every row, column, and 3×3 box contains the digits 1–9
exactly once. Locked (given) cells can't be changed.

## Resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
