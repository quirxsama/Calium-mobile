import 'package:flutter/material.dart';

import 'package:calium_stream/core/utils/navigation_utils.dart';

/// Prevents Android system back from closing the app when a root page was
/// opened without anything beneath it.
class AppBackScope extends StatelessWidget {
  const AppBackScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: canGoBack(context),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) goBackOrHome(context);
    },
    child: child,
  );
}
