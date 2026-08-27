import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Securely retrieves Google Gemini AI API Key exclusively from .env file
  static String get defaultGeminiApiKey {
    try {
      final envKey = dotenv.env['GEMINI_API_KEY'];
      if (envKey != null && envKey.trim().isNotEmpty && !envKey.contains('your_gemini_api_key')) {
        return envKey.trim();
      }
    } catch (_) {}
    return '';
  }

  /// Retrieves the Google OAuth server/web client ID exclusively from .env file.
  /// Used by GoogleSignIn to validate ID tokens server-side.
  static String get googleOAuthClientId {
    try {
      final clientId = dotenv.env['GOOGLE_OAUTH_CLIENT_ID'];
      if (clientId != null && clientId.trim().isNotEmpty && !clientId.contains('your_')) {
        return clientId.trim();
      }
    } catch (_) {}
    return '';
  }
}

