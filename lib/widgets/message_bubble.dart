import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';

/// Chat bubble widget for displaying messages
class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  const MessageBubble({
    super.key,
    required this.message,
    this.onSpeak,
    this.isSpeaking = false,
  });

  /// Copy message text to clipboard
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar (left side)
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError
                  ? Colors.red.shade100
                  : theme.colorScheme.primaryContainer,
              child: Icon(
                message.isError ? Icons.error_outline : Icons.smart_toy,
                size: 18,
                color: message.isError
                    ? Colors.red.shade700
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary
                      : message.isError
                      ? Colors.red.shade50
                      // ignore: deprecated_member_use
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message text
                    SelectableText(
                      message.text,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : message.isError
                            ? Colors.red.shade900
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                    // Timestamp and actions
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: isUser
                                // ignore: deprecated_member_use
                                ? Colors.white.withOpacity(0.7)
                                : theme.colorScheme.onSurfaceVariant
                                      // ignore: deprecated_member_use
                                      .withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),

                        // TTS button for AI messages
                        if (!isUser && !message.isError) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onSpeak,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                isSpeaking
                                    ? Icons.volume_up
                                    : Icons.volume_up_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant
                                    // ignore: deprecated_member_use
                                    .withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // User Avatar (right side)
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  /// Format timestamp to show time
  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
