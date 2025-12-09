import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/colors.dart';
import '../../models/time_slot.dart';
import '../../services/supabase_service.dart';
import 'booking_form_screen.dart';

// Provider для загрузки слотов
final timeSlotsProvider = FutureProvider.family<List<TimeSlot>, int>(
  (ref, durationMinutes) async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 60));

    return await SupabaseService.getAvailableTimeSlots(
      startDate: now,
      endDate: endDate,
      durationMinutes: durationMinutes,
    );
  },
);

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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeSlot? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final timeSlotsAsync = ref.watch(timeSlotsProvider(widget.durationMinutes));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оберіть дату та час'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientSoft,
        ),
        child: timeSlotsAsync.when(
          data: (timeSlots) => _buildCalendarView(timeSlots),
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
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(timeSlotsProvider(widget.durationMinutes));
                  },
                  child: const Text('Спробувати ще раз'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _selectedSlot != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingFormScreen(
                          timeSlot: _selectedSlot!,
                          sessionType: widget.sessionType,
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

  Widget _buildCalendarView(List<TimeSlot> timeSlots) {
    // Группируем слоты по датам
    final slotsByDate = <DateTime, List<TimeSlot>>{};
    for (final slot in timeSlots) {
      final date = DateTime(
        slot.startTime.year,
        slot.startTime.month,
        slot.startTime.day,
      );
      slotsByDate.putIfAbsent(date, () => []).add(slot);
    }

    final availableDates = slotsByDate.keys.toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              availableGestures: AvailableGestures.horizontalSwipe,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              enabledDayPredicate: (day) {
                final dateOnly = DateTime(day.year, day.month, day.day);
                return availableDates.any((d) => isSameDay(d, dateOnly));
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedSlot = null;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          if (_selectedDay != null) _buildTimeSlots(slotsByDate),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(Map<DateTime, List<TimeSlot>> slotsByDate) {
    final selectedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );

    final slots = slotsByDate[selectedDate] ?? [];

    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'На цю дату немає доступних слотів',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    // Сортируем слоты по времени
    slots.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Доступний час',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              final isSelected = _selectedSlot?.id == slot.id;
              final timeString =
                  '${slot.startTime.hour.toString().padLeft(2, '0')}:${slot.startTime.minute.toString().padLeft(2, '0')}';

              return ChoiceChip(
                label: Text(timeString),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSlot = selected ? slot : null;
                  });
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
