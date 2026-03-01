import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dictionary_model.dart';
import 'dictionary_parser.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'dictionary.db');

    print('📂 Database path: $path');

    // Check if database exists
    final exists = await databaseFactory.databaseExists(path);

    if (!exists) {
      print('🆕 Creating new database...');
      // Create the database with schema
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      
      print('📥 Importing dictionary data...');
      await _importDictionaryData(db);
      
      return db;
    } else {
      print('✅ Using existing database');
      final db = await openDatabase(path, version: 1);
      
      // Ensure all tables exist (for databases created before all tables were added)
      await _ensureTablesExist(db);
      
      // Check if database is empty and import if needed
      await _ensureDictionaryDataImported(db);
      
      return db;
    }
  }

  Future<void> _ensureDictionaryDataImported(Database db) async {
    try {
      // Check if headwords table has data
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM headwords LIMIT 1');
      final count = result.isNotEmpty ? (result[0]['count'] as int? ?? 0) : 0;
      
      if (count == 0) {
        print('📥 Dictionary table empty, importing data...');
        try {
          await _importDictionaryData(db);
        } catch (e) {
          print('⚠️ Dictionary import failed, adding sample data for testing: $e');
          await _addSampleData(db);
        }
      } else {
        print('✅ Dictionary data already exists ($count headwords)');
      }
    } catch (e) {
      print('Error checking dictionary data: $e');
    }
  }

  Future<void> _addSampleData(Database db) async {
    try {
      print('🔧 Adding sample data for testing...');
      
      // Insert sample headwords
      await db.insert('headwords', {
        'id': 1,
        'term': 'apple',
        'lang': 'en',
        'is_common': 1,
        'frequency': 100,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('headwords', {
        'id': 2,
        'term': 'hello',
        'lang': 'en',
        'is_common': 1,
        'frequency': 150,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await db.insert('headwords', {
        'id': 3,
        'term': 'water',
        'lang': 'en',
        'is_common': 1,
        'frequency': 120,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Insert sample senses  
      await db.insert('senses', {
        'id': 1,
        'headword_id': 1,
        'pos': 'noun',
        'definition': 'a fruit with red, yellow, or green skin',
      });
      
      await db.insert('senses', {
        'id': 2,
        'headword_id': 2,
        'pos': 'exclamation',
        'definition': 'used as a greeting',
      });
      
      await db.insert('senses', {
        'id': 3,
        'headword_id': 3,
        'pos': 'noun',
        'definition': 'a clear liquid with no color, taste, or smell',
      });
      
      // Insert sample examples
      await db.insert('examples', {
        'id': 1,
        'sense_id': 1,
        'sentence': 'I eat an apple every day',
        'translation': 'Tôi ăn một quả táo mỗi ngày',
      });
      
      await db.insert('examples', {
        'id': 2,
        'sense_id': 2,
        'sentence': 'Hello, how are you?',
        'translation': 'Xin chào, bạn khỏe không?',
      });
      
      await db.insert('examples', {
        'id': 3,
        'sense_id': 3,
        'sentence': 'Drink more water',
        'translation': 'Uống nhiều nước hơn',
      });
      
      print('✅ Sample data added successfully');
    } catch (e) {
      print('❌ Error adding sample data: $e');
    }
  }

  Future<void> _ensureTablesExist(Database db) async {
    try {
      // Check if search_history table exists
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='search_history'"
      );
      
      if (result.isEmpty) {
        print('🔧 Adding missing search_history table...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            term TEXT NOT NULL,
            lang TEXT NOT NULL,
            searched_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_search_history_term ON search_history(term)');
      }
      
      // Check if learned_words table exists
      final learnedResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='learned_words'"
      );
      
      if (learnedResult.isEmpty) {
        print('🔧 Adding missing learned_words table...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS learned_words (
            headword_id INTEGER PRIMARY KEY,
            mastery_level INTEGER DEFAULT 1,
            last_review DATETIME,
            FOREIGN KEY (headword_id) REFERENCES headwords(id) ON DELETE CASCADE
          )
        ''');
      }
      
      // Check if favorites table exists
      final favResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='favorites'"
      );
      
      if (favResult.isEmpty) {
        print('🔧 Adding missing favorites table...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            headword_id INTEGER NOT NULL UNIQUE,
            added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (headword_id) REFERENCES headwords(id) ON DELETE CASCADE
          )
        ''');
      }
    } catch (e) {
      print('Error ensuring tables: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🏗️  Creating database schema...');

    // Create headwords table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS headwords (
        id INTEGER PRIMARY KEY,
        term TEXT NOT NULL,
        lang TEXT NOT NULL CHECK (lang IN ('en', 'vi')),
        pronunciation TEXT,
        is_common INTEGER DEFAULT 0,
        frequency INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create senses table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS senses (
        id INTEGER PRIMARY KEY,
        headword_id INTEGER NOT NULL,
        pos TEXT,
        definition TEXT NOT NULL,
        domain TEXT,
        FOREIGN KEY (headword_id) REFERENCES headwords(id) ON DELETE CASCADE
      )
    ''');

    // Create examples table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS examples (
        id INTEGER PRIMARY KEY,
        sense_id INTEGER NOT NULL,
        sentence TEXT,
        translation TEXT,
        FOREIGN KEY (sense_id) REFERENCES senses(id) ON DELETE CASCADE
      )
    ''');

    // Create favorites table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        headword_id INTEGER NOT NULL UNIQUE,
        added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (headword_id) REFERENCES headwords(id) ON DELETE CASCADE
      )
    ''');

    // Create search history table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        term TEXT NOT NULL,
        lang TEXT NOT NULL,
        searched_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create learned words table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS learned_words (
        headword_id INTEGER PRIMARY KEY,
        mastery_level INTEGER DEFAULT 1,
        last_review DATETIME,
        FOREIGN KEY (headword_id) REFERENCES headwords(id) ON DELETE CASCADE
      )
    ''');

    // Create all indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_headwords_term ON headwords(term COLLATE NOCASE)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_headwords_lang ON headwords(lang)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_senses_headword ON senses(headword_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_examples_sense ON examples(sense_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_search_history_term ON search_history(term)');

    print('✅ Schema created');
  }

  Future<void> _importDictionaryData(Database db) async {
    try {
      print('🔄 Starting dictionary import...');
      // Parse both dictionary files
      final data = await DictionaryParser.parseBothFiles();

      final headwords = data['headwords'] as List<Headword>;
      final senses = data['senses'] as List<Sense>;
      final examples = data['examples'] as List<Example>;

      print('💾 Importing ${headwords.length} headwords...');
      for (final hw in headwords) {
        await db.insert('headwords', hw.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      print('💾 Importing ${senses.length} senses...');
      for (final sense in senses) {
        await db.insert('senses', sense.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      print('💾 Importing ${examples.length} examples...');
      // Batch insert examples for better performance
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final example in examples) {
          batch.insert('examples', example.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
      });

      // Verify import was successful
      final verifyCount = await db.rawQuery('SELECT COUNT(*) as count FROM headwords LIMIT 1');
      final count = verifyCount.isNotEmpty ? (verifyCount[0]['count'] as int? ?? 0) : 0;
      print('✅ Dictionary data imported successfully! Total in DB: $count headwords');
    } catch (e) {
      print('❌ Error importing dictionary: $e');
      rethrow;
    }
  }

  // ==================== SEARCH QUERIES ====================

  /// Search for a term in both languages
  Future<List<Map<String, dynamic>>> search(String query, {int limit = 50}) async {
    final db = await database;
    
    try {
      final results = await db.rawQuery('''
        SELECT h.id, h.term, h.lang, h.is_common,
               s.id as sense_id, s.pos, s.definition,
               e.id as example_id, e.sentence, e.translation
        FROM headwords h
        LEFT JOIN senses s ON s.headword_id = h.id
        LEFT JOIN examples e ON e.sense_id = s.id
        WHERE h.term LIKE ?
        ORDER BY h.is_common DESC, h.term ASC
        LIMIT ?
      ''', ['%$query%', limit]);
      
      return results;
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }

  /// Get detailed word entry
  Future<WordEntry?> getWordEntry(int headwordId) async {
    final db = await database;

    try {
      final hwMaps = await db.query(
        'headwords',
        where: 'id = ?',
        whereArgs: [headwordId],
      );

      if (hwMaps.isEmpty) return null;

      final headword = Headword.fromMap(hwMaps.first);

      // Get senses
      final senseMaps = await db.query(
        'senses',
        where: 'headword_id = ?',
        whereArgs: [headwordId],
      );

      final senses = senseMaps.map((m) => Sense.fromMap(m)).toList();

      // Get examples for each sense
      final examplesBySense = <int, List<Example>>{};
      for (final sense in senses) {
        final exampleMaps = await db.query(
          'examples',
          where: 'sense_id = ?',
          whereArgs: [sense.id],
        );
        examplesBySense[sense.id] = exampleMaps.map((m) => Example.fromMap(m)).toList();
      }

      return WordEntry(
        headword: headword,
        senses: senses,
        examplesBySense: examplesBySense,
      );
    } catch (e) {
      print('❌ Error fetching word: $e');
      return null;
    }
  }

  // ==================== FAVORITES ====================

  Future<void> addFavorite(int headwordId) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'headword_id': headwordId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavorite(int headwordId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'headword_id = ?',
      whereArgs: [headwordId],
    );
  }

  Future<bool> isFavorite(int headwordId) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'headword_id = ?',
      whereArgs: [headwordId],
    );
    return result.isNotEmpty;
  }

  Future<List<WordEntry>> getFavorites() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT h.id FROM headwords h
      JOIN favorites f ON f.headword_id = h.id
      ORDER BY f.added_at DESC
    ''');

    final entries = <WordEntry>[];
    for (final result in results) {
      final entry = await getWordEntry(result['id'] as int);
      if (entry != null) {
        entries.add(entry);
      }
    }
    return entries;
  }

  // ==================== SEARCH HISTORY ====================

  Future<void> addToHistory(String term, String lang) async {
    final db = await database;
    await db.insert(
      'search_history',
      {
        'term': term,
        'lang': lang,
        'searched_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSearchHistory({int limit = 20}) async {
    final db = await database;
    return db.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
    );
  }

  // ==================== STATS ====================

  Future<int> getDictionaryStats() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM headwords');
    return (result.first['count'] as int?) ?? 0;
  }

  // ==================== DATABASE MAINTENANCE ====================

  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
