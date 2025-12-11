import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/time_slot.dart';
import '../../models/appointment.dart';
import '../../services/supabase_service.dart';
import 'booking_confirmation_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final DateTime selectedTime;
  final String sessionType;
  final int durationMinutes;

  const BookingFormScreen({
    super.key,
    required this.selectedTime,
    required this.sessionType,
    required this.durationMinutes,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  TimeSlot? _matchingSlot;

  @override
  void initState() {
    super.initState();
    _findMatchingSlot();
  }

  Future<void> _findMatchingSlot() async {
    try {
      // Находим слот, который содержит выбранное время
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

      final slots = await SupabaseService.getAvailableTimeSlots(
        startDate: startOfTomorrow,
        sessionType: widget.sessionType,
      );

      final selectedEnd = widget.selectedTime.add(Duration(minutes: widget.durationMinutes));

      for (final slot in slots) {
        final slotStart = slot.startTime.toLocal();
        final slotEnd = slot.endTime.toLocal();

        // Проверяем, содержится ли наш выбранный период внутри этого слота
        if (widget.selectedTime.isAfter(slotStart) || widget.selectedTime.isAtSameMomentAs(slotStart)) {
          if (selectedEnd.isBefore(slotEnd) || selectedEnd.isAtSameMomentAs(slotEnd)) {
            setState(() {
              _matchingSlot = slot;
            });
            break;
          }
        }
      }
    } catch (e) {
      print('Error finding matching slot: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Email is optional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Введіть коректний email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Введіть коректний номер телефону';
    }
    return null;
  }

  // Convert app session type to database session type
  String _convertSessionTypeForDB(String appSessionType) {
    switch (appSessionType) {
      case '15min':
        return 'consultation_15';
      case '60min':
        return 'session_60';
      case '90min':
        return 'session_90';
      default:
        return appSessionType;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_matchingSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не вдалося знайти відповідний слот'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check that at least email or phone is provided
    if (_emailController.text.isEmpty && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, вкажіть email або телефон'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dbSessionType = _convertSessionTypeForDB(widget.sessionType);
      print('Converting session type: ${widget.sessionType} -> $dbSessionType');

      // Calculate exact appointment times
      final appointmentStart = widget.selectedTime;
      final appointmentEnd = appointmentStart.add(Duration(minutes: widget.durationMinutes));

      print('📅 Creating appointment: ${appointmentStart.toString()} - ${appointmentEnd.toString()}');

      final appointment = Appointment(
        timeSlotId: _matchingSlot!.id,
        clientName: _nameController.text.trim(),
        clientEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        clientPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        sessionType: dbSessionType,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        appointmentStartTime: appointmentStart,
        appointmentEndTime: appointmentEnd,
      );

      final createdAppointment =
          await SupabaseService.createAppointment(appointment);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            appointment: createdAppointment,
            selectedTime: widget.selectedTime,
            durationMinutes: widget.durationMinutes,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка при створенні запису: $e'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeString =
        '${widget.selectedTime.hour.toString().padLeft(2, '0')}:${widget.selectedTime.minute.toString().padLeft(2, '0')}';
    final dateString =
        '${widget.selectedTime.day}.${widget.selectedTime.month}.${widget.selectedTime.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваші дані'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientSoft,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dateString,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeString,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.durationMinutes} хвилин',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Контактні дані',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Ім'я *",
                        hintText: "Введіть ваше ім'я",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Будь ласка, введіть ім'я";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'example@email.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        hintText: '+380 XX XXX XX XX',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Примітки (необов\'язково)',
                        hintText: 'Додаткова інформація або запитання',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '* Вкажіть email або телефон (або обидва)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Підтвердити запис'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
