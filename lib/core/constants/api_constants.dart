import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API configuration constants for Calium Mobile.
/// Base URL points to Calium backend (calium.fun) which provides authenticated
/// proxy endpoints for Anizium anime data, asset caching, user auth, and social rooms.
abstract final class ApiConstants {
  // ─── Base Configuration ──────────────────────────────────────
  static String get baseUrl =>
      dotenv.env['CALIUM_BACKEND_URL'] ?? 'https://calium.fun';

  static String get caliumBackendUrl =>
      dotenv.env['CALIUM_BACKEND_URL'] ?? 'https://calium.fun';

  static String get aniziumApiBaseUrl =>
      dotenv.env['ANIZIUM_API_BASE_URL'] ?? 'https://api.anizium.co';

  static const String origin = 'https://x.anizium.co';
  static const String referer = 'https://x.anizium.co/';

  static String get cfControl =>
      dotenv.env['ANIZIUM_CF_CONTROL'] ??
      '134e4c040840015655080906544d030f004b4c075b54500f';

  static String get userSession =>
      dotenv.env['ANIZIUM_USER_SESSION'] ??
      '0356070355535553000c040f515f390f07084a0d565d472d18560c081218400e4451520f585352475d41541d0c5546081f020d51101e';

  static String get userAgent =>
      dotenv.env['ANIZIUM_USER_AGENT'] ??
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36';

  static String get tmdbApiKey =>
      dotenv.env['TMDB_API_KEY'] ?? '75e42cf3985dc80e24781088a764c1c1';

  // ─── Genre IDs ───────────────────────────────────────────────
  /// Maps Turkish genre names to their Anizium API numeric IDs.
  static const Map<String, int> genreIds = {
    'Aile ve Çocuk': 54464,
    'Aksiyon': 62263,
    'Askeri': 40034,
    'Bilim Kurgu': 90158,
    'Büyü ve Kılıç': 82742,
    'Doğaüstü': 11860,
    'Dram': 57282,
    'Dövüş Sanatları': 88689,
    'Ecchi': 17263,
    'Fantastik': 43261,
    'Gençlik Hikayesi': 14837,
    'Gerilim': 57593,
    'Gizem': 78746,
    'Harem': 73510,
    'Hayatta Kalma': 33458,
    'Isekai': 23813,
    'Iyashikei': 34953,
    'İngilizce Dublaj': 79741,
    'Kara Mizah': 40838,
    'Karanlık Fantastik': 92619,
    'Romantizm': 59624,
    'Komedi': 47450,
    'Korku': 7628,
    'Macera': 5263,
    'Meka': 21846,
    'Mitoloji': 43306,
    'Okul': 73505,
    'Parodi': 50737,
    'Psikolojik': 29049,
    'Reenkarnasyon': 38932,
    'Samuray': 63917,
    'Sanat': 75150,
    'Seinen': 87910,
    'Shounen': 94032,
    'Spor': 25731,
    'Tarih': 8159,
    'Tatlı Kızlar': 263101,
    'Türkçe Dublaj': 66407,
    'Vahşet': 79793,
    'Vampir': 38454,
    'Yaşamdan Kesitler': 47202,
    'Çoklu Alt Yazı': 15055,
    'Ödüllü Animeler': 84484,
    'Şehir Macerası': 21923,
  };


  // ─── Cache TTLs (in seconds) ─────────────────────────────────
  static const int cacheTtlLatest = 600;
  static const int cacheTtlCalendar = 900;
  static const int cacheTtlCatalog = 1800;
  static const int cacheTtlTop = 1800;
  static const int cacheTtlDetail = 3600;
  static const int cacheTtlSearch = 300;
  static const int cacheTtlTmdbCast = 7200;
}
