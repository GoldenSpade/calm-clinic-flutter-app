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

  /// Parse UTC time string and convert to Kyiv timezone (UTC+2 winter / UTC+3 summer)
  static DateTime _parseUtcTime(String timeStr) {
    // Replace +00:00 with Z to make Dart parse it as UTC
    String normalizedStr = timeStr;
    if (timeStr.endsWith('+00:00')) {
      normalizedStr = timeStr.replaceAll('+00:00', 'Z');
    } else if (timeStr.endsWith('+00')) {
      normalizedStr = timeStr.replaceAll('+00', 'Z');
    }

    final utcTime = DateTime.parse(normalizedStr);

    // Convert to Kyiv timezone (Europe/Kiev)
    // Winter time (last Sunday of October to last Sunday of March): UTC+2
    // Summer time (last Sunday of March to last Sunday of October): UTC+3
    final kyivOffset = _getKyivOffset(utcTime);
    final kyivTime = utcTime.add(Duration(hours: kyivOffset));

    print('  _parseUtcTime: $timeStr -> UTC: $utcTime -> Kyiv (UTC+$kyivOffset): $kyivTime');
    return kyivTime;
  }

  /// Get Kyiv timezone offset (2 for winter, 3 for summer)
  static int _getKyivOffset(DateTime utcTime) {
    final year = utcTime.year;

    // Find last Sunday of March (start of summer time)
    DateTime marchLastSunday = DateTime.utc(year, 3, 31);
    while (marchLastSunday.weekday != DateTime.sunday) {
      marchLastSunday = marchLastSunday.subtract(const Duration(days: 1));
    }
    // DST starts at 3:00 local time (1:00 UTC)
    final dstStart = DateTime.utc(year, 3, marchLastSunday.day, 1);

    // Find last Sunday of October (end of summer time)
    DateTime octoberLastSunday = DateTime.utc(year, 10, 31);
    while (octoberLastSunday.weekday != DateTime.sunday) {
      octoberLastSunday = octoberLastSunday.subtract(const Duration(days: 1));
    }
    // DST ends at 4:00 local time (1:00 UTC)
    final dstEnd = DateTime.utc(year, 10, octoberLastSunday.day, 1);

    // Check if current time is in DST
    if (utcTime.isAfter(dstStart) && utcTime.isBefore(dstEnd)) {
      return 3; // Summer time UTC+3
    }
    return 2; // Winter time UTC+2
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
