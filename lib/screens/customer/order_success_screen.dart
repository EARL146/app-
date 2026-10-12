import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFBF0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.check_circle, size: 72, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              const Text(
                'Order placed successfully',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Reference: $orderId',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              const Text(
                'This demo confirms the UI flow and local cart validation. A real backend must complete the final order creation and payment handling.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/customer-home', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
