import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../l10n/app_translations.dart';
import '../../models/order_model.dart';
import '../../providers/customer_orders_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_brand_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _requestedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  Future<void> _pickProfilePhoto() async {
    if (!context.read<AuthService>().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to add a profile photo.')),
      );
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final bytes = result.files.first.bytes;
    if (bytes == null || bytes.length > 512 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an image no larger than 512 KB.')),
      );
      return;
    }
    final auth = context.read<AuthService>();
    final saved = await auth.updateProfileImage(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Profile photo saved.'
              : auth.errorMessage ?? 'Unable to save your profile photo.',
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthService>();
    final userId = auth.currentUserId;
    if (!auth.isAuthenticated || userId == null) {
      _requestedUserId = null;
      return;
    }
    if (_requestedUserId == userId) return;
    _requestedUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || context.read<AuthService>().currentUserId != userId) {
        return;
      }
      unawaited(context.read<CustomerOrdersProvider>().loadOrders(force: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final customerOrders = context.watch<CustomerOrdersProvider>();
    final orderCountStatus = _orderCountStatus(auth, customerOrders);
    final orderCount =
        orderCountStatus.value ?? customerOrders.orders.length.toString();
    final deliveryCount =
        orderCountStatus.value ??
        customerOrders.orders
            .where((order) => order.status == OrderStatus.delivered)
            .length
            .toString();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Profile'.tr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/settings'),
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: AppColors.warmSurfaceGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D1E130C),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Tooltip(
                          message: 'Change profile photo',
                          child: InkWell(
                            onTap: _pickProfilePhoto,
                            customBorder: const CircleBorder(),
                            child: Stack(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryButtonGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x26FF6422),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: auth.currentUserProfileImage == null
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 31,
                                          color: Colors.white,
                                        )
                                      : Image.memory(
                                          auth.currentUserProfileImage!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 19,
                                    height: 19,
                                    decoration: BoxDecoration(
                                      color: AppColors.darkSurface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.currentUserName ?? 'Customer account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                auth.currentUserEmail ??
                                    'Sign in to load account details',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 5),
                              if (customerOrders.orders.isNotEmpty &&
                                  auth.currentUserAddress?.trim().isNotEmpty ==
                                      true) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 12,
                                      color: AppColors.brandOrange,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        auth.currentUserAddress!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/settings'),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  if (!auth.isAuthenticated && !auth.isInitializing) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sign in to your account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customer and admin accounts can sign in here.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/sign-in'),
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Sign in'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                  ],
                  _RewardsCard(points: auth.currentUserRewardPoints),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.receipt_long_rounded,
                          value: orderCount,
                          label: 'Orders',
                          detail: orderCountStatus.detail,
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.stars_rounded,
                          value: auth.currentUserRewardPoints % 1 == 0
                              ? auth.currentUserRewardPoints.toStringAsFixed(0)
                              : auth.currentUserRewardPoints.toStringAsFixed(1),
                          label: 'Points',
                          detail: '0.5 per item',
                        ),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.delivery_dining_rounded,
                          value: deliveryCount,
                          label: 'Deliveries',
                          detail: orderCountStatus.detail,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _GroupLabel(title: 'PERSONAL & PREFERENCES'),
                  const SizedBox(height: 7),
                  _ProfileTile(
                    title: 'Account settings',
                    subtitle: 'Email, phone and security',
                    icon: Icons.manage_accounts_outlined,
                    route: '/settings',
                  ),
                  _ProfileTile(
                    title: 'Language',
                    subtitle: 'Bisaya (Cebuano)',
                    icon: Icons.language_rounded,
                    route: '/language',
                  ),
                  _ProfileTile(
                    title: 'Theme & appearance',
                    subtitle: 'Choose your app colors',
                    icon: Icons.palette_outlined,
                    route: '/themes',
                  ),
                  _ProfileTile(
                    title: 'Calendar & milestones',
                    subtitle: 'Important dates and reminders',
                    icon: Icons.calendar_month_rounded,
                    route: '/calendar',
                  ),
                  _ProfileTile(
                    title: 'Favorites',
                    subtitle: 'Products you saved',
                    icon: Icons.favorite_border_rounded,
                    route: '/favorites',
                  ),
                  _ProfileTile(
                    title: 'Order history',
                    subtitle: 'View your past orders',
                    icon: Icons.receipt_long_outlined,
                    route: '/order-history',
                  ),
                  const SizedBox(height: 17),
                  const _GroupLabel(title: 'SUPPORT'),
                  const SizedBox(height: 7),
                  _ProfileTile(
                    title: 'Contact BurgerBites',
                    subtitle: 'We are here to help',
                    icon: Icons.support_agent_rounded,
                    route: '/contact',
                  ),
                  _ProfileTile(
                    title: 'About us',
                    subtitle: 'Our story and values',
                    icon: Icons.info_outline_rounded,
                    route: '/about',
                  ),
                  const SizedBox(height: 12),
                  if (auth.isAuthenticated)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text('Log out?'.tr),
                            content: Text(
                              'Are you sure you want to log out?'.tr,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: Text('No'.tr),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Yes, log out'.tr),
                              ),
                            ],
                          ),
                        );
                        if (shouldLogout != true || !context.mounted) return;
                        await context.read<AuthService>().logout();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/customer-home',
                          (route) => false,
                          arguments: true,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 17),
                      label: Text('Sign out'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(47),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'BurgerBites · Fresh food, happy moments',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({String? value, String? detail}) _orderCountStatus(
  AuthService auth,
  CustomerOrdersProvider orders,
) {
  if (auth.isInitializing) return (value: '…', detail: 'Checking account');
  if (!auth.isAuthenticated) return (value: '—', detail: 'Sign in to view');
  if (orders.isLoading) return (value: '…', detail: 'Loading');
  if (orders.errorMessage != null) {
    return (value: '—', detail: 'Unavailable');
  }
  return (value: null, detail: null);
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({required this.points});

  final double points;

  @override
  Widget build(BuildContext context) {
    final progress = (points / 2500).clamp(0.0, 1.0).toDouble();
    final remaining = (2500 - points).clamp(0.0, 2500.0);
    final pointLabel = points.toStringAsFixed(points % 1 == 0 ? 0 : 1);
    final remainingLabel = remaining.toStringAsFixed(
      remaining % 1 == 0 ? 0 : 1,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF211814), Color(0xFF49301F)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x55FFC247)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF352116).withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFFC247),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BURGER BITES REWARDS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: .6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '0.5 point for every item you buy',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x33FFC247),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pointLabel PTS',
                  style: const TextStyle(
                    color: Color(0xFFFFD36A),
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pointLabel,
                style: const TextStyle(
                  color: Color(0xFFFFC247),
                  fontSize: 27,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '/ 2,500 points',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Color(0xFFFFD36A),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) =>
                  LinearProgressIndicator(
                    value: animatedProgress,
                    minHeight: 9,
                    backgroundColor: Colors.white.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFC247),
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                points >= 2500
                    ? Icons.lock_open_rounded
                    : Icons.local_offer_rounded,
                size: 13,
                color: const Color(0xFFFFC247),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  points >= 2500
                      ? 'Reward unlocked! Use 2,500 points at checkout for 80% off up to 5 items.'
                      : '$remainingLabel points to unlock 80% off up to 5 items.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.detail,
  });
  final IconData icon;
  final String value;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.brandOrange, size: 18),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 8),
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(
            detail!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 7),
          ),
        ],
      ],
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 9,
      fontWeight: FontWeight.w900,
      letterSpacing: .7,
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: AnimatedPressScale(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: AppColors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            onTap: () => Navigator.of(context).pushNamed(route),
            dense: true,
            leading: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: AppColors.brandOrange, size: 18),
            ),
            title: Text(
              title.tr,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              subtitle.tr,
              style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
