class LearningProgress {
  final int? id;
  final String level;
  final String unitId;
  final String unitName;
  final int lessonIndex;
  final String status; // not_started / in_progress / completed
  final int score;
  final String updatedAt;

  const LearningProgress({
    this.id,
    required this.level,
    required this.unitId,
    required this.unitName,
    this.lessonIndex = 0,
    this.status = 'not_started',
    this.score = 0,
    required this.updatedAt,
  });

  factory LearningProgress.fromMap(Map<String, dynamic> map) {
    return LearningProgress(
      id: map['id'] as int?,
      level: map['level'] as String? ?? 'A1',
      unitId: map['unit_id'] as String? ?? '',
      unitName: map['unit_name'] as String? ?? '',
      lessonIndex: map['lesson_index'] as int? ?? 0,
      status: map['status'] as String? ?? 'not_started',
      score: map['score'] as int? ?? 0,
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'level': level,
        'unit_id': unitId,
        'unit_name': unitName,
        'lesson_index': lessonIndex,
        'status': status,
        'score': score,
        'updated_at': updatedAt,
      };

  LearningProgress copyWith({
    int? id,
    String? level,
    String? unitId,
    String? unitName,
    int? lessonIndex,
    String? status,
    int? score,
    String? updatedAt,
  }) {
    return LearningProgress(
      id: id ?? this.id,
      level: level ?? this.level,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      lessonIndex: lessonIndex ?? this.lessonIndex,
      status: status ?? this.status,
      score: score ?? this.score,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
