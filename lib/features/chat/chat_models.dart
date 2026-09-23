enum ChatRole { user, model }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.isError = false,
  });

  final String id;
  final ChatRole role;
  final String text;
  final bool isError;

  bool get isUser => role == ChatRole.user;
}

class FarmerChatState {
  const FarmerChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final String? error;

  FarmerChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return FarmerChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;

  @override
  String toString() => message;
}
