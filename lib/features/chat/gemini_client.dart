import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/api/api_client.dart';
import 'package:my_app/core/config/gemini_config.dart';
import 'package:my_app/features/chat/agri_link_guide.dart';
import 'package:my_app/features/chat/chat_models.dart';

class GeminiClient {
  GeminiClient({
    http.Client? httpClient,
    String? apiKey,
    List<String>? models,
  })  : _http = httpClient ?? http.Client(),
        _apiKeyOverride = apiKey,
        _models = _uniqueModels(models);

  final http.Client _http;
  final String? _apiKeyOverride;
  final List<String> _models;

  String get _apiKey => (_apiKeyOverride ?? GeminiConfig.apiKey).trim();

  static const _endpointHost = 'generativelanguage.googleapis.com';

  Future<String> generateReply({
    required List<ChatMessage> history,
    required String userText,
  }) async {
    if (!kIsWeb && _apiKey.isEmpty) {
      throw GeminiException(
        'AgriLink chat is not configured yet. Add a Gemini API key to enable it.',
      );
    }

    final contents = buildContents(history: history, userText: userText);
    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': AgriLinkGuide.systemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 2048,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    });

    Object? lastError;
    if (kIsWeb) {
      return _postViaBackend(history: history, userText: userText);
    }

    for (final model in _models) {
      try {
        return await _postModel(model: model, body: body);
      } on GeminiException catch (error) {
        lastError = error;
        if (_isUnreachable(error.message)) {
          try {
            return await _postViaBackend(history: history, userText: userText);
          } on GeminiException catch (proxyError) {
            lastError = proxyError;
            if (!_isUnreachable(proxyError.message)) rethrow;
          }
        }
        if (!_shouldTryNextModel(error.message)) rethrow;
      }
    }

    throw lastError is GeminiException
        ? lastError
        : GeminiException('AgriLink chat could not complete that request.');
  }

  /// Public so tests can lock the exact payload sent to Gemini.
  static List<Map<String, Object>> buildContents({
    required List<ChatMessage> history,
    required String userText,
  }) {
    final contents = <Map<String, Object>>[];
    for (final message in history) {
      if (message.isError || message.text.trim().isEmpty) continue;
      contents.add({
        'role': message.role == ChatRole.user ? 'user' : 'model',
        'parts': [
          {'text': message.text},
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userText.trim()},
      ],
    });
    return contents;
  }

  static String parseText(Map<String, dynamic> json) {
    final promptBlock = json['promptFeedback'] is Map
        ? (json['promptFeedback'] as Map)['blockReason']?.toString()
        : null;
    if (promptBlock != null && promptBlock.isNotEmpty) {
      throw GeminiException(
        'Please ask a general question about using AgriLink.',
      );
    }

    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw GeminiException(
        'පිළිතුරක් ලැබුණේ නැත. කරුණාකර ප්‍රශ්නය නැවත අසන්න.',
      );
    }

    final first = candidates.first;
    if (first is! Map) {
      throw GeminiException('AgriLink chat returned an unexpected reply.');
    }

    final finishReason = first['finishReason']?.toString();
    if (finishReason == 'SAFETY' || finishReason == 'BLOCKLIST') {
      throw GeminiException(
        'Please ask a general question about using AgriLink.',
      );
    }

    final content = first['content'];
    if (content is! Map) {
      throw GeminiException('AgriLink chat returned an empty reply.');
    }
    final parts = content['parts'];
    if (parts is! List) {
      throw GeminiException('AgriLink chat returned an empty reply.');
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is! Map || part['thought'] == true) continue;
      if (part['text'] is String) {
        buffer.write(part['text']);
      }
    }
    final text = _forDisplay(buffer.toString());
    if (text.isEmpty) {
      throw GeminiException(
        'පිළිතුරක් ලැබුණේ නැත. කරුණාකර ප්‍රශ්නය නැවත අසන්න.',
      );
    }
    return text;
  }

  static String _forDisplay(String raw) {
    final cleaned = raw
        .replaceAll('**', '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    return cleaned
        .split('\n')
        .where((line) => !_isMetaLine(line))
        .join('\n')
        .trim();
  }

  static bool _isMetaLine(String line) {
    final text = line.trim();
    return RegExp(
          r"^(\*\s*)?(let's|let us|i will|i'll|here's how i|here is how i)\b",
          caseSensitive: false,
        ).hasMatch(text) ||
        RegExp(
          r"\b(write it in|internal thought|reasoning:|draft:)\b",
          caseSensitive: false,
        ).hasMatch(text);
  }

  Future<String> _postModel({
    required String model,
    required String body,
  }) async {
    final uri = Uri.https(
      _endpointHost,
      '/v1beta/models/$model:generateContent',
    );
    late http.Response response;
    try {
      response = await _http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw GeminiException(
        'පිළිතුර ලැබීමට වැඩි කාලයක් ගත විය. කරුණාකර නැවත උත්සාහ කරන්න.',
      );
    } catch (error) {
      throw GeminiException(_unreachableMessage(error));
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw GeminiException(_httpMessage(response.statusCode));
    }

    if (response.statusCode == 200) {
      return parseText(json);
    }

    final apiMessage = _extractApiError(json);
    throw GeminiException(_httpMessage(response.statusCode, apiMessage));
  }

  static String _httpMessage(int status, [String? apiMessage]) {
    switch (status) {
      case 400:
        return apiMessage ?? 'That question could not be sent. Try rephrasing it.';
      case 401:
      case 403:
        return 'Chat access was refused. The Gemini API key may be invalid.';
      case 404:
        return 'The selected Gemini model is not available for this key.';
      case 429:
        return 'Too many questions right now. Try again in a moment.';
      default:
        return apiMessage ?? 'AgriLink chat is unavailable right now (HTTP $status).';
    }
  }

  Future<String> _postViaBackend({
    required List<ChatMessage> history,
    required String userText,
  }) async {
    try {
      final messages = <Map<String, String>>[
        for (final message in history)
          if (!message.isError && message.text.trim().isNotEmpty)
            {
              'role': message.role == ChatRole.user ? 'user' : 'model',
              'text': message.text,
            },
      ];
      return await AgriLinkApi.instance.farmerChat(
        messages: messages,
        userText: userText.trim(),
      );
    } on AgriLinkApiException catch (error) {
      if (error.message.contains('Is the API running')) {
        throw GeminiException(
          'Browser chat needs the AgriLink API. From the backend folder run npm run start:dev, then send again.',
        );
      }
      throw GeminiException(error.message);
    } catch (error) {
      throw GeminiException(_unreachableMessage(error));
    }
  }

  static bool _isUnreachable(String message) {
    final raw = message.toLowerCase();
    return raw.contains('could not reach') ||
        raw.contains('timed out') ||
        raw.contains('failed to fetch') ||
        raw.contains('api running');
  }

  static String _unreachableMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (kIsWeb ||
        raw.contains('failed to fetch') ||
        raw.contains('xmlhttprequest') ||
        raw.contains('cors')) {
      return 'Browser chat needs the AgriLink API. From the backend folder run npm run start:dev, then send again.';
    }
    if (kDebugMode) {
      return 'Could not reach AgriLink chat: $error';
    }
    return 'Could not reach AgriLink chat. Check your connection and try again.';
  }

  static String? _extractApiError(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return null;
  }

  static bool _shouldTryNextModel(String message) {
    final raw = message.toLowerCase();
    return raw.contains('not available') ||
        raw.contains('http 404') ||
        raw.contains('high demand') ||
        raw.contains('try again later') ||
        raw.contains('overloaded');
  }

  static List<String> _uniqueModels(List<String>? override) {
    final preferred = override ??
        <String>[GeminiConfig.model, ...GeminiConfig.fallbackModels];
    final seen = <String>{};
    return [
      for (final model in preferred)
        if (model.trim().isNotEmpty && seen.add(model.trim())) model.trim(),
    ];
  }
}
