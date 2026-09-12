import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:smollm_app/screens/chat/widgets/chat_bubble.dart';
import 'package:smollm_app/screens/chat/widgets/chat_input_bar.dart';
import 'package:smollm_app/screens/chat/widgets/empty_chat_view.dart';
import 'package:smollm_app/src/constants/app_constants.dart';
import 'package:smollm_app/src/services/llama_service.dart';

/// The main chat screen where you load models and chat with them.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final LlamaService _llamaService = LlamaService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(role: 'system', content: "${Constants.defaultSystemPrompt}, Never use filler words"),
  ];

  bool _isLoading = false;
  bool _isGenerating = false;
  String _currentResponse = '';
  String _status = 'No model selected';
  String? _loadedModelName;

  @override
  void dispose() {
    _llamaService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Model picker/loader.
  Future<void> pickAndLoadModel() async {
    if (_isLoading || _isGenerating) return;

    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['gguf']);
      if (file == null || file.path == null) return;

      final path = file.path!;
      final fileName = file.name;

      if (!path.toLowerCase().endsWith('.gguf')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Selected file must have a .gguf extension')));
        return;
      }

      setState(() {
        _isLoading = true;
        _status = 'Detecting GPU...';
      });

      final gpu = await _llamaService.detectGpu();

      if (mounted) {
        setState(() {
          _status = 'Loading $fileName (${gpu.vulkanSupported ? "Vulkan GPU" : "CPU"})...';
        });
      }

      await _llamaService.loadModel(
        modelPath: path,
        threads: Constants.defaultThreadCount,
        contextSize: Constants.defaultContextSize,
        gpuLayers: gpu.recommendedGpuLayers,
      );

      if (!mounted) return;

      setState(() {
        _loadedModelName = fileName;
        _isLoading = false;
        _status = 'Ready: $fileName';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _status = 'Failed to load model';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Model load error: $e')));
    }
  }

  /// Keeps the system prompt and only the last few messages so we don't run out of memory.
  List<ChatMessage> _preparePromptMessages() {
    final systemMessage = _messages.firstWhere(
      (m) => m.role == 'system',
      orElse: () => ChatMessage(role: 'system', content: Constants.defaultSystemPrompt),
    );

    final conversation = _messages.where((m) => m.role != 'system').toList();

    final recentConversation = conversation.length > Constants.slidingWindowTurns
        ? conversation.sublist(conversation.length - Constants.slidingWindowTurns)
        : conversation;

    return [systemMessage, ...recentConversation];
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || !_llamaService.isModelLoaded || _isGenerating) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isGenerating = true;
      _currentResponse = '';
    });
    _scrollToBottom();

    try {
      final promptMessages = _preparePromptMessages();
      final stream = _llamaService.generateChat(
        messages: promptMessages,
        temperature: Constants.defaultTemperature,
        topP: Constants.defaultTopP,
        repeatPenalty: Constants.defaultRepeatPenalty,
      );

      await for (final token in stream) {
        if (!mounted) break;

        setState(() {
          _currentResponse += token;
        });
        _scrollToBottom();
      }

      if (!mounted) return;

      if (_currentResponse.isNotEmpty) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', content: _currentResponse));
          _currentResponse = '';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _stopGeneration() async {
    await _llamaService.stop();
    if (mounted) {
      setState(() {
        _isGenerating = false;
        if (_currentResponse.isNotEmpty) {
          _messages.add(ChatMessage(role: 'assistant', content: '$_currentResponse [Stopped]'));
          _currentResponse = '';
        }
      });
    }
  }

  Future<void> _clearChat() async {
    await _llamaService.clearContext();
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.role != 'system');
      _currentResponse = '';
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleMessages = _messages.where((m) => m.role != 'system').toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Local LLM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(
              _status,
              style: TextStyle(
                fontSize: 12,
                color: _llamaService.isModelLoaded ? Colors.greenAccent : Colors.grey.shade400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear chat',
              onPressed: _isGenerating ? null : _clearChat,
            ),
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Pick GGUF model',
            onPressed: _isLoading || _isGenerating ? null : pickAndLoadModel,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: visibleMessages.isEmpty && _currentResponse.isEmpty
                ? EmptyChatView(
                    isModelLoaded: _llamaService.isModelLoaded,
                    loadedModelName: _loadedModelName,
                    isLoading: _isLoading,
                    onPickModel: pickAndLoadModel,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: visibleMessages.length + (_currentResponse.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < visibleMessages.length) {
                        final msg = visibleMessages[index];
                        return ChatBubble(text: msg.content, isUser: msg.role == 'user');
                      }
                      return ChatBubble(text: _currentResponse, isUser: false, isStreaming: true);
                    },
                  ),
          ),
          ChatInputBar(
            textController: _textController,
            isModelLoaded: _llamaService.isModelLoaded,
            isGenerating: _isGenerating,
            onSend: _sendMessage,
            onStop: _stopGeneration,
          ),
        ],
      ),
    );
  }
}
