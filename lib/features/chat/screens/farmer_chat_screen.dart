import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_app/core/config/gemini_config.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/common_widgets.dart';
import 'package:my_app/features/chat/agri_link_guide.dart';
import 'package:my_app/features/chat/chat_models.dart';
import 'package:my_app/features/chat/chat_provider.dart';
import 'package:my_app/shared/entities/enums.dart';
import 'package:my_app/shared/providers/app_providers.dart';

class FarmerChatScreen extends ConsumerStatefulWidget {
  const FarmerChatScreen({super.key});

  @override
  ConsumerState<FarmerChatScreen> createState() => _FarmerChatScreenState();
}

class _FarmerChatScreenState extends ConsumerState<FarmerChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  bool _hasApiKey = GeminiConfig.hasApiKey;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFarmer =
        ref.watch(authProvider).profile?.role == UserRole.farmer;
    if (!isFarmer) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ask AgriLink')),
        body: const EmptyStateView(
          icon: Icons.lock_outline,
          title: 'Farmers only',
          message: 'Ask AgriLink is available on the farmer dashboard.',
        ),
      );
    }

    final chat = ref.watch(farmerChatProvider);
    final configured = _hasApiKey || kIsWeb;

    ref.listen<FarmerChatState>(farmerChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length ||
          previous?.isSending != next.isSending) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask AgriLink'),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              tooltip: 'Clear chat',
              onPressed: chat.isSending
                  ? null
                  : () => ref.read(farmerChatProvider.notifier).clear(),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty
                ? _EmptyIntro(
                    needsApiKey: !configured,
                    onApiKeySaved: () => setState(() {
                      _hasApiKey = GeminiConfig.hasApiKey;
                    }),
                    onSuggestion: _send,
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount:
                        chat.messages.length + (chat.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= chat.messages.length) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(message: chat.messages[index]);
                    },
                  ),
          ),
          _Composer(
            controller: _controller,
            focusNode: _focus,
            sending: chat.isSending,
            autofocus: configured,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  void _send(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(farmerChatProvider.notifier).send(text);
    _focus.requestFocus();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

class _EmptyIntro extends StatelessWidget {
  const _EmptyIntro({
    required this.onSuggestion,
    required this.needsApiKey,
    required this.onApiKeySaved,
  });

  final ValueChanged<String> onSuggestion;
  final bool needsApiKey;
  final VoidCallback onApiKeySaved;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      children: [
        const Center(child: AgriLinkLogo(size: 56)),
        const SizedBox(height: 16),
        Text(
          'General how-to for AgriLink',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask about listings, bids, crop plans, demand, and orders. This chat does not see your farm, listings, or personal details.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (needsApiKey) ...[
          const SizedBox(height: 20),
          _ApiKeyCard(onSaved: onApiKeySaved),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final suggestion in AgriLinkGuide.suggestions)
              ActionChip(
                label: Text(suggestion),
                onPressed: () => onSuggestion(suggestion),
              ),
          ],
        ),
      ],
    );
  }
}

class _ApiKeyCard extends StatefulWidget {
  const _ApiKeyCard({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends State<_ApiKeyCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gemini API key',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Paste a key from Google AI Studio to enable replies. It stays on this device for this session only.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                hintText: 'AIza…',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Save key',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    GeminiConfig.sessionKey = key;
    widget.onSaved();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final background = message.isError
        ? const Color(0xFFFFEBEE)
        : isUser
            ? AppColors.farmer
            : AppColors.surface;
    final foreground = isUser && !message.isError
        ? Colors.white
        : message.isError
            ? AppColors.error
            : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            border: isUser
                ? null
                : Border.all(
                    color: message.isError
                        ? AppColors.error.withValues(alpha: 0.35)
                        : AppColors.border,
                  ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: foreground,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Writing a reply…',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final ValueChanged<String> onSend;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: true,
                  readOnly: false,
                  autofocus: autofocus,
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: sending ? null : onSend,
                  decoration: const InputDecoration(
                    hintText: 'Ask how AgriLink works',
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: sending ? null : () => onSend(controller.text),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                ),
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
