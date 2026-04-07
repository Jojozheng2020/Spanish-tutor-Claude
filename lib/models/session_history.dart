class SessionHistory {
  final int? id;
  final String mode; // teacher / freetalk / quiz
  final String? level;
  final String? unitId;
  final int durationSeconds;
  final String? transcript;
  final List<String> newWords;
  final String createdAt;

  const SessionHistory({
    this.id,
    required this.mode,
    this.level,
    this.unitId,
    this.durationSeconds = 0,
    this.transcript,
    this.newWords = const [],
    required this.createdAt,
  });

  factory SessionHistory.fromMap(Map<String, dynamic> map) {
    final rawWords = map['new_words'] as String?;
    final words = (rawWords != null && rawWords.isNotEmpty)
        ? rawWords.split(',')
        : <String>[];
    return SessionHistory(
      id: map['id'] as int?,
      mode: map['mode'] as String? ?? 'teacher',
      level: map['level'] as String?,
      unitId: map['unit_id'] as String?,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      transcript: map['transcript'] as String?,
      newWords: words,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'mode': mode,
        if (level != null) 'level': level,
        if (unitId != null) 'unit_id': unitId,
        'duration_seconds': durationSeconds,
        if (transcript != null) 'transcript': transcript,
        'new_words': newWords.join(','),
        'created_at': createdAt,
      };

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
