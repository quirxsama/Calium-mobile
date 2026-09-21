/// Bounds a recovery cycle and invalidates it when the user changes media.
class PlaybackRecovery {
  int _generation = 0;
  bool _running = false;
  bool get isRunning => _running;

  void cancel() {
    _generation++;
    _running = false;
  }

  Future<bool> run(Future<bool> Function(int attempt) reconnect) async {
    if (_running) return false;
    final generation = ++_generation;
    _running = true;
    try {
      for (var attempt = 1; attempt <= 3; attempt++) {
        bool recovered;
        try {
          recovered = await reconnect(attempt);
        } catch (_) {
          recovered = false;
        }
        if (generation != _generation) return false;
        if (recovered) return true;
      }
      return false;
    } finally {
      if (generation == _generation) _running = false;
    }
  }
}
