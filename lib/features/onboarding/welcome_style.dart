import 'package:flutter/material.dart';

abstract final class WelcomeStyle {
  static const cream = Color(0xFFF5F1EA);
  static const paper = Color(0xFFFAF7F2);
  static const ink = Color(0xFF1B1916);
  static const muted = Color(0xFF6E675D);
  static const gold = Color(0xFFB08D57);
  static const forest = Color(0xFF2F4A35);

  static const serif = 'Georgia';
  static const serifFallbacks = ['Times New Roman', 'Times', 'serif'];

  static const display = TextStyle(
    fontFamily: serif,
    fontFamilyFallback: serifFallbacks,
    color: ink,
    height: 1.15,
    fontWeight: FontWeight.w500,
  );

  static const eyebrow = TextStyle(
    color: gold,
    fontSize: 11,
    letterSpacing: 3.2,
    fontWeight: FontWeight.w600,
  );
}
