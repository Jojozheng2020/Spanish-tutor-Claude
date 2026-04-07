class Vocabulary {
  final int? id;
  final String spanish;
  final String chinese;
  final String level;
  final String unitId;
  final int familiarity; // 0-5
  final String? lastReviewed;
  final String createdAt;

  const Vocabulary({
    this.id,
    required this.spanish,
    required this.chinese,
    required this.level,
    required this.unitId,
    this.familiarity = 0,
    this.lastReviewed,
    required this.createdAt,
  });

  factory Vocabulary.fromMap(Map<String, dynamic> map) {
    return Vocabulary(
      id: map['id'] as int?,
      spanish: map['spanish'] as String? ?? '',
      chinese: map['chinese'] as String? ?? '',
      level: map['level'] as String? ?? 'A1',
      unitId: map['unit_id'] as String? ?? '',
      familiarity: map['familiarity'] as int? ?? 0,
      lastReviewed: map['last_reviewed'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'spanish': spanish,
        'chinese': chinese,
        'level': level,
        'unit_id': unitId,
        'familiarity': familiarity,
        if (lastReviewed != null) 'last_reviewed': lastReviewed,
        'created_at': createdAt,
      };

  Vocabulary copyWith({
    int? id,
    String? spanish,
    String? chinese,
    String? level,
    String? unitId,
    int? familiarity,
    String? lastReviewed,
    String? createdAt,
  }) {
    return Vocabulary(
      id: id ?? this.id,
      spanish: spanish ?? this.spanish,
      chinese: chinese ?? this.chinese,
      level: level ?? this.level,
      unitId: unitId ?? this.unitId,
      familiarity: familiarity ?? this.familiarity,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
