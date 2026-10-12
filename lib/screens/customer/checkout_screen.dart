import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'John Doe');
  final _addressController = TextEditingController(text: '123 Main Street, Mandaue');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(backgroundColor: AppColors.pageBackground, title: const Text('Checkout')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(child: Text('Your cart is empty. Add items before checkout.'));
          }

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        const Text(
                          'Delivery details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          validator: (value) => (value == null || value.trim().length < 2)
                              ? 'Enter a valid customer name.'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Customer name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          validator: (value) => (value == null || value.trim().length < 8)
                              ? 'Enter a valid delivery address.'
                              : null,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Delivery address',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Order notes (optional)',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _summaryRow('Subtotal', '₱${cart.subtotal.toStringAsFixed(0)}'),
                              const SizedBox(height: 8),
                              _summaryRow('Delivery', '₱${cart.deliveryFee.toStringAsFixed(0)}'),
                              const SizedBox(height: 8),
                              _summaryRow('Tax', '₱${cart.tax.toStringAsFixed(0)}'),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),
                              _summaryRow(
                                'Total',
                                '₱${cart.total.toStringAsFixed(0)}',
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: cart.isSubmitting
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;

                              final orderId = await cart.submitOrder(
                                customerName: _nameController.text,
                                deliveryAddress: _addressController.text,
                              );

                              if (!mounted) return;

                              if (orderId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(cart.errorMessage ?? 'Unable to place order.'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                                return;
                              }

                              Navigator.of(context)
                                  .pushReplacementNamed('/order-success', arguments: orderId);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: cart.isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Place order'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _summaryRow(String label, String value, {bool isTotal = false}) {
  return Row(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: isTotal ? 18 : 14,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}
