import 'package:flutter/material.dart';

import '../constants/admin_form_styles.dart';

class AdminSaleScheduleSummary extends StatelessWidget {
  const AdminSaleScheduleSummary({
    super.key,
    required this.startsAt,
    required this.endsAt,
  });

  final DateTime? startsAt;
  final DateTime? endsAt;

  String _display(DateTime? value) =>
      value == null ? 'Not set' : value.toLocal().toString().substring(0, 16);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminFormStyles.surfaceTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminFormStyles.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AdminFormStyles.mutedText,
            size: 17,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sale is off · saved schedule',
                  style: TextStyle(
                    color: AdminFormStyles.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Starts: ${_display(startsAt)}',
                  style: const TextStyle(
                    color: AdminFormStyles.mutedText,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Expires: ${_display(endsAt)}',
                  style: const TextStyle(
                    color: AdminFormStyles.mutedText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
