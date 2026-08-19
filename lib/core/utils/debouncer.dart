import 'dart:async';

import 'package:flutter/foundation.dart';

/// A simple debouncer that delays the execution of [run] by [duration].
///
/// Every call to [run] resets the internal timer. Only the last callback
/// survives after the debounce window elapses.
///
/// ```dart
/// final _debouncer = Debouncer();
/// _debouncer.run(() => _bloc.add(SearchChanged(query)));
/// ```
///
/// Always call [dispose] when the owner widget is disposed to avoid leaks.
class Debouncer {
  Debouncer({Duration? delay, Duration? duration})
      : duration = delay ?? duration ?? const Duration(milliseconds: 350);

  /// The debounce window.
  final Duration duration;

  Timer? _timer;

  /// Schedule [action] to execute after [duration].
  ///
  /// If called again before the timer fires, the previous action is cancelled.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancel any pending action and release resources.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
