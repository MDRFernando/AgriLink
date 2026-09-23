import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/features/chat/chat_models.dart';
import 'package:my_app/features/chat/gemini_client.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

final geminiClientProvider = Provider<GeminiClient>((ref) {
  return GeminiClient();
});

final farmerChatProvider =
    StateNotifierProvider<FarmerChatNotifier, FarmerChatState>((ref) {
  return FarmerChatNotifier(
    client: ref.watch(geminiClientProvider),
    isFarmer: ref.watch(authProvider).profile?.role == UserRole.farmer,
  );
});

class FarmerChatNotifier extends StateNotifier<FarmerChatState> {
  FarmerChatNotifier({
    required GeminiClient client,
    required this.isFarmer,
  })  : _client = client,
        super(const FarmerChatState());

  final GeminiClient _client;
  final bool isFarmer;
  int _counter = 0;

  static const _maxHistory = 12;

  Future<void> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;

    if (!isFarmer) {
      state = state.copyWith(
        error: 'Ask AgriLink is available to farmers only.',
      );
      return;
    }

    final userMessage = ChatMessage(
      id: _nextId(),
      role: ChatRole.user,
      text: text,
    );
    final pending = [...state.messages, userMessage];
    state = state.copyWith(
      messages: pending,
      isSending: true,
      clearError: true,
    );

    try {
      final reply = await _client.generateReply(
        history: _historyForModel(pending.sublist(0, pending.length - 1)),
        userText: text,
      );
      state = state.copyWith(
        messages: [
          ...pending,
          ChatMessage(
            id: _nextId(),
            role: ChatRole.model,
            text: reply,
          ),
        ],
        isSending: false,
      );
    } catch (error) {
      final message = error is GeminiException
          ? error.message
          : 'AgriLink chat could not complete that request.';
      state = state.copyWith(
        messages: [
          ...pending,
          ChatMessage(
            id: _nextId(),
            role: ChatRole.model,
            text: message,
            isError: true,
          ),
        ],
        isSending: false,
        error: message,
      );
    }
  }

  void clear() {
    _counter = 0;
    state = const FarmerChatState();
  }

  List<ChatMessage> _historyForModel(List<ChatMessage> messages) {
    final usable = messages
        .where((message) => !message.isError && message.text.trim().isNotEmpty)
        .toList();
    if (usable.length <= _maxHistory) return usable;
    return usable.sublist(usable.length - _maxHistory);
  }

  String _nextId() {
    _counter += 1;
    return 'm$_counter';
  }
}
