import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global BLoC observer for development debugging.
/// Logs state transitions and errors to the console.
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode) {
      debugPrint('📘 ${bloc.runtimeType} Event: $event');
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      debugPrint(
        '🔄 ${bloc.runtimeType}: ${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      debugPrint(
        '📝 ${bloc.runtimeType}: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (kDebugMode) {
      debugPrint('❌ ${bloc.runtimeType} Error: $error');
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
