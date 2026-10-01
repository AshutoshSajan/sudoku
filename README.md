<div align="center">

<img src="web/icons/Icon-512.png" width="120" alt="Sudoku app icon">

# Sudoku

**A beautiful, modern Sudoku puzzle game — one codebase, every screen.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%E2%80%A2%20iOS%20%E2%80%A2%20Web%20%E2%80%A2%20Desktop-4CAF50)](https://flutter.dev/multi-platform)
[![Netlify Status](https://api.netlify.com/api/v1/badges/8fb5f669-c274-4746-a221-85a75dc6c6fb/deploy-status)](https://app.netlify.com/projects/solve-sudoku)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

🎮 **[Play it live](https://solve-sudoku.netlify.app)**

</div>

---

## ✨ Features

| Area | Details |
|------|---------|
| 🎯 Difficulties | Easy · Medium · Hard · Expert — every puzzle verified to have exactly one solution |
| ✏️ Notes mode | Pencil-mark candidates, auto-cleaned when digits are placed |
| 💡 Hints | 3 per game on Easy/Medium — disabled on Hard & Expert |
| ↩️ Undo & erase | Full move history, one-tap erase |
| ❌ Mistake limit | 3 wrong entries ends the game |
| ⏱️ Timer | Auto-pauses in background, manual pause hides the board |
| ⌨️ Keyboards | Laptop keys (1–9, arrows, U/N/H) + Android/iOS touch keyboard |
| 💬 Tooltips | Hover/long-press any icon for what it does |
| ❓ Help screen | In-game "How to Play" guide (tap the **?** icon) |
| 🌓 Themes | System-aware dark & light, toggleable |
| 📱 Responsive | Full-width board with distributed spacing on phones, even card grid on desktop, scroll fallback on tiny windows |

### 🎚️ Difficulties

| Level | Cells removed | Hints |
|-------|--------------:|-------|
| Easy | 30 | 3 |
| Medium | 40 | 3 |
| Hard | 50 | — |
| Expert | 55 | — |

### ⌨️ Keyboard shortcuts (desktop / laptop)

| Keys | Action |
|------|--------|
| `1`–`9` | Place digit |
| `0` / Backspace | Erase cell |
| Arrow keys | Move selection |
| `U` / `N` / `H` | Undo / notes mode / hint |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x (Dart ^3.13.2)
- Android Studio + SDK for Android builds · Chrome for web

```sh
flutter pub get
```

### Run

```sh
flutter run -d chrome   # web
flutter run -d linux    # desktop
flutter run             # Android device / emulator
flutter devices         # list targets
```

### Verify & release

```sh
flutter analyze
flutter test
flutter build web --release
flutter build apk
```

### Deploy (web)

The site deploys to Netlify from the prebuilt output:

```sh
flutter build web --release
netlify deploy --prod   # publish = build/web (see netlify.toml)
```

---

## 🗂️ Project Structure

```text
lib/
├── main.dart              # App entry point, theme mode state
├── models/
│   └── sudoku_game.dart   # State, generation, solver, rules
├── screens/
│   ├── home_screen.dart   # Landing + difficulty grid
│   ├── game_screen.dart   # Gameplay (board, controls, keyboard input)
│   └── help_screen.dart   # In-game "How to Play" guide
├── theme/
│   └── app_theme.dart     # Material 3 light/dark themes, board colors
└── widgets/
    ├── sudoku_board.dart  # 9×9 board, highlights, errors, notes
    ├── number_pad.dart    # 1–9 entry with remaining-count badges
    ├── action_bar.dart    # Undo, erase, notes toggle, hint
    ├── game_header.dart   # Difficulty, timer, mistakes, pause, help
    └── win_dialog.dart    # Win / game-over dialogs
web/
├── icons/                 # PWA + maskable + Apple touch icons
├── favicon.png
└── manifest.json
```

## 🧩 How puzzles are generated

1. A complete grid is built with randomized backtracking (seeded diagonal boxes).
2. Cells are removed one by one — a removal sticks only if the puzzle still has
   exactly one solution (capped solver check).

## 📖 Rules refresher

Fill the 9×9 grid so every row, column, and 3×3 box contains 1–9 exactly once.
Locked (given) cells can't be changed. Stuck? Open the in-game help via **?**.

---

<div align="center">

Built with 💙 using Flutter · [Docs](https://docs.flutter.dev/) · [Live demo](https://solve-sudoku.netlify.app)

</div>
