import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/realtime_service.dart';
import '../services/audio_service.dart';
import '../services/db_service.dart';
import '../services/settings_service.dart';
import '../models/session_history.dart';

// ============================================================
// CallController — 通话状态管理
//
// 修复列表（基于文档审查报告）：
//  1. 修复多段字幕解析：正确处理一次 AI 回复中多对 [ES][ZH] 标签
//  2. API Key 通过 SettingsService 注入，不硬编码
//  3. 会话结束后自动保存历史记录
// ============================================================

enum CallState { idle, connecting, active, error }

class SubtitleSegment {
  final String spanish;
  final String chinese;
  final bool isUser; // true=用户, false=AI

  const SubtitleSegment({
    required this.spanish,
    required this.chinese,
    this.isUser = false,
  });
}

class CallController extends ChangeNotifier {
  final RealtimeService _realtime = RealtimeService();
  final AudioService _audio = AudioService();
  final DbService _db = DbService();
  final SettingsService _settings = SettingsService();

  CallState _state = CallState.idle;
  String _errorMessage = '';
  String _mode = 'teacher';
  String? _level;
  String? _unitId;

  // ---- 字幕 ----
  final List<SubtitleSegment> _subtitles = [];

  // ---- 当前流式积累 ----
  String _streamingAiText = '';

  // ---- 用于解析标签的正则 ----
  static final RegExp _esTagRx = RegExp(r'\[ES\](.*?)\[/ES\]', dotAll: true);
  static final RegExp _zhTagRx = RegExp(r'\[ZH\](.*?)\[/ZH\]', dotAll: true);

  // ---- 计时 ----
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  // ---- 语音状态 ----
  bool _isSpeaking = false; // VAD 检测到用户正在说话
  bool _isAiThinking = false; // 用户停止说话，等待 AI 回复

  // ---- Getters ----
  CallState get state => _state;
  String get errorMessage => _errorMessage;
  List<SubtitleSegment> get subtitles => List.unmodifiable(_subtitles);
  int get elapsedSeconds => _elapsedSeconds;
  bool get isSpeaking => _isSpeaking;
  bool get isAiThinking => _isAiThinking;
  String get streamingAiText => _streamingAiText;

  // =========================================================
  // 开始通话
  // =========================================================

  Future<void> startCall({
    required String instructions,
    required String mode,
    String? level,
    String? unitId,
  }) async {
    if (_state != CallState.idle) return;

    _mode = mode;
    _level = level;
    _unitId = unitId;
    _state = CallState.connecting;
    _subtitles.clear();
    _streamingAiText = '';
    _errorMessage = '';
    _isSpeaking = false;
    _isAiThinking = false;
    notifyListeners();

    // 初始化音频
    await _audio.init();

    // 注入 API Key、端点设置与音色
    final apiKey = await _settings.getApiKey();
    final useIntl = await _settings.getUseIntlEndpoint();
    final voice = await _settings.getVoice();
    _realtime.setApiKey(apiKey);
    _realtime.setUseIntlEndpoint(useIntl);
    _realtime.setVoice(voice);

    // 绑定事件回调
    _bindCallbacks();

    // 连接 WebSocket
    await _realtime.connect(instructions: instructions);

    // 开始录音
    _audio.onAudioChunk = (b64) => _realtime.sendAudio(b64);
    await _audio.startRecording();

    // 开始计时
    _elapsedSeconds = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });

    _state = CallState.active;
    notifyListeners();
  }

  void _bindCallbacks() {
    _realtime.onConnected = () {
      if (kDebugMode) debugPrint('[CallController] 已连接');
    };

    _realtime.onDisconnected = () {
      if (kDebugMode) debugPrint('[CallController] 断开连接');
    };

    // AI 音频流 → 播放
    _realtime.onAudioDelta = (pcm) => _audio.feedAudio(pcm);

    // AI 文字流 → 积累并解析字幕
    _realtime.onAiTranscriptDelta = (delta) {
      _streamingAiText += delta;
      notifyListeners();
    };

    // AI 完整文字 → 最终解析字幕
    _realtime.onAiTranscriptDone = (fullText) {
      _parseAndAddSubtitles(fullText, isUser: false);
      _streamingAiText = '';
      _isAiThinking = false;
      notifyListeners();
    };

    // 用户语音转录
    _realtime.onUserTranscript = (transcript) {
      if (transcript.trim().isNotEmpty) {
        _subtitles.add(SubtitleSegment(
          spanish: transcript,
          chinese: '',
          isUser: true,
        ));
        notifyListeners();
      }
    };

    // 本轮响应完成
    _realtime.onResponseDone = () {
      _isAiThinking = false;
      notifyListeners();
    };

    // VAD：用户开始说话
    _realtime.onSpeechStarted = () {
      _isSpeaking = true;
      _isAiThinking = false;
      // 打断 AI 播放
      _audio.stopPlayback();
      _realtime.cancelResponse();
      notifyListeners();
    };

    // VAD：用户停止说话
    _realtime.onSpeechStopped = () {
      _isSpeaking = false;
      _isAiThinking = true;
      notifyListeners();
    };

    // 错误
    _realtime.onError = (msg, code) {
      _errorMessage = msg;
      _state = CallState.error;
      notifyListeners();
    };
  }

  // =========================================================
  // 字幕解析（修复：正确处理多对标签）
  // =========================================================

  void _parseAndAddSubtitles(String text, {required bool isUser}) {
    if (isUser) {
      _subtitles.add(SubtitleSegment(spanish: text, chinese: '', isUser: true));
      return;
    }

    // 提取所有 [ES] 匹配
    final esMatches = _esTagRx.allMatches(text).toList();
    // 提取所有 [ZH] 匹配
    final zhMatches = _zhTagRx.allMatches(text).toList();

    final count =
        esMatches.length > zhMatches.length ? esMatches.length : zhMatches.length;

    if (count == 0) {
      // 没有标签，直接作为西班牙语文本显示
      if (text.trim().isNotEmpty) {
        _subtitles.add(SubtitleSegment(spanish: text.trim(), chinese: ''));
      }
      return;
    }

    // 修复：逐对匹配，防止多段字幕互相覆盖
    for (var i = 0; i < count; i++) {
      final es =
          i < esMatches.length ? (esMatches[i].group(1)?.trim() ?? '') : '';
      final zh =
          i < zhMatches.length ? (zhMatches[i].group(1)?.trim() ?? '') : '';
      if (es.isNotEmpty || zh.isNotEmpty) {
        _subtitles.add(SubtitleSegment(spanish: es, chinese: zh));
      }
    }
  }

  // =========================================================
  // 结束通话
  // =========================================================

  Future<void> endCall() async {
    if (_state == CallState.idle) return;

    _durationTimer?.cancel();
    _durationTimer = null;

    await _audio.stopRecording();
    await _audio.stopPlayback();
    await _realtime.disconnect();
    await _audio.dispose();

    // 保存会话历史
    final transcript = _subtitles
        .map((s) => s.isUser ? '学生: ${s.spanish}' : 'AI: ${s.spanish}')
        .join('\n');
    await _db.insertSession(SessionHistory(
      mode: _mode,
      level: _level,
      unitId: _unitId,
      durationSeconds: _elapsedSeconds,
      transcript: transcript,
      createdAt: DateTime.now().toIso8601String(),
    ));

    _state = CallState.idle;
    _subtitles.clear();
    _streamingAiText = '';
    _errorMessage = '';
    _isSpeaking = false;
    _isAiThinking = false;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  // =========================================================
  // 切换教学模式（修复：动态更新 instructions，重连时不丢失）
  // =========================================================

  void switchMode(String newInstructions) {
    _realtime.updateInstructions(newInstructions);
  }

  // =========================================================
  // Web 预览模式（仅展示 UI，不连接真实语音）
  // =========================================================
  void setWebPreviewMode() {
    _state = CallState.error;
    _errorMessage =
        'Web 预览模式\n\n真实语音功能需要在 Android 手机上运行\n\n'
        '📱 请下载 APK 安装到手机体验完整功能\n\n'
        '当前 Web 预览可查看：\n'
        '• 首页 / 词汇本 / 学习进度\n'
        '• 设置页面（填写 API Key）\n'
        '• 整体界面设计与交互';
    notifyListeners();
  }

  @override
  void dispose() {
    endCall();
    super.dispose();
  }
}
