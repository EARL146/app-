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
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Center(
                      child: Column(
                        children: [
                          BrandLogo(
                            width: 120,
                            height: 120,
                            animate: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Create an account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your details below to sign up for the app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Full name',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.brandOrange,
                            width: 1.6,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().length < 2) {
                          return 'Enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email address',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.brandOrange,
                            width: 1.6,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(v)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.brandOrange,
                            width: 1.6,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 12) {
                          return 'Use at least 12 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    AnimatedPressScale(
                      enabled: !_isSubmitting,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryButtonGradient,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brandOrange.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AnimatedPressScale(
                          child: TextButton(
                            onPressed: _openSignIn,
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                color: AppColors.brandOrange,
                                fontWeight: FontWeight.w800,
                              ),
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
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthService>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
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
