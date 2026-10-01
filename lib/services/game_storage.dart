import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/sudoku_game.dart';

/// Persists the in-progress game so leaving the app always resumes
/// where the player left off. Works on mobile, desktop, and web.
class GameStorage {
  static const _key = 'autosave_game_v1';

  /// Saves [game], or deletes the save when the game is finished —
  /// completed and lost games never resume.
  static Future<void> save(SudokuGame game) async {
    final prefs = await SharedPreferences.getInstance();
    if (game.isCompleted || game.isGameOver) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, jsonEncode(game.toJson()));
  }

  /// Loads the saved game, or null when there is none, it is corrupt,
  /// stale, or already finished (corrupt saves are deleted).
  static Future<SudokuGame?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final game = SudokuGame.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      if (game == null) await prefs.remove(_key);
      return game;
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Lightweight snapshot for the home screen resume card.
  static Future<SaveSummary?> summary() async {
    final game = await load();
    if (game == null) return null;
    return SaveSummary(
      difficulty: game.difficulty,
      formattedTime: game.formattedTime,
      mistakes: game.mistakes,
    );
  }
}

/// What the home screen shows about a resumable game.
class SaveSummary {
  final Difficulty difficulty;
  final String formattedTime;
  final int mistakes;

  const SaveSummary({
    required this.difficulty,
    required this.formattedTime,
    required this.mistakes,
  });
}
