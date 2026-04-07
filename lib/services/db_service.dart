import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_pkg;
import '../models/progress.dart';
import '../models/vocabulary.dart';
import '../models/session_history.dart';

// ============================================================
// DbService — SQLite 本地数据库
// 修复：所有高频查询字段添加索引
// ============================================================
class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final fullPath = path_pkg.join(dbPath, 'spanish_tutor.db');
    return openDatabase(
      fullPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ---- 学习进度表 ----
    await db.execute('''
      CREATE TABLE learning_progress (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        level       TEXT    NOT NULL DEFAULT 'A1',
        unit_id     TEXT    NOT NULL,
        unit_name   TEXT    NOT NULL,
        lesson_index INTEGER NOT NULL DEFAULT 0,
        status      TEXT    NOT NULL DEFAULT 'not_started',
        score       INTEGER NOT NULL DEFAULT 0,
        updated_at  TEXT    NOT NULL
      )
    ''');
    // 修复：添加索引，按级别查询进度
    await db.execute(
        'CREATE INDEX idx_progress_level ON learning_progress(level)');
    await db.execute(
        'CREATE UNIQUE INDEX idx_progress_unit ON learning_progress(unit_id)');

    // ---- 词汇表 ----
    await db.execute('''
      CREATE TABLE vocabulary (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        spanish       TEXT    NOT NULL,
        chinese       TEXT    NOT NULL,
        level         TEXT    NOT NULL,
        unit_id       TEXT    NOT NULL,
        familiarity   INTEGER NOT NULL DEFAULT 0,
        last_reviewed TEXT,
        created_at    TEXT    NOT NULL
      )
    ''');
    // 修复：高频查询字段加索引
    await db.execute(
        'CREATE INDEX idx_vocab_level_unit ON vocabulary(level, unit_id)');
    await db.execute(
        'CREATE INDEX idx_vocab_familiarity ON vocabulary(familiarity)');

    // ---- 会话历史表 ----
    await db.execute('''
      CREATE TABLE session_history (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        mode             TEXT    NOT NULL,
        level            TEXT,
        unit_id          TEXT,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        transcript       TEXT,
        new_words        TEXT,
        created_at       TEXT    NOT NULL
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_session_created ON session_history(created_at DESC)');
  }

  // =========================================================
  // 学习进度 CRUD
  // =========================================================

  Future<void> upsertProgress(LearningProgress p) async {
    final db = await database;
    await db.insert(
      'learning_progress',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LearningProgress>> getProgressByLevel(String level) async {
    final db = await database;
    final rows = await db.query(
      'learning_progress',
      where: 'level = ?',
      whereArgs: [level],
      orderBy: 'unit_id ASC',
    );
    return rows.map(LearningProgress.fromMap).toList();
  }

  Future<LearningProgress?> getProgressByUnit(String unitId) async {
    final db = await database;
    final rows = await db.query(
      'learning_progress',
      where: 'unit_id = ?',
      whereArgs: [unitId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LearningProgress.fromMap(rows.first);
  }

  Future<Map<String, int>> getLevelStats() async {
    final db = await database;
    final result = <String, int>{};
    for (final level in ['A1', 'A2', 'B1']) {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) as total FROM learning_progress WHERE level = ? AND status = ?',
        [level, 'completed'],
      );
      result[level] = (rows.first['total'] as int?) ?? 0;
    }
    return result;
  }

  // =========================================================
  // 词汇 CRUD
  // =========================================================

  Future<void> insertVocabulary(Vocabulary v) async {
    final db = await database;
    await db.insert(
      'vocabulary',
      v.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Vocabulary>> getVocabularyByLevel(String level) async {
    final db = await database;
    final rows = await db.query(
      'vocabulary',
      where: 'level = ?',
      whereArgs: [level],
      orderBy: 'familiarity ASC, created_at DESC',
    );
    return rows.map(Vocabulary.fromMap).toList();
  }

  Future<List<Vocabulary>> getAllVocabulary() async {
    final db = await database;
    final rows = await db.query(
      'vocabulary',
      orderBy: 'created_at DESC',
    );
    return rows.map(Vocabulary.fromMap).toList();
  }

  Future<void> updateFamiliarity(int id, int familiarity) async {
    final db = await database;
    await db.update(
      'vocabulary',
      {
        'familiarity': familiarity,
        'last_reviewed': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getVocabularyCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as cnt FROM vocabulary');
    return (result.first['cnt'] as int?) ?? 0;
  }

  // =========================================================
  // 会话历史 CRUD
  // =========================================================

  Future<void> insertSession(SessionHistory s) async {
    final db = await database;
    await db.insert('session_history', s.toMap());
  }

  Future<List<SessionHistory>> getRecentSessions({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'session_history',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(SessionHistory.fromMap).toList();
  }

  Future<int> getTotalStudySeconds() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(duration_seconds) as total FROM session_history');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
