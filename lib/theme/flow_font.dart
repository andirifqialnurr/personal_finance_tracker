import 'package:flutter/material.dart';

abstract final class FlowFont {
  static TextTheme applyTo(TextTheme textTheme) {
    return textTheme.apply(fontFamily: 'Montserrat');
  }
}
