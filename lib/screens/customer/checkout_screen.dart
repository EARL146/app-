import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/food_image.dart';
import '../../widgets/customer_account_prompt.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _profilePrefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profilePrefilled) return;
    final auth = context.read<AuthService>();
    _nameController.text = auth.currentUserName ?? '';
    _addressController.text = auth.currentUserAddress ?? '';
    _phoneController.text = auth.currentUserPhone ?? '';
    _profilePrefilled = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Cart & checkout')),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(
              child: Text('Your cart is empty. Add items before checkout.'),
            );
          }
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                    children: [
                      _AddressCard(
                        nameController: _nameController,
                        addressController: _addressController,
                        phoneController: _phoneController,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your feast',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${cart.items.length} items',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      ...cart.items.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 42,
                                height: 42,
                                child: FoodImage(
                                  imageUrl: item.productImage,
                                  borderRadius: 11,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.quantity} × ₱${item.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₱${item.subtotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      const _SectionTitle(title: 'Payment method'),
                      const SizedBox(height: 7),
                      _PaymentOption(
                        title: 'Cash on Delivery (COD)',
                        subtitle: 'Pay when your order arrives',
                        icon: Icons.payments_outlined,
                        selected: _paymentMethod == 'Cash on Delivery',
                        onTap: () =>
                            setState(() => _paymentMethod = 'Cash on Delivery'),
                      ),
                      _PaymentOption(
                        title: 'GCash e-Wallet',
                        subtitle:
                            'Unavailable: no payment provider is configured',
                        icon: Icons.account_balance_wallet_outlined,
                        selected: _paymentMethod == 'GCash e-Wallet',
                        onTap: _showOnlinePaymentUnavailable,
                      ),
                      _PaymentOption(
                        title: 'Maya wallet',
                        subtitle:
                            'Unavailable: sandbox configuration is pending',
                        icon: Icons.account_balance_wallet_outlined,
                        selected: false,
                        onTap: _showOnlinePaymentUnavailable,
                      ),
                      _PaymentOption(
                        title: 'Credit / Debit',
                        subtitle:
                            'Unavailable: no payment provider is configured',
                        icon: Icons.credit_card_outlined,
                        selected: _paymentMethod == 'Credit / Debit',
                        onTap: _showOnlinePaymentUnavailable,
                      ),
                      const SizedBox(height: 12),
                      const _SectionTitle(title: 'Order notes'),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Add delivery instructions (optional)',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TotalsCard(
                        subtotal: cart.subtotal,
                        delivery: cart.deliveryFee,
                        tax: cart.tax,
                        total: cart.total,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.brandOrange,
                              size: 16,
                            ),
                            SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                'Orders require the BurgerBites server. Cash on delivery is the only available method; no online payment is processed.',
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: ElevatedButton(
                        onPressed: cart.isSubmitting
                            ? null
                            : () => _submit(context, cart),
                        child: cart.isSubmitting
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Submit COD order',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₱${cart.total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context, CartProvider cart) async {
    if (!await requireCustomerAccount(context, action: 'place this order')) {
      return;
    }
    if (!context.mounted) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final orderId = await cart.submitOrder(
      customerName: _nameController.text,
      deliveryAddress: _addressController.text,
      phone: _phoneController.text,
      paymentMethod: _paymentMethod == 'Cash on Delivery'
          ? 'cod'
          : 'unavailable',
      notes: _notesController.text,
    );
    if (!context.mounted) return;
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
  }

  void _showOnlinePaymentUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Online payment is not configured. Select cash on delivery.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.nameController,
    required this.addressController,
    required this.phoneController,
  });

  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.brandOrange,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'DELIVERY TO HOME',
                  style: TextStyle(
                    color: AppColors.brandOrange,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => value == null || value.trim().length < 2
                ? 'Enter your name.'
                : null,
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Delivery address',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            validator: (value) => value == null || value.trim().length < 8
                ? 'Enter a complete delivery address.'
                : null,
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) =>
                value == null || value.replaceAll(RegExp(r'\D'), '').length < 10
                ? 'Enter a valid mobile number.'
                : null,
          ),
          const SizedBox(height: 4),
          const Text(
            'Delivery estimate is confirmed by the restaurant after order review.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
  );
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.brandOrange : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.brandOrange, size: 17),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? AppColors.brandOrange : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.subtotal,
    required this.delivery,
    required this.tax,
    required this.total,
  });
  final double subtotal;
  final double delivery;
  final double tax;
  final double total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        _line('Subtotal', subtotal),
        const SizedBox(height: 7),
        _line('Delivery fee', delivery),
        const SizedBox(height: 7),
        _line('Tax (12%)', tax),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 9),
          child: Divider(height: 1),
        ),
        _line('Total amount', total, strong: true),
      ],
    ),
  );

  Widget _line(String label, double value, {bool strong = false}) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: strong ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: strong ? 12 : 10,
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
      Text(
        '₱${value.toStringAsFixed(0)}',
        style: TextStyle(
          color: strong ? AppColors.brandOrange : AppColors.textPrimary,
          fontSize: strong ? 16 : 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}
