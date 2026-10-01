<div align="center">

<img src="web/icons/Icon-512.png" width="140" alt="Sudoku app icon">

# Sudoku

### A beautiful, modern Sudoku puzzle game — one codebase, every screen.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%E2%80%A2%20iOS%20%E2%80%A2%20Web%20%E2%80%A2%20Desktop-4CAF50)](https://flutter.dev/multi-platform)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Netlify Status](https://api.netlify.com/api/v1/badges/8fb5f669-c274-4746-a221-85a75dc6c6fb/deploy-status)](https://app.netlify.com/projects/solve-sudoku)

**🎮 [Play it live](https://solve-sudoku.netlify.app) · 📖 [Contributing](CONTRIBUTING.md) · ❓ In-game help via the ? icon**

</div>

---

## ✨ Features

| | |
|---|---|
| 🎯 **4 difficulties** | Easy · Medium · Hard · Expert — every puzzle verified to have exactly one solution |
| ✏️ **Notes mode** | Pencil-mark candidates, auto-cleaned when digits land |
| 💡 **Hints** | 3 per game on Easy/Medium — disabled on Hard & Expert |
| ↩️ **Undo & erase** | Full move history, one-tap erase |
| ❌ **Mistake limit** | 3 wrong entries ends the game |
| ⏱️ **Timer** | Auto-pauses in background, manual pause hides the board |
| ⌨️ **Keyboards** | Laptop keys + Android/iOS touch keyboard |
| 💬 **Tooltips** | Hover / long-press any icon to learn it |
| 🌓 **Themes** | System-aware dark & light, toggleable |
| 📱 **Responsive** | Full-width board on phones, even grids on desktop, scroll fallback on tiny windows |

### 🎚️ Difficulties

| Level | Cells removed | Hints |
|:------|--------------:|:-----:|
| Easy | 30 | 3 |
| Medium | 40 | 3 |
| Hard | 50 | — |
| Expert | 55 | — |

### ⌨️ Keyboard shortcuts

| Keys | Action |
|------|--------|
| `1`–`9` | Place digit |
| `0` / Backspace | Erase cell |
| Arrow keys | Move selection |
| `U` / `N` / `H` | Undo / notes mode / hint |

---

## 🚀 Run it yourself

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x · Chrome for web · Android Studio for Android.

```sh
flutter pub get

flutter run -d chrome   # web
flutter run -d linux    # desktop
flutter run             # Android device / emulator
```

**Verify & release:**

```sh
flutter analyze && flutter test
flutter build web --release
flutter build apk
```

**Deploy the web build** (prebuilt `build/web` → Netlify, see `netlify.toml`):

```sh
flutter build web --release && netlify deploy --prod
```

<details>
<summary><b>🗂️ Project structure</b></summary>

```text
lib/
├── main.dart              # Entry point, theme mode state
├── models/sudoku_game.dart# State, generation, solver, rules
├── screens/
│   ├── home_screen.dart   # Landing + difficulty grid
│   ├── game_screen.dart   # Gameplay (board, controls, keyboards)
│   └── help_screen.dart   # In-game "How to Play" guide
├── theme/app_theme.dart   # Material 3 light/dark themes
└── widgets/               # Board, number pad, action bar, header, dialogs
extension/                 # Chrome/Firefox popup (embeds the web build)
fastlane/                  # F-Droid store metadata
test/                      # 21 unit + widget tests
```

</details>

<details>
<summary><b>🧩 How puzzles are generated</b></summary>

1. A complete grid is built with randomized backtracking (seeded diagonal boxes).
2. Cells are removed one by one — a removal sticks only if the puzzle still has exactly one solution (capped solver check).
3. Generation runs on a background isolate so the UI never freezes.

</details>

---

## 🗺️ Coming soon

- 🦊 Firefox add-on (signed `.xpi` via `web-ext sign`)
- 🧩 Chrome Web Store listing
- 📦 F-Droid release (metadata ready in `fastlane/`)

## 📖 Rules refresher

Fill the 9×9 grid so every row, column, and 3×3 box contains 1–9 exactly once. Locked cells can't be changed. Stuck? Tap **?** in the app.

---

<div align="center">

Built with 💙 using Flutter · GPL-3.0 · [Live demo](https://solve-sudoku.netlify.app)

</div>
