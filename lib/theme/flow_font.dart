import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class FlowFont {
  static TextTheme applyTo(TextTheme textTheme) {
    return GoogleFonts.montserratTextTheme(textTheme);
  }
}
