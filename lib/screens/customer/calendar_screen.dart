import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Calendar & milestones')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(17, 4, 17, 22),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ACCOUNT FAVORITES · COMPOSTELA HUB',
              style: TextStyle(
                color: AppColors.brandOrange,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'Kalendaryo ug mga Petsa',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your BurgerBites dates and upcoming menu moments.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: AppColors.brandOrange,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BurgerBites account calendar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Selected date',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                CalendarDatePicker(
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2032),
                  initialDate: _selectedDate,
                  currentDate: DateTime.now(),
                  onDateChanged: (value) =>
                      setState(() => _selectedDate = value),
                ),
                const Row(
                  children: [
                    Icon(Icons.circle, color: AppColors.brandOrange, size: 7),
                    SizedBox(width: 4),
                    Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 11),
                    Icon(Icons.circle, color: AppColors.warning, size: 7),
                    SizedBox(width: 4),
                    Text(
                      'Sample milestone',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 125,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D1D16),
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 145,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.asset(
                      'assets/products/smash_burger.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2D1D16),
                          const Color(0xFF2D1D16).withValues(alpha: .94),
                          Colors.transparent,
                        ],
                        stops: const [0, .58, 1],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 14,
                  top: 13,
                  child: Text(
                    'COMPOSTELA BURGER CLUB',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                ),
                const Positioned(
                  left: 14,
                  top: 39,
                  child: SizedBox(
                    width: 185,
                    child: Text(
                      'Lab-as ug init nga mga burger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 13,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/menu'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 13),
                    label: const Text(
                      'Browse menu',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Upcoming moments',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                _formatMonth(_selectedDate),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const _MilestoneTile(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Account created',
            description: 'Welcome to the BurgerBites app preview.',
            tag: 'SAMPLE',
          ),
          const _MilestoneTile(
            icon: Icons.local_offer_outlined,
            title: 'Special voucher day',
            description: 'A sample reminder for your next burger treat.',
            tag: 'TODAY',
          ),
          const _MilestoneTile(
            icon: Icons.celebration_outlined,
            title: 'Monthly anniversary',
            description: 'Celebrate with a fresh favorite from the menu.',
            tag: 'COMING UP',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.brandOrange,
                  size: 15,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Milestones and reminders are sample content; no account calendar is connected.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/menu'),
              icon: const Icon(Icons.delivery_dining_rounded, size: 17),
              label: const Text('Schedule a burger delivery'),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/order-history'),
            icon: const Icon(Icons.receipt_long_rounded, size: 16),
            label: const Text('View order history'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
  String _formatMonth(DateTime date) =>
      '${_monthName(date.month)} ${date.year}';

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
  });
  final IconData icon;
  final String title;
  final String description;
  final String tag;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brandOrange, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              color: AppColors.brandOrange,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}
