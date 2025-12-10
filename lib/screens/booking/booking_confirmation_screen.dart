import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/appointment.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Appointment appointment;
  final DateTime selectedTime;
  final int durationMinutes;

  const BookingConfirmationScreen({
    super.key,
    required this.appointment,
    required this.selectedTime,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final timeString =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    final dateString =
        '${selectedTime.day}.${selectedTime.month}.${selectedTime.year}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientSoft,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Запис підтверджено!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ваш запис успішно створено',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              context,
                              icon: Icons.person,
                              label: "Ім'я",
                              value: appointment.clientName,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              context,
                              icon: Icons.calendar_today,
                              label: 'Дата',
                              value: dateString,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              context,
                              icon: Icons.access_time,
                              label: 'Час',
                              value: timeString,
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              context,
                              icon: Icons.timer,
                              label: 'Тривалість',
                              value: '$durationMinutes хвилин',
                            ),
                            if (appointment.clientEmail != null) ...[
                              const Divider(height: 24),
                              _buildInfoRow(
                                context,
                                icon: Icons.email,
                                label: 'Email',
                                value: appointment.clientEmail!,
                              ),
                            ],
                            if (appointment.clientPhone != null) ...[
                              const Divider(height: 24),
                              _buildInfoRow(
                                context,
                                icon: Icons.phone,
                                label: 'Телефон',
                                value: appointment.clientPhone!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Посилання на відеозустріч буде надіслано за 24 години до консультації',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Повернутися на головну'),
                      ),
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

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
