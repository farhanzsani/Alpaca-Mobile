/// App-wide constants for the ALPACA application.
///
/// ALPACA is a digitalization platform for agrarian SMEs
/// and local culinary tourism.
library;

/// General application constants.
abstract final class AppConstants {
  /// The display name of the application.
  static const String appName = 'ALPACA';

  /// The full application title.
  static const String appTitle = 'ALPACA - Agrarian & Culinary Tourism Platform';

  /// Application description.
  static const String appDescription =
      'Platform digitalisasi untuk UMKM agraris dan wisata kuliner lokal';

  /// Current application version.
  static const String appVersion = '1.0.0';

  /// Build number for release tracking.
  static const int buildNumber = 1;

  /// Default locale for the application.
  static const String defaultLocale = 'id_ID';

  /// Default currency code.
  static const String currencyCode = 'IDR';

  /// Default country code for phone numbers.
  static const String defaultCountryCode = '+62';

  /// Maximum file upload size in bytes (10 MB).
  static const int maxFileUploadSize = 10 * 1024 * 1024;

  /// Maximum image dimension in pixels.
  static const int maxImageDimension = 1920;

  /// Image compression quality (0-100).
  static const int imageCompressionQuality = 85;

  /// Default pagination page size.
  static const int defaultPageSize = 20;

  /// Search debounce duration in milliseconds.
  static const int searchDebounceDuration = 300;

  /// Session timeout duration in minutes.
  static const int sessionTimeoutMinutes = 60;

  /// Minimum password length.
  static const int minPasswordLength = 8;

  /// Maximum product name length.
  static const int maxProductNameLength = 100;

  /// Maximum description length.
  static const int maxDescriptionLength = 500;

  /// Supported image formats.
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// Supported document formats.
  static const List<String> supportedDocumentFormats = [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
  ];
}

/// Animation duration constants.
abstract final class AnimationDurations {
  /// Fast animation (150ms).
  static const Duration fast = Duration(milliseconds: 150);

  /// Normal animation (300ms).
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow animation (500ms).
  static const Duration slow = Duration(milliseconds: 500);
}

/// Spacing constants for consistent UI layout.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants.
abstract final class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double circular = 100.0;
}
