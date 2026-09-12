import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:smollm_app/src/constants/app_constants.dart';

/// Manages the local llama.cpp AI engine: loading models, checking GPU support, and streaming chat.
class LlamaService {
  LlamaController? _controller;

  /// Returns true if a model is currently loaded in native memory and ready to chat.
  bool get isModelLoaded => _controller != null;

  /// Checks if the GPU supports Vulkan and asks how many layers we can offload to it.
  Future<GpuInfo> detectGpu() async {
    final tempController = LlamaController();
    try {
      return await tempController.detectGpu();
    } finally {
      await tempController.dispose();
    }
  }

  /// Unloads any old model first
  /// Loads a .gguf model into memory with thread and context limits.
  Future<void> loadModel({
    required String modelPath,
    int threads = Constants.defaultThreadCount,
    int contextSize = Constants.defaultContextSize,
    int? gpuLayers,
  }) async {
    // Free previous native C++ allocations before creating a new runtime instance.
    await dispose();

    final controller = LlamaController();

    try {
      final gpu = await controller.detectGpu();
      final layers = gpuLayers ?? gpu.recommendedGpuLayers;

      await controller.loadModel(
        modelPath: modelPath,
        threads: threads,
        contextSize: contextSize,
        gpuLayers: layers,
      );

      _controller = controller;
    } catch (e) {
      // If loading fails, dispose the handle so we don't leave an unmanaged C++ pointer leaking RAM.
      await controller.dispose();
      rethrow;
    }
  }

  /// Streams the model's reply token by token as it generates them.
  Stream<String> generateChat({
    required List<ChatMessage> messages,
    double temperature = Constants.defaultTemperature,
    double topP = Constants.defaultTopP,
    double repeatPenalty = Constants.defaultRepeatPenalty,
  }) {
    final controller = _controller;
    if (controller == null) {
      throw StateError('Cannot generate chat: no model loaded.');
    }

    return controller.generateChat(
      messages: messages,
      temperature: temperature,
      topP: topP,
      repeatPenalty: repeatPenalty,
    );
  }

  /// Signals the native loop to stop generating tokens mid-sentence without unloading the model.
  Future<void> stop() async {
    await _controller?.stop();
  }

  /// Wipes the KV cache (token memory) in native RAM to reset the chat, but keeps the model weights loaded.
  Future<void> clearContext() async {
    await _controller?.clearContext();
  }

  /// Frees native C++ heap memory allocated by llama.cpp so we don't leak RAM.
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }
}
