import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'booking_calendar_screen.dart';

class BookingDurationScreen extends StatelessWidget {
  const BookingDurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оберіть тривалість сесії'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _buildDurationCard(
                    context,
                    duration: 15,
                    title: 'Безкоштовна консультація',
                    subtitle: '15 хвилин',
                    price: 'Безкоштовно',
                    description:
                        'Познайомимося та обговоримо ваші потреби. Допоможе зрозуміти, чи підходить вам мій підхід.',
                    icon: Icons.phone,
                    sessionType: '15min',
                  ),
                  const SizedBox(height: 16),
                  _buildDurationCard(
                    context,
                    duration: 60,
                    title: 'Індивідуальна сесія',
                    subtitle: '60 хвилин',
                    price: '1 500 ₴',
                    description:
                        'Повноцінна психологічна консультація з PDF-конспектом після сесії.',
                    icon: Icons.person,
                    sessionType: '60min',
                  ),
                  const SizedBox(height: 16),
                  _buildDurationCard(
                    context,
                    duration: 90,
                    title: 'Розширена сесія',
                    subtitle: '90 хвилин',
                    price: '2 000 ₴',
                    description:
                        'Поглиблена робота з більше часу для детального опрацювання запиту.',
                    icon: Icons.timer,
                    sessionType: '90min',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationCard(
    BuildContext context, {
    required int duration,
    required String title,
    required String subtitle,
    required String price,
    required String description,
    required IconData icon,
    required String sessionType,
  }) {
    final isFree = duration == 15;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFree
            ? BorderSide(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingCalendarScreen(
                durationMinutes: duration,
                sessionType: sessionType,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.mutedForeground,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    price,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingCalendarScreen(
                          durationMinutes: duration,
                          sessionType: sessionType,
                        ),
                      ),
                    );
                  },
                  child: const Text('Обрати час'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
