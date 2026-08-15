import 'package:flutter/material.dart';

/// Shared layout tokens used by every Flow screen and component.
abstract final class FlowSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;

  static const cardCompact = 12.0;
  static const cardStandard = 16.0;
  static const cardFeatured = 20.0;

  static const gapTight = xxs;
  static const gapGroup = xs;
  static const gapBlock = sm;
  static const gapSection = md;
}

abstract final class FlowRadii {
  static const card = 16.0;
  static const input = 12.0;
  static const button = 12.0;
  static const pill = 999.0;
}

abstract final class FlowControlSize {
  static const minTouchTarget = 48.0;
  static const iconContainer = 44.0;
}

abstract final class FlowIconSize {
  static const emptyState = 64.0;
  static const pageEmptyState = 56.0;
}

abstract final class FlowShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x140F2420), blurRadius: 20, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A168C78), blurRadius: 2, spreadRadius: 1),
  ];

  static const darkCard = <BoxShadow>[
    BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x24168C78), blurRadius: 2, spreadRadius: 1),
  ];
}
