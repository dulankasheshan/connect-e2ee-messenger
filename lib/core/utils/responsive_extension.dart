import 'package:flutter/cupertino.dart';

extension ResponsiveExtension on BuildContext {
  // Get full width and height
  double get screeWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Get percentage of screen height (e.g., context.heightPct(0.2) = 20% of height)
  double heightPct(double percent) => MediaQuery.of(this).size.height * percent;

  // Get percentage of screen width
  double widthPct(double percent) => MediaQuery.of(this).size.width * percent;

  // Industry standard breakpoints for responsive layouts
  bool get isMobile => MediaQuery.of(this).size.width < 600;
  bool get isTablet => MediaQuery.of(this).size.width >= 600 && MediaQuery.of(this).size.width < 1200;
  bool get isDesktop => MediaQuery.of(this).size.width >= 1200;
}
