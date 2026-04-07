import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import 'platform_websocket.dart'; // 平台条件导出，隔离 dart:io

// ============================================================
// RealtimeService — 阿里云百炼 WebSocket 实时语音服务
//
// 修复：
//  1. 通过 platform_websocket.dart 隔离 dart:io，修复 Web 白屏
//  2. instructions 保存为实例变量，重连时使用最新值
//  3. 心跳 Timer，防止移动网络 NAT 超时断连
//  4. 完整错误码映射
//  5. API Key 外部注入，不硬编码
// ============================================================

class RealtimeService {
  final PlatformWebSocket _ws = PlatformWebSocket();
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  String _currentInstructions = '';
  String _apiKey = '';
  final _uuid = const Uuid();

  // ---- 事件回调 ----
  Function(String transcript)? onUserTranscript;
  Function(String delta)? onAiTranscriptDelta;
  Function(String full)? onAiTranscriptDone;
  Function(List<int> pcmData)? onAudioDelta;
  Function()? onResponseDone;
  Function(String message, String? code)? onError;
  Function()? onSpeechStarted;
  Function()? onSpeechStopped;
  Function()? onConnected;
  Function()? onDisconnected;

  bool _useIntlEndpoint = false;

  bool get isConnected => _isConnected;

  void setApiKey(String key) => _apiKey = key;

  void setUseIntlEndpoint(bool value) => _useIntlEndpoint = value;

  // =========================================================
  // 连接
  // =========================================================
  Future<void> connect({required String instructions}) async {
    _currentInstructions = instructions;

    if (_apiKey.isEmpty) {
      onError?.call('请先在设置中填写阿里云 DashScope API Key', 'no_api_key');
      return;
    }

    final baseUrl = _useIntlEndpoint
        ? AppConstants.realtimeBaseUrlIntl
        : AppConstants.realtimeBaseUrl;
    final url = '$baseUrl?model=${AppConstants.model}';

    try {
      await _ws.connect(
        url,
        {'Authorization': 'Bearer $_apiKey'},
        onMessage: _handleMessage,
        onDone: _handleDisconnect,
        onError: (Object error) {
          final errStr = error.toString();
          if (errStr.contains('web_not_supported')) {
            onError?.call(
              'Web 预览模式不支持真实语音通话\n请下载 APK 安装到 Android 手机后体验完整功能',
              'web_not_supported',
            );
          } else {
            if (kDebugMode) debugPrint('[RealtimeService] ws error: $error');
            _handleDisconnect();
          }
        },
      );
      _isConnected = true;
      _reconnectAttempts = 0;
      _startHeartbeat();
      onConnected?.call();
      _sendSessionUpdate();
    } catch (e) {
      if (kDebugMode) debugPrint('[RealtimeService] connect failed: $e');
      onError?.call('无法连接到服务器，请检查网络', null);
      _scheduleReconnect();
    }
  }

  // =========================================================
  // 心跳
  // =========================================================
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AppConstants.heartbeatIntervalSeconds),
      (_) {
        if (_isConnected) {
          try {
            _ws.send('ping');
          } catch (_) {}
        }
      },
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // =========================================================
  // 重连
  // =========================================================
  void _handleDisconnect() {
    _isConnected = false;
    _stopHeartbeat();
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= AppConstants.maxReconnectAttempts) {
      onError?.call(
        '连接断开，已尝试重连 ${AppConstants.maxReconnectAttempts} 次失败\n请检查网络后重试',
        'reconnect_failed',
      );
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    if (kDebugMode) {
      debugPrint('[RealtimeService] 第 $_reconnectAttempts 次重连，${delay.inSeconds}s 后...');
    }
    Future.delayed(delay, () {
      if (_currentInstructions.isNotEmpty) {
        connect(instructions: _currentInstructions);
      }
    });
  }

  // =========================================================
  // 会话配置
  // =========================================================
  void updateInstructions(String instructions) {
    _currentInstructions = instructions;
    if (_isConnected) _sendSessionUpdate();
  }

  void _sendSessionUpdate() {
    _send({
      'event_id': 'evt_session_${_uuid.v4()}',
      'type': 'session.update',
      'session': {
        'modalities': ['text', 'audio'],
        'voice': AppConstants.defaultVoice,
        'input_audio_format': 'pcm',
        'output_audio_format': 'pcm',
        'input_audio_transcription': {'model': 'whisper-1'},
        'instructions': _currentInstructions,
        'turn_detection': {
          'type': 'server_vad',
          'threshold': AppConstants.vadThreshold,
          'silence_duration_ms': AppConstants.vadSilenceDurationMs,
        },
        'temperature': 0.8,
        'max_tokens': 4096,
      },
    });
  }

  // =========================================================
  // 发送音频
  // =========================================================
  void sendAudio(String base64Audio) {
    if (!_isConnected) return;
    _send({
      'event_id': 'evt_audio_${_uuid.v4()}',
      'type': 'input_audio_buffer.append',
      'audio': base64Audio,
    });
  }

  void cancelResponse() {
    if (!_isConnected) return;
    _send({
      'event_id': 'evt_cancel_${_uuid.v4()}',
      'type': 'response.cancel',
    });
  }

  // =========================================================
  // 消息处理
  // =========================================================
  void _handleMessage(dynamic data) {
    if (data is String && (data == 'pong' || data.isEmpty)) return;

    final raw = data is String ? data : utf8.decode(data as List<int>);
    Map<String, dynamic> msg;
    try {
      msg = json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final type = msg['type'] as String? ?? '';

    switch (type) {
      case 'session.created':
      case 'session.updated':
        break;
      case 'error':
        final err = msg['error'] as Map<String, dynamic>?;
        _handleApiError(
          err?['message'] as String? ?? '未知错误',
          err?['code'] as String?,
        );
      case 'input_audio_buffer.speech_started':
        onSpeechStarted?.call();
      case 'input_audio_buffer.speech_stopped':
        onSpeechStopped?.call();
      case 'response.audio.delta':
        final b64 = msg['delta'] as String? ?? '';
        if (b64.isNotEmpty) onAudioDelta?.call(base64.decode(b64));
      case 'response.audio_transcript.delta':
        onAiTranscriptDelta?.call(msg['delta'] as String? ?? '');
      case 'response.audio_transcript.done':
        onAiTranscriptDone?.call(msg['transcript'] as String? ?? '');
      case 'conversation.item.input_audio_transcription.completed':
        onUserTranscript?.call(msg['transcript'] as String? ?? '');
      case 'response.done':
        onResponseDone?.call();
      default:
        if (kDebugMode) debugPrint('[RealtimeService] unhandled: $type');
    }
  }

  void _handleApiError(String message, String? code) {
    final userMsg = switch (code) {
      'rate_limit_exceeded' => '请求过于频繁，请稍后重试',
      'invalid_api_key' => 'API Key 无效，请在设置中重新填写',
      'insufficient_quota' => 'API 额度不足，请登录阿里云控制台充值',
      'model_not_found' => '模型暂不可用，请稍后重试',
      _ => message,
    };
    onError?.call(userMsg, code);
  }

  void _send(Map<String, dynamic> event) {
    if (!_isConnected) return;
    try {
      _ws.send(json.encode(event));
    } catch (e) {
      if (kDebugMode) debugPrint('[RealtimeService] send failed: $e');
    }
  }

  Future<void> disconnect() async {
    _reconnectAttempts = AppConstants.maxReconnectAttempts;
    _stopHeartbeat();
    _isConnected = false;
    await _ws.close();
  }
}
