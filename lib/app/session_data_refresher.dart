import 'package:flutter/widgets.dart';

import 'package:calium_stream/core/services/account_session.dart';

typedef SessionActivatedCallback = void Function(String? userId);

/// Runs [onSessionChanged] whenever the active Hive session is swapped in.
///
/// On a cold start the app boots on the guest boxes and the cubits load their
/// data before the stored session is restored. Activating the session only
/// rebuilds widgets – it does not re-trigger the cubits – so account-bound data
/// (watch history, favorites, tracking) has to be reloaded explicitly.
class SessionDataRefresher extends StatefulWidget {
  const SessionDataRefresher({
    required this.child,
    this.onSessionChanged,
    super.key,
  });

  final Widget child;

  /// Called after the session became ready, with the new user id (`null` for
  /// the guest session).
  final SessionActivatedCallback? onSessionChanged;

  @override
  State<SessionDataRefresher> createState() => _SessionDataRefresherState();
}

class _SessionDataRefresherState extends State<SessionDataRefresher> {
  String? _sessionKey;

  @override
  void initState() {
    super.initState();
    _sessionKey = _currentSessionKey();
    AccountSession.instance.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    AccountSession.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  String _currentSessionKey() {
    final session = AccountSession.instance;
    return '${session.generation}:${session.ready}:${session.userId}';
  }

  void _onSessionChanged() {
    final session = AccountSession.instance;
    if (!session.ready) return;
    final key = _currentSessionKey();
    if (key == _sessionKey) return;
    _sessionKey = key;
    if (widget.onSessionChanged == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onSessionChanged!(session.userId);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
