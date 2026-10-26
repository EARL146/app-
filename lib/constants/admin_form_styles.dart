import 'package:flutter/material.dart';

import 'app_colors.dart';

class AdminFormStyles {
  AdminFormStyles._();

  static const page = Color(0xFFFFF8F4);
  static const surface = Color(0xFFFFFFFF);
  static const input = Color(0xFFFFFDFC);
  static const surfaceTint = Color(0xFFFFF0E8);
  static const text = Color(0xFF30231D);
  static const mutedText = Color(0xFF82746D);
  static const border = Color(0xFFEADFD8);

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: border),
    );

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: page,
      canvasColor: surface,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: AppColors.brandOrange,
        onPrimary: Colors.white,
        secondary: AppColors.brandOrangeDark,
        surface: surface,
        onSurface: text,
        outline: border,
      ),
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        hintStyle: const TextStyle(color: mutedText, fontSize: 12),
        labelStyle: const TextStyle(color: mutedText, fontSize: 12),
        floatingLabelStyle: TextStyle(
          color: AppColors.brandOrangeDark,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: mutedText,
        suffixIconColor: mutedText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        border: outline,
        enabledBorder: outline,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.brandOrange, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerBackgroundColor: AppColors.brandOrange,
        headerForegroundColor: Colors.white,
        dividerColor: border,
      ),
    );
  }
}
