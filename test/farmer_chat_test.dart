import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/config/gemini_config.dart';
import 'package:my_app/features/chat/agri_link_guide.dart';
import 'package:my_app/features/chat/chat_models.dart';
import 'package:my_app/features/chat/chat_provider.dart';
import 'package:my_app/features/chat/gemini_client.dart';

class _FakeGeminiClient extends GeminiClient {
  _FakeGeminiClient(this.reply) : super(apiKey: 'test-key');

  final String reply;
  List<ChatMessage>? lastHistory;
  String? lastUserText;

  @override
  Future<String> generateReply({
    required List<ChatMessage> history,
    required String userText,
  }) async {
    lastHistory = history;
    lastUserText = userText;
    return reply;
  }
}

void main() {
  tearDown(() {
    GeminiConfig.sessionKey = '';
  });

  test('session API key can be set without a rebuild flag', () {
    GeminiConfig.sessionKey = 'AIza-test';
    expect(GeminiConfig.hasApiKey, isTrue);
    expect(GeminiConfig.apiKey, 'AIza-test');
  });

  test('Gemini payload only includes conversation text, not profile fields', () {
    final contents = GeminiClient.buildContents(
      history: const [
        ChatMessage(id: '1', role: ChatRole.user, text: 'How do bids work?'),
        ChatMessage(
          id: '2',
          role: ChatRole.model,
          text: 'Buyers offer at or above your reserve price.',
        ),
        ChatMessage(
          id: '3',
          role: ChatRole.model,
          text: 'ignored error',
          isError: true,
        ),
      ],
      userText: 'How do I list produce?',
    );

    expect(contents, [
      {
        'role': 'user',
        'parts': [
          {'text': 'How do bids work?'},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Buyers offer at or above your reserve price.'},
        ],
      },
      {
        'role': 'user',
        'parts': [
          {'text': 'How do I list produce?'},
        ],
      },
    ]);
    expect(contents.toString(), isNot(contains('email')));
    expect(contents.toString(), isNot(contains('phone')));
    expect(contents.toString(), isNot(contains('farmerId')));
  });

  test('Gemini parser reads candidate text and strips light markdown', () {
    final text = GeminiClient.parseText({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '## List produce\nUse **List produce** on Home.'},
            ],
          },
        },
      ],
    });

    expect(text, 'List produce\nUse List produce on Home.');
  });

  test('Gemini parser hides internal thoughts and planning lines', () {
    final text = GeminiClient.parseText({
      'candidates': [
        {
          'content': {
            'parts': [
              {
                'thought': true,
                'text': "* Let's write it in clear, simple Sinhala script:",
              },
              {
                'text':
                    "Let's write it in Sinhala:\nනිෂ්පාදන ලැයිස්තුගත කිරීමට Home තිරයේ List produce තෝරන්න.",
              },
            ],
          },
        },
      ],
    });

    expect(text, 'නිෂ්පාදන ලැයිස්තුගත කිරීමට Home තිරයේ List produce තෝරන්න.');
  });

  test('Gemini parser rejects safety-blocked replies', () {
    expect(
      () => GeminiClient.parseText({
        'candidates': [
          {'finishReason': 'SAFETY', 'content': <String, dynamic>{}},
        ],
      }),
      throwsA(isA<GeminiException>()),
    );
  });

  test('system prompt stays general and covers farmer screens', () {
    expect(AgriLinkGuide.systemPrompt, contains('Do not use, request, or invent'));
    expect(AgriLinkGuide.systemPrompt, contains('List produce'));
    expect(AgriLinkGuide.systemPrompt, contains('Crop planning'));
    expect(AgriLinkGuide.systemPrompt, contains('Singlish'));
    expect(AgriLinkGuide.systemPrompt, contains('Never output reasoning'));
  });

  test('non-farmers cannot send chat messages', () async {
    final client = _FakeGeminiClient('should not be called');
    final notifier = FarmerChatNotifier(client: client, isFarmer: false);

    await notifier.send('How do bids work?');

    expect(notifier.state.messages, isEmpty);
    expect(notifier.state.error, 'Ask AgriLink is available to farmers only.');
    expect(client.lastUserText, isNull);
  });

  test('farmers send general questions without attaching profile data', () async {
    final client = _FakeGeminiClient(
      'Open Home and tap List produce. Set crop, quantity, reserve price, and a bidding window.',
    );
    final notifier = FarmerChatNotifier(client: client, isFarmer: true);

    await notifier.send('How do I list produce?');

    expect(client.lastUserText, 'How do I list produce?');
    expect(client.lastHistory, isEmpty);
    expect(notifier.state.messages, hasLength(2));
    expect(notifier.state.messages.last.role, ChatRole.model);
    expect(notifier.state.messages.last.text, contains('List produce'));
  });
}
