import 'package:shared_preferences/shared_preferences.dart';

class RecentGameModel {
  final String title;
  final String url;
  final String category;
  final String colorHex;
  final DateTime playedAt;

  RecentGameModel({
    required this.title,
    required this.url,
    required this.category,
    required this.colorHex,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'category': category,
      'colorHex': colorHex,
      'playedAt': playedAt.toIso8601String(),
    };
  }

  factory RecentGameModel.fromJson(Map<String, dynamic> json) {
    return RecentGameModel(
      title: json['title'] as String,
      url: json['url'] as String,
      category: json['category'] as String,
      colorHex: json['colorHex'] as String,
      playedAt: DateTime.parse(json['playedAt'] as String),
    );
  }
}

class RecentGamesService {
  static const String _key = 'recent_games';
  static const int _maxGames = 5;

  static Future<void> addRecentGame({
    required String title,
    required String url,
    required String category,
    required String colorHex,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentGamesJson = prefs.getStringList(_key) ?? [];

      // Create new game entry
      final newGame = RecentGameModel(
        title: title,
        url: url,
        category: category,
        colorHex: colorHex,
        playedAt: DateTime.now(),
      );

      // Convert existing games to models
      final games = recentGamesJson
          .map((json) => RecentGameModel.fromJson(
              Map<String, dynamic>.from(
                  _parseJson(json) as Map<dynamic, dynamic>)))
          .toList();

      // Remove if game already exists
      games.removeWhere((g) => g.url == url);

      // Add new game to the beginning
      games.insert(0, newGame);

      // Keep only the last 5 games
      if (games.length > _maxGames) {
        games.removeRange(_maxGames, games.length);
      }

      // Convert back to JSON and save
      final updatedJson =
          games.map((g) => _jsonEncode(g.toJson())).toList();
      await prefs.setStringList(_key, updatedJson);
    } catch (e) {
      print('Error adding recent game: $e');
    }
  }

  static Future<List<RecentGameModel>> getRecentGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentGamesJson = prefs.getStringList(_key) ?? [];

      return recentGamesJson
          .map((json) => RecentGameModel.fromJson(
              Map<String, dynamic>.from(
                  _parseJson(json) as Map<dynamic, dynamic>)))
          .toList();
    } catch (e) {
      print('Error fetching recent games: $e');
      return [];
    }
  }

  static Future<void> clearRecentGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing recent games: $e');
    }
  }

  // Simple JSON encoding/decoding since we're storing as strings
  static String _jsonEncode(Map<String, dynamic> data) {
    return data.toString();
  }

  static dynamic _parseJson(String jsonString) {
    // Simple parsing for our specific case
    final map = <String, dynamic>{};
    final items = jsonString
        .replaceAll('{', '')
        .replaceAll('}', '')
        .split(', ')
        .where((item) => item.isNotEmpty);

    for (var item in items) {
      final parts = item.split(': ');
      if (parts.length == 2) {
        final key = parts[0].trim();
        var value = parts[1].trim();

        // Try to parse boolean and numeric values
        if (value.toLowerCase() == 'true') {
          map[key] = true;
        } else if (value.toLowerCase() == 'false') {
          map[key] = false;
        } else if (double.tryParse(value) != null) {
          map[key] = double.parse(value);
        } else {
          // Remove quotes if present
          if (value.startsWith("'") && value.endsWith("'")) {
            value = value.substring(1, value.length - 1);
          }
          map[key] = value;
        }
      }
    }
    return map;
  }
}
