import 'time_slot.dart';

class Appointment {
  final String? id;
  final String timeSlotId;
  final String clientName;
  final String? clientEmail;
  final String? clientPhone;
  final String sessionType;
  final String? notes;
  final String status;
  final DateTime? createdAt;
  final TimeSlot? timeSlot;
  final DateTime? appointmentStartTime;
  final DateTime? appointmentEndTime;

  Appointment({
    this.id,
    required this.timeSlotId,
    required this.clientName,
    this.clientEmail,
    this.clientPhone,
    required this.sessionType,
    this.notes,
    this.status = 'confirmed',
    this.createdAt,
    this.timeSlot,
    this.appointmentStartTime,
    this.appointmentEndTime,
  });

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
    final kyivOffset = _getKyivOffset(utcTime);
    final kyivTime = utcTime.add(Duration(hours: kyivOffset));

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

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final startTimeStr = json['appointment_start_time'] as String?;
    final endTimeStr = json['appointment_end_time'] as String?;

    // Parse appointment times using Kyiv timezone conversion (same as TimeSlot)
    DateTime? parsedStartTime;
    DateTime? parsedEndTime;

    if (startTimeStr != null) {
      parsedStartTime = _parseUtcTime(startTimeStr);
      print('Appointment.fromJson: start_time $startTimeStr -> Kyiv: $parsedStartTime');
    }
    if (endTimeStr != null) {
      parsedEndTime = _parseUtcTime(endTimeStr);
      print('Appointment.fromJson: end_time $endTimeStr -> Kyiv: $parsedEndTime');
    }

    return Appointment(
      id: json['id'] as String?,
      timeSlotId: json['time_slot_id'] as String,
      clientName: json['client_name'] as String,
      clientEmail: json['client_email'] as String?,
      clientPhone: json['client_phone'] as String?,
      sessionType: json['session_type'] as String,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'confirmed',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      timeSlot: json['time_slot'] != null
          ? TimeSlot.fromJson(json['time_slot'] as Map<String, dynamic>)
          : null,
      appointmentStartTime: parsedStartTime,
      appointmentEndTime: parsedEndTime,
    );
  }

  /// Convert Kyiv time to UTC ISO string for database storage
  static String _kyivTimeToUtcString(DateTime kyivTime) {
    // Get the Kyiv offset for this time
    // We need to calculate what UTC time would give us this Kyiv time
    // Kyiv time = UTC + offset, so UTC = Kyiv time - offset
    final kyivOffset = _getKyivOffset(kyivTime.subtract(const Duration(hours: 3))); // approximate UTC
    final utcTime = kyivTime.subtract(Duration(hours: kyivOffset));

    print('_kyivTimeToUtcString: Kyiv $kyivTime (offset $kyivOffset) -> UTC $utcTime');

    return utcTime.toIso8601String();
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'time_slot_id': timeSlotId,
      'client_name': clientName,
      if (clientEmail != null) 'client_email': clientEmail,
      if (clientPhone != null) 'client_phone': clientPhone,
      'session_type': sessionType,
      if (notes != null) 'notes': notes,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (appointmentStartTime != null)
        'appointment_start_time': _kyivTimeToUtcString(appointmentStartTime!),
      if (appointmentEndTime != null)
        'appointment_end_time': _kyivTimeToUtcString(appointmentEndTime!),
    };
  }
}
