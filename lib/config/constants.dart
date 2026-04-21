// ============================================================
// 应用配置常量
// 修复说明：API Key 不再硬编码，通过 SharedPreferences 在运行时读取
// ============================================================

class AppConstants {
  // ---- WebSocket 连接 ----
  static const String realtimeBaseUrl =
      'wss://dashscope.aliyuncs.com/api-ws/v1/realtime';
  static const String realtimeBaseUrlIntl =
      'wss://dashscope-intl.aliyuncs.com/api-ws/v1/realtime';

  static const String model = 'qwen-omni-turbo-realtime';

  // ---- 音色选项（以 API 实际支持的音色为准）----
  static const String defaultVoice = 'Chelsie';
  static const List<String> availableVoices = [
    'Chelsie',
    'Serena',
    'Ethan',
    'Cherry',
  ];

  // ---- 音频参数 ----
  static const int inputSampleRate = 16000;
  static const int inputChannels = 1;
  static const int outputSampleRate = 24000;
  static const int outputChannels = 1;
  static const int audioChunkBytes = 3200; // 100ms @ 16kHz 16-bit mono

  // ---- VAD 参数 ----
  static const double vadThreshold = 0.5;
  static const int vadSilenceDurationMs = 1200;

  // ---- WebSocket 心跳间隔（修复：避免移动网络断连）----
  static const int heartbeatIntervalSeconds = 20;

  // ---- WebSocket 重连 ----
  static const int maxReconnectAttempts = 3;

  // ---- SharedPreferences key ----
  static const String prefApiKey = 'dashscope_api_key';
  static const String prefVoice = 'selected_voice';
  static const String prefUseIntlEndpoint = 'use_intl_endpoint';

  // ---- 课程级别 ----
  static const List<String> levels = ['A1', 'A2', 'B1'];

  // ---- 应用信息 ----
  static const String appName = 'Spanish Voice Tutor';
  static const String appVersion = '1.0.0';
}
