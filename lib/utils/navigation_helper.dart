import 'package:flutter/material.dart';

class AppNavigation {
  const AppNavigation._();

  static void safeBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  static Future<void> goBack(
    BuildContext context, {
    String fallbackRoute = '/dashboard',
  }) async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == fallbackRoute) {
      return;
    }

    await navigator.pushReplacementNamed(fallbackRoute);
  }

  static Future<bool> handleSystemBack(
    BuildContext context, {
    String fallbackRoute = '/dashboard',
  }) async {
    await goBack(context, fallbackRoute: fallbackRoute);
    return false;
  }
}

class AppBackButton extends StatelessWidget {
  final String fallbackRoute;
  final Color? color;
  final String? tooltip;

  const AppBackButton({
    super.key,
    this.fallbackRoute = '/dashboard',
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => AppNavigation.goBack(
        context,
        fallbackRoute: fallbackRoute,
      ),
      icon: Icon(
        Icons.arrow_back_rounded,
        color: color,
      ),
    );
  }
}
