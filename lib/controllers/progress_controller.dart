import 'package:flutter/foundation.dart';
import '../services/db_service.dart';
import '../models/progress.dart';
import '../models/vocabulary.dart';
import '../models/session_history.dart';

// ============================================================
// ProgressController — 学习进度 & 词汇管理
// ============================================================

class ProgressController extends ChangeNotifier {
  final DbService _db = DbService();

  // ---- 进度数据 ----
  Map<String, List<LearningProgress>> _progressByLevel = {};
  Map<String, int> _completedByLevel = {};

  // ---- 词汇数据 ----
  List<Vocabulary> _vocabulary = [];
  int _vocabCount = 0;

  // ---- 历史数据 ----
  List<SessionHistory> _recentSessions = [];
  int _totalStudySeconds = 0;

  bool _isLoading = false;

  // ---- Getters ----
  Map<String, List<LearningProgress>> get progressByLevel => _progressByLevel;
  Map<String, int> get completedByLevel => _completedByLevel;
  List<Vocabulary> get vocabulary => List.unmodifiable(_vocabulary);
  int get vocabCount => _vocabCount;
  List<SessionHistory> get recentSessions => List.unmodifiable(_recentSessions);
  int get totalStudySeconds => _totalStudySeconds;
  bool get isLoading => _isLoading;

  String get totalStudyFormatted {
    final h = _totalStudySeconds ~/ 3600;
    final m = (_totalStudySeconds % 3600) ~/ 60;
    if (h > 0) return '$h小时$m分钟';
    return '$m分钟';
  }

  // =========================================================
  // 数据加载
  // =========================================================

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _loadProgress(),
        _loadVocabulary(),
        _loadSessions(),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('[ProgressController] loadAll error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProgress() async {
    final byLevel = <String, List<LearningProgress>>{};
    final completed = <String, int>{};
    for (final level in ['A1', 'A2', 'B1']) {
      final list = await _db.getProgressByLevel(level);
      byLevel[level] = list;
      completed[level] = list.where((p) => p.status == 'completed').length;
    }
    _progressByLevel = byLevel;
    _completedByLevel = completed;
  }

  Future<void> _loadVocabulary() async {
    _vocabulary = await _db.getAllVocabulary();
    _vocabCount = await _db.getVocabularyCount();
  }

  Future<void> _loadSessions() async {
    _recentSessions = await _db.getRecentSessions();
    _totalStudySeconds = await _db.getTotalStudySeconds();
  }

  // =========================================================
  // 进度更新
  // =========================================================

  Future<void> markUnitCompleted(String level, String unitId, String unitName,
      {int score = 100}) async {
    await _db.upsertProgress(LearningProgress(
      level: level,
      unitId: unitId,
      unitName: unitName,
      status: 'completed',
      score: score,
      updatedAt: DateTime.now().toIso8601String(),
    ));
    await _loadProgress();
    notifyListeners();
  }

  Future<void> markUnitInProgress(
      String level, String unitId, String unitName, int lessonIndex) async {
    await _db.upsertProgress(LearningProgress(
      level: level,
      unitId: unitId,
      unitName: unitName,
      lessonIndex: lessonIndex,
      status: 'in_progress',
      updatedAt: DateTime.now().toIso8601String(),
    ));
    await _loadProgress();
    notifyListeners();
  }

  double getLevelProgress(String level) {
    // A1=10单元, A2=10单元, B1=10单元
    const totalUnits = 10;
    final completed = _completedByLevel[level] ?? 0;
    return completed / totalUnits;
  }

  // =========================================================
  // 词汇管理
  // =========================================================

  Future<void> addVocabulary(Vocabulary vocab) async {
    await _db.insertVocabulary(vocab);
    await _loadVocabulary();
    notifyListeners();
  }

  Future<void> updateFamiliarity(int id, int familiarity) async {
    await _db.updateFamiliarity(id, familiarity.clamp(0, 5));
    await _loadVocabulary();
    notifyListeners();
  }

  List<Vocabulary> getVocabByLevel(String level) {
    return _vocabulary.where((v) => v.level == level).toList();
  }

  // =========================================================
  // 统计数据
  // =========================================================

  int get totalSessionCount => _recentSessions.length;

  int get completedUnitsTotal {
    return _completedByLevel.values.fold(0, (a, b) => a + b);
  }
}
