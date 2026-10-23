import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Whether the current screen has a route beneath it. Falls back to the plain
/// Navigator when a screen is pumped without GoRouter (widget tests).
bool canGoBack(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router != null) return router.canPop();
  return Navigator.of(context).canPop();
}

/// Pops the current route, or returns to the home shell when this screen was
/// opened without a route beneath it (notification, deep link, cold start).
void goBackOrHome(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) {
    Navigator.of(context).maybePop();
  } else if (router.canPop()) {
    router.pop();
  } else {
    router.go('/');
  }
}
