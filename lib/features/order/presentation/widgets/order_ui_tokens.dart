import 'package:flutter/material.dart';

class OrderUiTokens {
  const OrderUiTokens._();

  static const Color primarySeed = Color(0xFFD88A16);
  static const Color accentAction = Color(0xFFC8813A);
  static const Color darkAction = Color(0xFF6A3A16);
  static const Color pageBackground = Color(0xFFF5EFE6);
  static const Color cardSurface = Color(0xFFFAF4ED);
  static const Color primaryText = Color(0xFF2C1810);
  static const Color mutedText = Color(0xFF6F5A4E);
  static const Color border = Color(0xFFE2D6C6);
  static const Color danger = Color(0xFFA24D3F);
  static const Color dangerSoft = Color(0xFFF2DFDB);

  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;

  static ButtonStyle primaryButtonStyle({Color? backgroundColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? darkAction,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(58),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    );
  }

  static ButtonStyle secondaryOutlinedStyle({Color? color}) {
    final activeColor = color ?? darkAction;
    return OutlinedButton.styleFrom(
      foregroundColor: activeColor,
      side: BorderSide(color: activeColor, width: 1.2),
      minimumSize: const Size.fromHeight(58),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  static ButtonStyle dangerOutlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: danger,
      side: const BorderSide(color: danger, width: 1.2),
      minimumSize: const Size.fromHeight(58),
      backgroundColor: dangerSoft,
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  static InputDecoration inputDecoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      fillColor: cardSurface,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primarySeed),
      ),
    );
  }
}
