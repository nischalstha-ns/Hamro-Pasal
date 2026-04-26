import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'gesture_navigation_wrapper.dart';

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.body,
    this.navigationRail,
    this.showNavigationRail = false,
  });

  final Widget body;
  final Widget? navigationRail;
  final bool showNavigationRail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= AppConstants.mobileBreakpoint;

        if (isTablet && showNavigationRail && navigationRail != null) {
          return Row(
            children: [
              navigationRail!,
              const VerticalDivider(width: 1),
              Expanded(
                child: GestureNavigationWrapper(child: body),
              ),
            ],
          );
        }

        return GestureNavigationWrapper(child: body);
      },
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.tabletBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
