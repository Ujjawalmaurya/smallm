import 'package:flutter/material.dart';

/// Placeholder view displayed when the conversation is empty.
class EmptyChatView extends StatelessWidget {
  final bool isModelLoaded;
  final String? loadedModelName;
  final bool isLoading;
  final VoidCallback onPickModel;

  const EmptyChatView({
    super.key,
    required this.isModelLoaded,
    this.loadedModelName,
    required this.isLoading,
    required this.onPickModel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory_outlined, size: 56, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              !isModelLoaded
                  ? 'No model loaded.\nLoad a .gguf model first.'
                  : '$loadedModelName loaded, Start chatting',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400, height: 1.4),
            ),
            if (!isModelLoaded) ...[
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: isLoading ? null : onPickModel,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Select Model'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
