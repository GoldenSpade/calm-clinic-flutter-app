import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/time_slot.dart';
import '../models/appointment.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  // Get available time slots
  static Future<List<TimeSlot>> getAvailableTimeSlots({
    DateTime? startDate,
    DateTime? endDate,
    int? durationMinutes,
  }) async {
    dynamic query = client.from('time_slots').select().eq('is_available', true);

    if (startDate != null) {
      query = query.gte('start_time', startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.lte('start_time', endDate.toIso8601String());
    }

    if (durationMinutes != null) {
      query = query.eq('duration_minutes', durationMinutes);
    }

    query = query.order('start_time', ascending: true);

    final response = await query;
    return (response as List)
        .map((json) => TimeSlot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Create appointment
  static Future<Appointment> createAppointment(Appointment appointment) async {
    final response = await client
        .from('appointments')
        .insert(appointment.toJson())
        .select()
        .single();

    // Update time slot to mark as unavailable
    await client
        .from('time_slots')
        .update({'is_available': false})
        .eq('id', appointment.timeSlotId);

    return Appointment.fromJson(response);
  }

  // Get appointments (for admin)
  static Future<List<Appointment>> getAppointments() async {
    final response = await client
        .from('appointments')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
