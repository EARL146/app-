import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_translations.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_orders_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_brand_button.dart';
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
  bool _redeemRewards = false;

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
      appBar: AppBar(title: Text('Cart & checkout'.tr)),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          final rewardPoints = context
              .watch<AuthService>()
              .currentUserRewardPoints;
          final rewardSavings = _redeemRewards && rewardPoints >= 2500
              ? _estimatedRewardSavings(cart)
              : 0.0;
          final estimatedSubtotal = (cart.subtotal - rewardSavings)
              .clamp(0, double.infinity)
              .toDouble();
          final estimatedTax = estimatedSubtotal * 0.12;
          final estimatedTotal =
              estimatedSubtotal + cart.deliveryFee + estimatedTax;
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
                        name: _nameController.text,
                        address: _addressController.text,
                        phone: _phoneController.text,
                        onEdit: () async {
                          await Navigator.of(context).pushNamed('/settings');
                          if (!context.mounted) return;
                          final auth = context.read<AuthService>();
                          setState(() {
                            _nameController.text = auth.currentUserName ?? '';
                            _addressController.text =
                                auth.currentUserAddress ?? '';
                            _phoneController.text = auth.currentUserPhone ?? '';
                          });
                        },
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
                            style: TextStyle(
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
                                      style: TextStyle(
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
                      if (rewardPoints >= 2500) ...[
                        const SizedBox(height: 8),
                        Material(
                          color: AppColors.surface,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.border),
                          ),
                          child: SwitchListTile.adaptive(
                            value: _redeemRewards,
                            activeThumbColor: AppColors.brandOrange,
                            title: const Text(
                              'Redeem 2,500 points',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Text(
                              '80% off up to 5 products · save about ₱${_estimatedRewardSavings(cart).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onChanged: (value) =>
                                setState(() => _redeemRewards = value),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const _SectionTitle(title: 'Order notes'),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          hintText: 'Add delivery instructions (optional)',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TotalsCard(
                        subtotal: estimatedSubtotal,
                        delivery: cart.deliveryFee,
                        tax: estimatedTax,
                        total: estimatedTotal,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
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
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: AnimatedPressScale(
                      enabled: !cart.isSubmitting,
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
                                    AnimatedValueText(
                                      '₱${estimatedTotal.toStringAsFixed(0)}',
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
      redeemRewards: _redeemRewards,
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
    await context.read<AuthService>().refreshProfile();
    if (!context.mounted) return;
    await context.read<CustomerOrdersProvider>().loadOrders(force: true);
    if (!context.mounted) return;
    Navigator.of(context)
        .pushReplacementNamed('/order-success', arguments: orderId);
  }

  double _estimatedRewardSavings(CartProvider cart) {
    var remaining = 5;
    var savings = 0.0;
    for (final item in cart.items) {
      if (remaining <= 0) break;
      final discountedUnits = item.quantity < remaining
          ? item.quantity
          : remaining;
      savings += item.price * 0.8 * discountedUnits;
      remaining -= discountedUnits;
    }
    return savings;
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
    required this.name,
    required this.address,
    required this.phone,
    required this.onEdit,
  });

  final String name;
  final String address;
  final String phone;
  final VoidCallback onEdit;

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
              Icon(
                Icons.location_on_rounded,
                color: AppColors.brandOrange,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'DELIVERY DETAILS',
                  style: TextStyle(
                    color: AppColors.brandOrange,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
            ],
          ),
          _DeliveryDetail(
            icon: Icons.person_outline_rounded,
            value: name.isEmpty ? 'Add your name in account settings' : name,
          ),
          _DeliveryDetail(
            icon: Icons.home_outlined,
            value: address.isEmpty
                ? 'Add a delivery address in account settings'
                : address,
          ),
          _DeliveryDetail(
            icon: Icons.phone_outlined,
            value: phone.isEmpty
                ? 'Add a phone number in account settings'
                : phone,
          ),
          const SizedBox(height: 4),
          Text(
            'Delivery estimate is confirmed by the restaurant after order review.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetail extends StatelessWidget {
  const _DeliveryDetail({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11))),
      ],
    ),
  );
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
    return AnimatedPressScale(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brandOrange : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brandOrange.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
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
                      style: TextStyle(
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
                color: selected
                    ? AppColors.brandOrange
                    : AppColors.textSecondary,
              ),
            ],
          ),
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
