import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../navigation/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_brand_button.dart';
import '../../widgets/brand_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.returnToCaller = false});

  final bool returnToCaller;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: BurgerBitesWordmark(
                          width: math
                              .min(320.0, constraints.maxWidth - 48)
                              .clamp(120.0, 320.0)
                              .toDouble(),
                          animate: false,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create an account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111111),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Enter your email to sign up for this app',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111111),
                        ),
                        decoration: _fieldDecoration('email@domain.com'),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111111),
                        ),
                        decoration: _fieldDecoration(
                          'Password',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 12) {
                            return 'Use at least 12 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.name],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111111),
                        ),
                        decoration: _fieldDecoration('Full name'),
                        validator: (value) {
                          final trimmed = (value ?? '').trim();
                          if (trimmed.isNotEmpty && trimmed.length < 2) {
                            return 'Enter at least 2 characters';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 16),
                      AnimatedPressScale(
                        enabled: !_isSubmitting,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.black87,
                              disabledForegroundColor: Colors.white70,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(
                              color: Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Color(0xFFE5E7EB),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _socialButton(
                        icon: const Text(
                          'G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        label: 'Continue with Google',
                      ),
                      const SizedBox(height: 10),
                      _socialButton(
                        icon: const Icon(
                          Icons.apple_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        label: 'Continue with Apple',
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                            height: 1.45,
                          ),
                          children: const [
                            TextSpan(
                              text: 'By clicking continue, you agree to our ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: Color(0xFF111111),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: '\nand '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF111111),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: _openSignIn,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brandRed,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String hint, {
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 14,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.black, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.danger, width: 1.4),
    ),
  );

  Widget _socialButton({
    required Widget icon,
    required String label,
  }) => SizedBox(
    height: 48,
    child: ElevatedButton(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label is not configured yet. Use email and password to create your account.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEEEEEE),
        foregroundColor: const Color(0xFF111111),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthService>();
    final email = _emailController.text.trim().toLowerCase();
    var name = _nameController.text.trim();
    if (name.isEmpty && email.contains('@')) {
      final prefix = email.split('@').first;
      name = prefix.isNotEmpty
          ? '${prefix[0].toUpperCase()}${prefix.substring(1)}'
          : 'Customer';
    } else if (name.isEmpty) {
      name = 'Customer';
    }

    final success = await auth.register(
      name: name,
      email: email,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Unable to create this account.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (widget.returnToCaller && auth.currentUserRole == 'customer') {
      Navigator.of(context).pop(true);
      return;
    }
    final destination = auth.currentUserRole == 'admin'
        ? AppRoutes.adminHome
        : AppRoutes.customerHome;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(destination, (route) => false);
  }

  Future<void> _openSignIn() async {
    final navigator = Navigator.of(context);
    if (!widget.returnToCaller) {
      navigator.pop();
      return;
    }

    final signedIn = await navigator.pushNamed<bool>(
      AppRoutes.signIn,
      arguments: true,
    );
    if (!mounted || signedIn != true) return;

    final auth = context.read<AuthService>();
    if (auth.isAuthenticated && auth.currentUserRole == 'customer') {
      navigator.pop(true);
    }
  }
}
