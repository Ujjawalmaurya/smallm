import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController textController;
  final bool isModelLoaded;
  final bool isGenerating;
  final VoidCallback onSend;
  final VoidCallback onStop;

  const ChatInputBar({
    super.key,
    required this.textController,
    required this.isModelLoaded,
    required this.isGenerating,
    required this.onSend,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade800, width: 0.8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                enabled: isModelLoaded && !isGenerating,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: !isModelLoaded ? 'Load a model first...' : 'Ask anything...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            if (isGenerating)
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                tooltip: 'Stop generation',
                onPressed: onStop,
              )
            else
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded),
                tooltip: 'Send message',
                onPressed: isModelLoaded ? onSend : null,
              ),
          ],
        ),
      ),
    );
  }
}
