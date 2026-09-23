import 'package:my_app/core/config/gemini_local_key.dart';

/// Gemini access for the farmer chat plugin.
///
/// Resolution order:
/// 1. `--dart-define=GEMINI_API_KEY=...`
/// 2. [kLocalGeminiApiKey] in `gemini_local_key.dart`
abstract final class GeminiConfig {
  static const fromEnvironment = String.fromEnvironment('GEMINI_API_KEY');

  static const model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash-lite',
  );

  static const fallbackModels = <String>[
    'gemini-2.5-flash-lite',
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-flash-latest',
  ];

  /// Set at runtime from the farmer chat screen so development can start
  /// without a rebuild. Not persisted.
  static String sessionKey = '';

  static String get apiKey {
    if (fromEnvironment.trim().isNotEmpty) return fromEnvironment.trim();
    if (sessionKey.trim().isNotEmpty) return sessionKey.trim();
    return kLocalGeminiApiKey.trim();
  }

  static bool get hasApiKey => apiKey.isNotEmpty;
}
