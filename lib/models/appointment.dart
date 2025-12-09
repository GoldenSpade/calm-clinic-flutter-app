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
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
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
    );
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
    };
  }
}
