import 'package:flutter/material.dart';

class PremiumPageTransitionsBuilder extends PageTransitionsBuilder {
  const PremiumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Ultra-smooth easing curves
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInCubic,
    );

    // Subtle slide motion (moves up slightly from bottom)
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curve);

    // Fade animation
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curve);

    // Scale animation (0.98 -> 1.0)
    final scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(curve);

    // Secondary fade for the outgoing screen
    final secondaryFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInQuart,
      reverseCurve: Curves.easeOutCubic,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: FadeTransition(
          opacity: secondaryFadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppAnimations {
  /// Ultra-smooth dialog presentation (240ms duration)
  static Future<T?> showPremiumDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel ?? 'Dismiss',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        final child = builder(context);
        return useSafeArea ? SafeArea(child: child) : child;
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInCubic,
        );

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(curve);

        final scaleAnimation = Tween<double>(
          begin: 0.98,
          end: 1.0,
        ).animate(curve);

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Ultra-smooth bottom sheet presentation (280ms duration)
  static Future<T?> showPremiumBottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      shape: shape ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}
