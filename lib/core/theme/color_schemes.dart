import 'package:flutter/material.dart';

class AppColorSchemes {
  AppColorSchemes._();

  // Nepal Green seed color
  static const Color seedColor = Color(0xFF1D9E75);

  // Light Color Scheme
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

  // Dark Color Scheme
  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );
}
