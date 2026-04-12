import 'package:flutter/material.dart';

enum AppBreakpoint { mobile, tablet, desktop }

class ResponsiveLayout {
  static const double mobileMaxWidth = 700;
  static const double handsetMaxShortestSide = 600;
  static const double desktopMinWidth = 1100;
  static const double contentMaxWidth = 760;
  static const double detailMaxWidth = 880;
  static const double formMaxWidth = 460;
  static const double wideContentMaxWidth = 980;

  static AppBreakpoint breakpointOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final shortestSide = size.shortestSide;
    if (shortestSide < handsetMaxShortestSide) {
      return AppBreakpoint.mobile;
    }
    if (width >= desktopMinWidth) return AppBreakpoint.desktop;
    if (width >= mobileMaxWidth) return AppBreakpoint.tablet;
    return AppBreakpoint.mobile;
  }

  static bool isMobile(BuildContext context) =>
      breakpointOf(context) == AppBreakpoint.mobile;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool useRailNavigation(BuildContext context) =>
      breakpointOf(context) != AppBreakpoint.mobile;

  static bool useLandscapePanels(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return isLandscape(context) && size.width >= 1000;
  }

  static double horizontalPadding(BuildContext context) {
    switch (breakpointOf(context)) {
      case AppBreakpoint.mobile:
        return 16;
      case AppBreakpoint.tablet:
        return 24;
      case AppBreakpoint.desktop:
        return 32;
    }
  }
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.contentMaxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: ResponsiveLayout.horizontalPadding(context),
              ),
          child: child,
        ),
      ),
    );
  }
}
