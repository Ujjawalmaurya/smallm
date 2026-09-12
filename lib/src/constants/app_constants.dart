/// Application-wide constants and default LLM inference configuration.
class Constants {
  Constants._();

  /// Baseline system prompt to establish conversational persona without tool definitions.
  static const String defaultSystemPrompt =
      'You are a helpful assistant. Talk straightforwardly, no bluff, to the point.';

  /// Maximum tokens (prompt + output) held in device RAM.
  /// 2048 balances memory safety on 4GB-6GB mobile devices with adequate conversational context.
  static const int defaultContextSize = 2048;

  /// Worker threads for matrix multiplication during token generation.
  /// 4 aligns with typical mobile CPU big.LITTLE performance clusters.
  static const int defaultThreadCount = 4;

  /// Retains the last 6 messages (~3 user/assistant turns) to prevent KV cache exhaustion.
  static const int slidingWindowTurns = 6;

  /// Controls generation determinism. Lower (0.3) prevents small-model hallucinations.
  static const double defaultTemperature = 0.3;

  /// Nucleus sampling cutoff: evaluates top 85% probability mass to drop irrelevant tokens.
  static const double defaultTopP = 0.85;

  /// Repetition penalty to prevent small models from looping repetitive phrases.
  static const double defaultRepeatPenalty = 1.15;
}
