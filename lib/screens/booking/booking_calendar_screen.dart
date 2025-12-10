import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/colors.dart';
import '../../models/time_slot.dart';
import '../../models/appointment.dart';
import '../../services/supabase_service.dart';
import 'booking_form_screen.dart';

// Provider для загрузки слотов
final timeSlotsProvider = FutureProvider.family<List<TimeSlot>, String>(
  (ref, sessionType) async {
    // Start from tomorrow like in React version
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    print('🔍 Fetching slots for session type: $sessionType');
    print('📅 Fetching slots from date: $startOfTomorrow');

    final slots = await SupabaseService.getAvailableTimeSlots(
      startDate: startOfTomorrow,
      sessionType: sessionType,
    );

    print('📊 Total slots fetched: ${slots.length}');
    if (slots.isNotEmpty) {
      print('First slot UTC: ${slots.first.startTime}');
      print('First slot Local: ${slots.first.startTime.toLocal()}');
      print('Slot session_type: ${slots.first.sessionType}');
    }

    return slots;
  },
);

// Provider для загрузки всех подтвержденных записей
final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  print('🔍 Fetching appointments...');
  final appointments = await SupabaseService.getAppointments();
  print('📊 Total appointments: ${appointments.length}');
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

  @override
  void initState() {
    super.initState();
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
  bool _isTimeBooked(
      DateTime slotTime, List<Appointment> appointments) {
    final slotEnd = slotTime.add(Duration(minutes: widget.durationMinutes));

    for (final appointment in appointments) {
      if (appointment.timeSlot == null) continue;

      final appointmentStart = appointment.timeSlot!.startTime;  // Already local time

      // Определяем длительность по типу сессии
      int appointmentDuration = 60;
      if (appointment.sessionType == 'consultation_15') {
        appointmentDuration = 15;
      } else if (appointment.sessionType == 'session_60') {
        appointmentDuration = 60;
      } else if (appointment.sessionType == 'session_90') {
        appointmentDuration = 90;
      }

      final appointmentEnd =
          appointmentStart.add(Duration(minutes: appointmentDuration));
      // Добавляем буфер 15 минут после записи
      final appointmentEndWithBuffer =
          appointmentEnd.add(const Duration(minutes: 15));

      // Проверяем пересечение
      final hasOverlap =
          slotTime.isBefore(appointmentEndWithBuffer) &&
          slotEnd.isAfter(appointmentStart);

      if (hasOverlap) {
        return true;
      }
    }

    return false;
  }

  // Генерирует все возможные слоты для конкретного дня
  List<SlotInfo> _getSlotsForDay(
      DateTime day, List<TimeSlot> timeSlots, List<Appointment> appointments) {
    final slots = <SlotInfo>[];
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    print('📅 Getting slots for day: ${day.day}.${day.month}.${day.year}');
    print('🔍 Session type: ${widget.sessionType}, Duration: ${widget.durationMinutes} min');

    // Фильтруем слоты по типу сессии и дню
    final daySlots = timeSlots.where((slot) {
      final slotStart = slot.startTime;  // Already local time
      final slotEnd = slot.endTime;      // Already local time
      final isCorrectSessionType = slot.sessionType == widget.sessionType;

      // Check if slot duration is sufficient for the selected session duration
      final hasSufficientDuration = slot.durationMinutes >= widget.durationMinutes;

      // Проверяем пересечение с целевым днем
      final hasIntersection =
          slotStart.isBefore(dayEnd) && slotEnd.isAfter(dayStart);

      return hasIntersection && slot.isAvailable && isCorrectSessionType && hasSufficientDuration;
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

      // Генерируем слоты
      while (currentSlot.millisecondsSinceEpoch + widget.durationMinutes * 60000 <= actualEnd.millisecondsSinceEpoch) {
        final slotEnd = currentSlot.add(Duration(minutes: widget.durationMinutes));

        print('    🕐 Checking slot: ${currentSlot.hour}:${currentSlot.minute.toString().padLeft(2, '0')} - ${slotEnd.hour}:${slotEnd.minute.toString().padLeft(2, '0')}');

        // Only include slots during business hours (8:00-20:00) and on the target day
        if (currentSlot.hour >= 8 &&
            slotEnd.hour <= 20 &&
            currentSlot.year == day.year &&
            currentSlot.month == day.month &&
            currentSlot.day == day.day) {

          // Additional check: if slotEnd is exactly 20:00 or before, it's valid
          // But if hours are same (20) and minutes > 0, it's invalid
          final isEndTimeValid = slotEnd.hour < 20 ||
                                  (slotEnd.hour == 20 && slotEnd.minute == 0);

          if (isEndTimeValid) {
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
            print('      ⏭️ Skipping slot (end time after 20:00)');
          }
        } else {
          print('      ⏭️ Skipping slot (outside business hours or wrong day)');
        }

        // Move to next increment based on session duration
        final increment = widget.durationMinutes >= 60 ? 30 : 15;
        currentSlot = currentSlot.add(Duration(minutes: increment));
      }
    }

    slots.sort((a, b) => a.time.compareTo(b.time));
    print('✅ Generated ${slots.length} bookable slots for ${day.day}.${day.month}');
    if (slots.isNotEmpty) {
      print('  First slot: ${slots.first.time.hour}:${slots.first.time.minute.toString().padLeft(2, '0')}');
      print('  Last slot: ${slots.last.time.hour}:${slots.last.time.minute.toString().padLeft(2, '0')}');
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
    final timeSlotsAsync = ref.watch(timeSlotsProvider(widget.sessionType));
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
