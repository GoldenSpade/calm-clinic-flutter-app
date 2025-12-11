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
    final startTimeStr = json['start_time'] as String;
    final endTimeStr = json['end_time'] as String;

    // Parse ISO 8601 string and handle timezone properly
    // Supabase returns time with "+00:00" which means UTC
    // We need to parse it as UTC and then convert to local
    final startTime = _parseUtcTime(startTimeStr);
    final endTime = _parseUtcTime(endTimeStr);

    print('TimeSlot.fromJson: $startTimeStr -> Local: $startTime');

    return TimeSlot(
      id: json['id'] as String,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: json['duration_minutes'] as int,
      isAvailable: json['is_available'] as bool,
      sessionType: json['session_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Parse UTC time string - returns as UTC DateTime
  static DateTime _parseUtcTime(String timeStr) {
    // Replace +00:00 with Z to make Dart parse it as UTC
    String normalizedStr = timeStr;
    if (timeStr.endsWith('+00:00')) {
      normalizedStr = timeStr.replaceAll('+00:00', 'Z');
    } else if (timeStr.endsWith('+00')) {
      normalizedStr = timeStr.replaceAll('+00', 'Z');
    }

    // Parse as UTC and keep it as UTC
    final utcTime = DateTime.parse(normalizedStr).toUtc();

    print('  _parseUtcTime: $timeStr -> UTC: $utcTime');
    return utcTime;
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
