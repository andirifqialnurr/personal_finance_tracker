import 'package:flutter/material.dart';

/// Central color bank for Flow's light and dark visual tokens.
abstract final class FlowColors {
  static const lightBackground = Color(0xFFF7F7F4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF182321);
  static const lightMutedText = Color(0xFF6F7B78);

  static const darkBackground = Color(0xFF171C1B);
  static const darkSurface = Color(0xFF222927);
  static const darkText = Color(0xFFF2F5F3);
  static const darkMutedText = Color(0xFFAAB8B3);

  static const accent = Color(0xFF168C78);
  static const income = Color(0xFF168C78);
  static const expense = Color(0xFFC96B6B);
  static const destructive = Color(0xFFB84444);
  static const chartAmber = Color(0xFFE0A458);
  static const chartBlue = Color(0xFF6D8FC7);
  static const chartPurple = Color(0xFF9B7EBD);
}
