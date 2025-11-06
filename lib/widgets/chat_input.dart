import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

/// Chat input widget with text field and action buttons
class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _micAnimationController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);

    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _textController.text.trim().isNotEmpty;
    });
  }

  Future<void> _sendMessage(ChatProvider chatProvider) async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    setState(() => _hasText = false);
    _focusNode.unfocus();

    await chatProvider.sendMessage(text);
  }

  Future<void> _toggleListening(ChatProvider chatProvider) async {
    if (chatProvider.isListening) {
      await chatProvider.stopListening();
    } else {
      await chatProvider.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Update text controller with listening text
        if (chatProvider.isListening && chatProvider.listeningText.isNotEmpty) {
          _textController.text = chatProvider.listeningText;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Microphone button
                  AnimatedBuilder(
                    animation: _micAnimationController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: chatProvider.isListening
                              // ignore: deprecated_member_use
                              ? theme.colorScheme.primary.withOpacity(
                                  0.2 + _micAnimationController.value * 0.3,
                                )
                              // ignore: deprecated_member_use
                              : theme.colorScheme.surfaceVariant,
                        ),
                        child: IconButton(
                          icon: Icon(
                            chatProvider.isListening
                                ? Icons.mic
                                : Icons.mic_none,
                            color: chatProvider.isListening
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: chatProvider.isTyping
                              ? null
                              : () => _toggleListening(chatProvider),
                          tooltip: chatProvider.isListening
                              ? 'Stop listening'
                              : 'Voice input',
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 8),

                  // Text input field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled:
                            !chatProvider.isTyping && !chatProvider.isListening,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: chatProvider.isListening
                              ? 'Listening...'
                              : 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(chatProvider),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send button
                  AnimatedScale(
                    scale: _hasText || chatProvider.isListening ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _hasText || chatProvider.isListening
                            ? LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withBlue(255),
                                ],
                              )
                            : null,
                        color: _hasText || chatProvider.isListening
                            ? null
                            // ignore: deprecated_member_use
                            : theme.colorScheme.surfaceVariant,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: _hasText || chatProvider.isListening
                              ? Colors.white
                              // ignore: deprecated_member_use
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
                        ),
                        onPressed:
                            (_hasText || chatProvider.isListening) &&
                                !chatProvider.isTyping
                            ? () => _sendMessage(chatProvider)
                            : null,
                        tooltip: 'Send message',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
