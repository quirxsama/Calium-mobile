/// Convenience formatting extensions on [Duration].
extension DurationFormatter on Duration {
  /// Returns a zero-padded `MM:SS` string.
  ///
  /// ```dart
  /// Duration(minutes: 3, seconds: 7).toMinSecString(); // '03:07'
  /// ```
  String toMinSecString() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Returns a zero-padded `HH:MM:SS` string.
  ///
  /// ```dart
  /// Duration(hours: 1, minutes: 5, seconds: 9).toHourMinSecString(); // '01:05:09'
  /// ```
  String toHourMinSecString() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Returns a human-readable Turkish string like `24 dk` or `1 sa 15 dk`.
  ///
  /// ```dart
  /// Duration(minutes: 24).toReadableString();           // '24 dk'
  /// Duration(hours: 1, minutes: 15).toReadableString();  // '1 sa 15 dk'
  /// ```
  String toReadableString() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours sa $minutes dk';
    } else if (hours > 0) {
      return '$hours sa';
    } else {
      return '$minutes dk';
    }
  }
}
