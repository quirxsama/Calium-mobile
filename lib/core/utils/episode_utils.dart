
class EpisodeUtils {
  EpisodeUtils._();

  /// Formats an episode title strictly as `S{season} B{episode}: {title}`.
  /// If title is missing or generic (like 'Bölüm X'), it returns `S{season} B{episode}`.
  static String formatEpisodeLabel({
    int season = 1,
    int episode = 1,
    String? title,
  }) {
    final s = season > 0 ? season : 1;
    final e = episode > 0 ? episode : 1;
    final prefix = 'S$s B$e';

    if (title == null || title.trim().isEmpty) {
      return prefix;
    }

    final cleanedTitle = title.trim();

    // Avoid redundancy like "S1 B1: Bölüm 1" or "S1 B1: Episode 1"
    final lowerTitle = cleanedTitle.toLowerCase();
    if (lowerTitle == 'bölüm $e' ||
        lowerTitle == 'episode $e' ||
        lowerTitle == 'bölüm' ||
        lowerTitle == 'episode' ||
        lowerTitle == 's$s b$e' ||
        lowerTitle == 's$s e$e') {
      return prefix;
    }

    // Sometimes API returns title as "S1 B1" already
    if (lowerTitle.startsWith('s$s b$e') || lowerTitle.startsWith('s$s e$e')) {
      return cleanedTitle;
    }

    return '$prefix: $cleanedTitle';
  }
}
