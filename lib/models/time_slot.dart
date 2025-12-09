class TimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final bool isAvailable;
  final String sessionType;
  final DateTime createdAt;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.isAvailable,
    required this.sessionType,
    required this.createdAt,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      durationMinutes: json['duration_minutes'] as int,
      isAvailable: json['is_available'] as bool,
      sessionType: json['session_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'is_available': isAvailable,
      'session_type': sessionType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
