import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../models/time_slot.dart';
import '../../models/appointment.dart';
import '../../services/supabase_service.dart';
import 'booking_form_screen.dart';

// Immutable class for provider parameters
class SlotQueryParams {
  final String sessionType;
  final int durationMinutes;

  const SlotQueryParams({
    required this.sessionType,
    required this.durationMinutes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlotQueryParams &&
          runtimeType == other.runtimeType &&
          sessionType == other.sessionType &&
          durationMinutes == other.durationMinutes;

  @override
  int get hashCode => sessionType.hashCode ^ durationMinutes.hashCode;
}

// Provider для загрузки слотов
final timeSlotsProvider = FutureProvider.family<List<TimeSlot>, SlotQueryParams>(
  (ref, params) async {
    // Start from tomorrow like in React version
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    print('🔍 Fetching slots for session type: ${params.sessionType} (duration: ${params.durationMinutes} min)');
    print('📅 Fetching slots from date: $startOfTomorrow');

    // For 90min sessions, fetch 60min slots but filter by duration
    final searchSessionType = (params.sessionType == '90min') ? '60min' : params.sessionType;

    final slots = await SupabaseService.getAvailableTimeSlots(
      startDate: startOfTomorrow,
      sessionType: searchSessionType,
    );

    // Filter by duration - only keep slots with sufficient duration
    final filteredSlots = slots.where((slot) =>
      slot.durationMinutes >= params.durationMinutes
    ).toList();

    print('📊 Total slots fetched: ${slots.length}, after duration filter: ${filteredSlots.length}');
    if (filteredSlots.isNotEmpty) {
      print('First slot: ${filteredSlots.first.startTime} (duration: ${filteredSlots.first.durationMinutes}min)');
    }

    return filteredSlots;
  },
);

// Provider для загрузки всех подтвержденных записей
final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  print('🔍 Fetching appointments...');
  final appointments = await SupabaseService.getAppointments();
  print('📊 Total appointments: ${appointments.length}');
  for (final apt in appointments) {
    print('  📅 Appointment: ${apt.sessionType}');
    print('     Start: ${apt.appointmentStartTime}');
    print('     End: ${apt.appointmentEndTime}');
    if (apt.timeSlot != null) {
      print('     TimeSlot: ${apt.timeSlot!.startTime} - ${apt.timeSlot!.endTime}');
    }
  }
  return appointments;
});

class SlotInfo {
  final DateTime time;
  final bool isAvailable;
  final bool isSelected;

  SlotInfo({
    required this.time,
    required this.isAvailable,
    this.isSelected = false,
  });
}

class BookingCalendarScreen extends ConsumerStatefulWidget {
  final int durationMinutes;
  final String sessionType;

  const BookingCalendarScreen({
    super.key,
    required this.durationMinutes,
    required this.sessionType,
  });

  @override
  ConsumerState<BookingCalendarScreen> createState() =>
      _BookingCalendarScreenState();
}

class _BookingCalendarScreenState
    extends ConsumerState<BookingCalendarScreen> {
  late DateTime _currentWeekStart;
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  bool _initialized = false;
  late SlotQueryParams _queryParams;

  @override
  void initState() {
    super.initState();
    // Create immutable query params once
    _queryParams = SlotQueryParams(
      sessionType: widget.sessionType,
      durationMinutes: widget.durationMinutes,
    );
    // Начинаем с понедельника текущей недели
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    _currentWeekStart = now.subtract(Duration(days: weekday - 1));
  }

  List<DateTime> _getWeekDays() {
    final days = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      days.add(_currentWeekStart.add(Duration(days: i)));
    }
    return days;
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  // Проверяет, занят ли конкретный временной слот
  // For overlap checking, we need to know the increment size, not the selected duration
  bool _isTimeBooked(
      DateTime slotTime, List<Appointment> appointments) {
    // Use increment (30 or 15 min) instead of selectedDuration for overlap checking
    final increment = widget.durationMinutes >= 60 ? 30 : 15;
    final slotEnd = slotTime.add(Duration(minutes: increment));

    // Check only appointments on the same day
    final slotDay = DateTime(slotTime.year, slotTime.month, slotTime.day);

    for (final appointment in appointments) {
      // Use appointmentStartTime/EndTime if available (new format), otherwise fallback to timeSlot
      DateTime appointmentStart;
      DateTime appointmentEnd;

      if (appointment.appointmentStartTime != null &&
          appointment.appointmentEndTime != null) {
        // New format with exact booking times
        appointmentStart = appointment.appointmentStartTime!;
        appointmentEnd = appointment.appointmentEndTime!;
      } else if (appointment.timeSlot != null) {
        // Old format - fallback to timeSlot
        appointmentStart = appointment.timeSlot!.startTime;

        // Определяем длительность по типу сессии
        int appointmentDuration = 60;
        if (appointment.sessionType == 'consultation_15') {
          appointmentDuration = 15;
        } else if (appointment.sessionType == 'session_60') {
          appointmentDuration = 60;
        } else if (appointment.sessionType == 'session_90') {
          appointmentDuration = 90;
        }

        appointmentEnd =
            appointmentStart.add(Duration(minutes: appointmentDuration));
      } else {
        continue;
      }

      // Check if appointment is on the same day as slot
      final appointmentDay = DateTime(appointmentStart.year, appointmentStart.month, appointmentStart.day);
      if (appointmentDay != slotDay) {
        continue; // Skip appointments from other days
      }

      // Check if this slot time falls within the appointment range
      // A slot is booked if it starts before the appointment ends AND ends after the appointment starts
      final hasOverlap =
          slotTime.isBefore(appointmentEnd) &&
          slotEnd.isAfter(appointmentStart);

      if (hasOverlap) {
        print('      ⛔ Slot ${slotTime.hour}:${slotTime.minute.toString().padLeft(2, '0')} blocked by appointment: ${appointmentStart.hour}:${appointmentStart.minute.toString().padLeft(2, '0')} - ${appointmentEnd.hour}:${appointmentEnd.minute.toString().padLeft(2, '0')} (${appointment.sessionType})');
        return true;
      }
    }

    return false;
  }

  // Check if there are enough consecutive free slots for a full session
  bool _hasEnoughConsecutiveSlots(
      DateTime startTime, List<SlotInfo> allSlots, List<Appointment> appointments) {
    // For 15-minute sessions, always allow (single slot)
    if (widget.durationMinutes == 15) return true;

    final increment = widget.durationMinutes >= 60 ? 30 : 15;
    final slotsNeeded = (widget.durationMinutes / increment).ceil();

    print('🔍 Checking ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - needs $slotsNeeded consecutive slots (${widget.durationMinutes} min)');

    // Check if all required consecutive slots are free
    for (int i = 0; i < slotsNeeded; i++) {
      final checkTime = startTime.add(Duration(minutes: i * increment));

      // Check directly if this time is booked
      final isBooked = _isTimeBooked(checkTime, appointments);

      // Also check if the slot exists in the generated slots
      final slotAtTime = allSlots.any((s) => s.time.isAtSameMomentAs(checkTime));

      print('  - ${checkTime.hour}:${checkTime.minute.toString().padLeft(2, '0')}: booked=$isBooked, exists=$slotAtTime');

      // If slot is booked OR doesn't exist, we can't book a full session
      if (isBooked || !slotAtTime) {
        print('  ❌ Slot ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} blocked - not enough consecutive slots');
        return false;
      }
    }

    print('  ✅ Slot ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} available - has enough consecutive slots');
    return true;
  }

  // Генерирует все возможные слоты для конкретного дня
  List<SlotInfo> _getSlotsForDay(
      DateTime day, List<TimeSlot> timeSlots, List<Appointment> appointments) {
    final slots = <SlotInfo>[];
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    print('📅 Getting slots for day: ${day.day}.${day.month}.${day.year}');
    print('🔍 Session type: ${widget.sessionType}, Duration: ${widget.durationMinutes} min');

    // Фильтруем слоты по дню (session type и duration уже отфильтрованы в провайдере)
    final daySlots = timeSlots.where((slot) {
      final slotStart = slot.startTime;  // Already local time
      final slotEnd = slot.endTime;      // Already local time

      // Проверяем пересечение с целевым днем
      final hasIntersection =
          slotStart.isBefore(dayEnd) && slotEnd.isAfter(dayStart);

      return hasIntersection && slot.isAvailable;
    }).toList();

    print('📊 Found ${daySlots.length} time slot ranges for this day');
    if (timeSlots.isNotEmpty && daySlots.isEmpty) {
      print('⚠️ No slots matched filters. All slots info:');
      for (final slot in timeSlots) {
        print('  Slot: ${slot.sessionType}, duration: ${slot.durationMinutes}min, required: ${widget.durationMinutes}min');
      }
    }

    for (final slot in daySlots) {
      final rangeStart = slot.startTime;  // Already local time
      final rangeEnd = slot.endTime;      // Already local time

      print('⏰ Processing slot range: ${rangeStart.hour}:${rangeStart.minute.toString().padLeft(2, '0')} - ${rangeEnd.hour}:${rangeEnd.minute.toString().padLeft(2, '0')} (duration: ${slot.durationMinutes}min)');

      // Adjust range to only the target day
      DateTime actualStart = rangeStart.isAfter(dayStart) ? rangeStart : dayStart;
      final actualEnd = rangeEnd.isBefore(dayEnd) ? rangeEnd : dayEnd;

      // Round to nearest business hour if starting from day start
      if (actualStart.isAtSameMomentAs(dayStart)) {
        actualStart = DateTime(day.year, day.month, day.day, 8, 0, 0);
      }

      print('  📍 Actual range after adjustment: ${actualStart.toString()} - ${actualEnd.toString()}');

      // Generate all possible slots within this range for the specific day
      DateTime currentSlot = DateTime.fromMillisecondsSinceEpoch(actualStart.millisecondsSinceEpoch);

      // Use increment (30 or 15 min) instead of selectedDuration to generate all slots
      final increment = widget.durationMinutes >= 60 ? 30 : 15;

      // Генерируем слоты с шагом increment
      while (currentSlot.millisecondsSinceEpoch + increment * 60000 <= actualEnd.millisecondsSinceEpoch) {
        final slotEnd = currentSlot.add(Duration(minutes: increment));

        print('    🕐 Checking slot: ${currentSlot.hour}:${currentSlot.minute.toString().padLeft(2, '0')} - ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, '0')}');

        // Only include slots during business hours (8:00-20:00) and on the target day
        if (currentSlot.hour >= 8 &&
            slotEnd.hour <= 20 &&
            currentSlot.year == day.year &&
            currentSlot.month == day.month &&
            currentSlot.day == day.day) {

          final isBooked = _isTimeBooked(currentSlot, appointments);
          final isSelected = _selectedTime != null &&
              _selectedTime!.isAtSameMomentAs(currentSlot);

          print('      ✅ Adding slot: ${currentSlot.hour}:${currentSlot.minute.toString().padLeft(2, '0')} (available: ${!isBooked})');

          slots.add(SlotInfo(
            time: DateTime.fromMillisecondsSinceEpoch(currentSlot.millisecondsSinceEpoch),
            isAvailable: !isBooked,
            isSelected: isSelected,
          ));
        } else {
          print('      ⏭️ Skipping slot (outside business hours or wrong day)');
        }

        // Move to next increment
        currentSlot = currentSlot.add(Duration(minutes: increment));
      }
    }

    // Sort slots first
    slots.sort((a, b) => a.time.compareTo(b.time));

    // For 60/90 min sessions, mark slots as unavailable if they don't have enough consecutive free slots
    if (widget.durationMinutes >= 60) {
      for (final slot in slots) {
        if (slot.isAvailable) {
          final hasEnough = _hasEnoughConsecutiveSlots(slot.time, slots, appointments);
          if (!hasEnough) {
            // Create a new SlotInfo with updated availability
            final index = slots.indexOf(slot);
            slots[index] = SlotInfo(
              time: slot.time,
              isAvailable: false,
              isSelected: slot.isSelected,
            );
          }
        }
      }
    }

    print('✅ Generated ${slots.length} bookable slots for ${day.day}.${day.month}');
    if (slots.isNotEmpty) {
      print('  First slot: ${slots.first.time.hour}:${slots.first.time.minute.toString().padLeft(2, '0')}');
      print('  Last slot: ${slots.last.time.hour}:${slots.last.time.minute.toString().padLeft(2, '0')}');
      final availableCount = slots.where((s) => s.isAvailable).length;
      print('  Available slots: $availableCount');
    }
    return slots;
  }

  void _autoSelectFirstAvailableDate(
      List<TimeSlot> timeSlots, List<Appointment> appointments) {
    if (_initialized || timeSlots.isEmpty) return;

    // Находим первый день с доступными слотами
    final weekDays = _getWeekDays();
    for (final day in weekDays) {
      final slotsForDay = _getSlotsForDay(day, timeSlots, appointments);
      final hasAvailableSlots =
          slotsForDay.any((slot) => slot.isAvailable);
      if (hasAvailableSlots) {
        setState(() {
          _selectedDate = day;
          _initialized = true;
        });
        return;
      }
    }

    // Если не нашли, переходим к следующей неделе
    if (!_initialized && timeSlots.isNotEmpty) {
      _nextWeek();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeSlotsAsync = ref.watch(timeSlotsProvider(_queryParams));
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оберіть зручний час'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientSoft,
        ),
        child: timeSlotsAsync.when(
          data: (timeSlots) {
            return appointmentsAsync.when(
              data: (appointments) {
                // Автоматически выбираем первый доступный день
                _autoSelectFirstAvailableDate(timeSlots, appointments);

                final weekDays = _getWeekDays();

                return Column(
                  children: [
                    // Week navigation
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _previousWeek,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            _formatWeekRange(weekDays.first, weekDays.last),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: _nextWeek,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                    // Days row
                    Container(
                      height: 80,
                      color: Colors.white,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: weekDays.length,
                        itemBuilder: (context, index) {
                          final day = weekDays[index];
                          final slotsForDay =
                              _getSlotsForDay(day, timeSlots, appointments);
                          final hasSlots = slotsForDay.any((s) => s.isAvailable);
                          final isSelected = _selectedDate != null &&
                              _selectedDate!.year == day.year &&
                              _selectedDate!.month == day.month &&
                              _selectedDate!.day == day.day;

                          final isToday = DateTime.now().year == day.year &&
                              DateTime.now().month == day.month &&
                              DateTime.now().day == day.day;
                          final isPast = day.isBefore(
                              DateTime(DateTime.now().year,
                                  DateTime.now().month, DateTime.now().day));

                          return GestureDetector(
                            onTap: (hasSlots && !isPast && !isToday)
                                ? () {
                                    setState(() {
                                      _selectedDate = day;
                                      _selectedTime = null;
                                    });
                                  }
                                : null,
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (hasSlots && !isPast && !isToday
                                        ? Colors.white
                                        : Colors.grey[200]),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (hasSlots && !isPast && !isToday
                                          ? AppColors.primary
                                              .withValues(alpha: 0.3)
                                          : Colors.grey[300]!),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getDayName(day.weekday),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : (hasSlots && !isPast && !isToday
                                              ? Colors.black54
                                              : Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : (hasSlots && !isPast && !isToday
                                              ? Colors.black
                                              : Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getMonthName(day.month),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? Colors.white
                                          : (hasSlots && !isPast && !isToday
                                              ? Colors.black54
                                              : Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // White spacing between dates and time slots
                    Container(
                      height: 10,
                      color: Colors.white,
                    ),
                    // Time slots
                    Expanded(
                      child: _selectedDate == null
                          ? Center(
                              child: Text(
                                'Оберіть дату вище',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                          : _buildTimeSlotsList(_getSlotsForDay(
                              _selectedDate!, timeSlots, appointments)),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(
                child: Text('Помилка завантаження записів'),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Помилка завантаження слотів',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _selectedTime != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingFormScreen(
                          selectedTime: _selectedTime!,
                          sessionType: widget.sessionType,
                          durationMinutes: widget.durationMinutes,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Продовжити'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTimeSlotsList(List<SlotInfo> slots) {
    if (slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'На цю дату немає доступних слотів',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final timeString =
            '${slot.time.hour.toString().padLeft(2, '0')}:${slot.time.minute.toString().padLeft(2, '0')}';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: slot.isAvailable
                ? () {
                    setState(() {
                      _selectedTime = slot.time;
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: slot.isSelected
                    ? AppColors.primary
                    : (slot.isAvailable ? Colors.white : Colors.grey[200]),
                border: Border.all(
                  color: slot.isSelected
                      ? AppColors.primary
                      : (slot.isAvailable
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.grey[300]!),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: slot.isSelected
                          ? Colors.white
                          : (slot.isAvailable ? Colors.black : Colors.grey),
                    ),
                  ),
                  if (!slot.isAvailable)
                    const Text(
                      'Зайнято',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatWeekRange(DateTime start, DateTime end) {
    return '${start.day} ${_getMonthName(start.month)} - ${end.day} ${_getMonthName(end.month)} ${end.year}';
  }

  String _getDayName(int weekday) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Січ',
      'Лют',
      'Бер',
      'Кві',
      'Тра',
      'Чер',
      'Лип',
      'Сер',
      'Вер',
      'Жов',
      'Лис',
      'Гру'
    ];
    return months[month - 1];
  }
}
