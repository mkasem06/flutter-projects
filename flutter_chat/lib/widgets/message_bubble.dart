import 'package:flutter/material.dart';

// A MessageBubble for showing a single chat message on the ChatScreen.
class MessageBubble extends StatelessWidget {
  // Create a message bubble which is meant to be the first in the sequence.
  const MessageBubble.first({
    super.key,
    required this.username,
    required this.message,
    required this.isMe,
  }) : isFirstInSequence = true;

  // Create a message bubble that continues the sequence.
  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
  }) : isFirstInSequence = false,
       username = null;

  // Whether or not this message bubble is the first in a sequence of messages
  // from the same user.
  // Modifies the message bubble slightly for these different cases - only
  // shows username for the first message from the same user, and changes
  // the shape of the bubble for messages thereafter.
  final bool isFirstInSequence;

  // Username of the user.
  // Not required if the message is not the first in a sequence.
  final String? username;
  final String message;

  // Controls how the MessageBubble will be aligned.
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      // Remove horizontal margin since no user image spacing is needed
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        // The side of the chat screen the message should show at.
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // First messages in the sequence provide a visual buffer at
              // the top.
              if (isFirstInSequence) const SizedBox(height: 18),
              if (username != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 13,
                    right: 13,
                  ),
                  child: Text(
                    username!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // The "speech" box surrounding the message.
              Container(
                decoration: BoxDecoration(
                  color: isMe
                      ? theme.colorScheme.primary
                      : (isDarkMode
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.colorScheme.secondaryContainer),
                  // Only show the message bubble's "speaking edge" if first in
                  // the chain.
                  // Whether the "speaking edge" is on the left or right depends
                  // on whether or not the message bubble is the current user.
                  borderRadius: BorderRadius.only(
                    topLeft: !isMe && isFirstInSequence
                        ? Radius.zero
                        : const Radius.circular(12),
                    topRight: isMe && isFirstInSequence
                        ? Radius.zero
                        : const Radius.circular(12),
                    bottomLeft: const Radius.circular(12),
                    bottomRight: const Radius.circular(12),
                  ),
                ),
                // Set some reasonable constraints on the width of the
                // message bubble so it can adjust to the amount of text
                // it should show.
                constraints: const BoxConstraints(maxWidth: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                // Margin around the bubble.
                margin: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 12,
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    // Add a little line spacing to make the text look nicer
                    // when multilined.
                    height: 1.3,
                    color: isMe
                        ? theme.colorScheme.onPrimary
                        : (isDarkMode
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSecondaryContainer),
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
