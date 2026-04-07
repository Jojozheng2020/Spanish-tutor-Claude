import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../controllers/call_controller.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/chat_bubble.dart';

// ============================================================
// 通话页面 — 实时语音对话，中西双语字幕
// ============================================================

class CallPage extends StatefulWidget {
  final String mode;
  final String instructions;
  final String? level;
  final String? unitId;
  final String? unitName;

  const CallPage({
    super.key,
    required this.mode,
    required this.instructions,
    this.level,
    this.unitId,
    this.unitName,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late CallController _callController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _callController = CallController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCall();
    });
  }

  Future<void> _startCall() async {
    _callController.addListener(_onCallUpdate);
    // Web 预览平台：不连接真实 WebSocket，直接展示说明
    if (kIsWeb) {
      _callController.setWebPreviewMode();
      return;
    }
    await _callController.startCall(
      instructions: widget.instructions,
      mode: widget.mode,
      level: widget.level,
      unitId: widget.unitId,
    );
  }

  void _onCallUpdate() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _callController.removeListener(_onCallUpdate);
    _callController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _modeLabel => switch (widget.mode) {
        'freetalk' => '自由对话',
        'quiz' => '测验模式',
        _ => '教学模式',
      };

  Color get _modeColor => switch (widget.mode) {
        'freetalk' => AppTheme.accent,
        'quiz' => AppTheme.warning,
        _ => AppTheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    // Web 平台直接显示说明页，完全不渲染通话 UI
    if (kIsWeb) return _buildWebPreviewPage(context);

    return ChangeNotifierProvider.value(
      value: _callController,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          backgroundColor: AppTheme.bgDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textSecondary, size: 20),
            onPressed: _confirmEnd,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _modeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _modeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _modeLabel,
                  style: TextStyle(color: _modeColor, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 10),
              Consumer<CallController>(
                builder: (_, ctrl, __) => Text(
                  _formatDuration(ctrl.elapsedSeconds),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
          actions: [
            Consumer<CallController>(
              builder: (_, ctrl, __) => _StatusIndicator(state: ctrl.state),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // AI 头像 + 状态区
            _buildAiSection(),
            // 字幕列表
            Expanded(child: _buildSubtitleList()),
            // 底部控制区
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSection() {
    return Consumer<CallController>(
      builder: (_, ctrl, __) {
        final isActive = ctrl.state == CallState.active;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              // AI 头像
              Stack(
                alignment: Alignment.center,
                children: [
                  // 外层光晕
                  if (ctrl.isAiThinking)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _modeColor.withValues(alpha: 0.1),
                      ),
                    ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_modeColor, _modeColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _modeColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Profe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 状态文字
              Text(
                _getStatusText(ctrl),
                style: TextStyle(
                  color: ctrl.isAiThinking ? _modeColor : AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              // 波形
              AudioVisualizer(
                isActive: isActive && (ctrl.isSpeaking || ctrl.isAiThinking),
                color: _modeColor,
                height: 36,
                barCount: 24,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubtitleList() {
    return Consumer<CallController>(
      builder: (_, ctrl, __) {
        if (ctrl.state == CallState.error) {
          final isWebPreview = ctrl.errorMessage.contains('Web 预览模式');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isWebPreview
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : AppTheme.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWebPreview ? Icons.phone_android : Icons.error_outline,
                      color: isWebPreview ? AppTheme.primary : AppTheme.error,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ctrl.errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('返回首页'),
                  ),
                ],
              ),
            ),
          );
        }

        if (ctrl.state == CallState.connecting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 16),
                Text('正在连接 AI 老师...', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        final subtitles = ctrl.subtitles;
        final streamText = ctrl.streamingAiText;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: subtitles.length + (streamText.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == subtitles.length && streamText.isNotEmpty) {
              return StreamingBubble(text: streamText);
            }
            return ChatBubble(segment: subtitles[index]);
          },
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Consumer<CallController>(
      builder: (_, ctrl, __) {
        final isActive = ctrl.state == CallState.active;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: AppTheme.bgMedium,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 用户状态指示
              if (isActive && ctrl.isSpeaking)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('正在聆听...', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 结束通话按钮
                  GestureDetector(
                    onTap: _confirmEnd,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.error.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '对话进行中 · 直接说话即可',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(CallController ctrl) {
    return switch (ctrl.state) {
      CallState.connecting => '连接中...',
      CallState.active => ctrl.isSpeaking
          ? '正在聆听你的发音...'
          : ctrl.isAiThinking
              ? 'Profe 正在思考...'
              : '等待你开口说话',
      CallState.error => '连接出错',
      CallState.idle => '通话结束',
    };
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // Web 预览专用页面（完全独立，不使用任何原生 API）
  // =========================================================
  Widget _buildWebPreviewPage(BuildContext context) {
    final modeLabel = switch (widget.mode) {
      'freetalk' => '自由对话',
      'quiz' => '测验模式',
      _ => '教学模式',
    };
    final modeColor = switch (widget.mode) {
      'freetalk' => AppTheme.accent,
      'quiz' => AppTheme.warning,
      _ => AppTheme.primary,
    };

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: modeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: modeColor.withValues(alpha: 0.3)),
          ),
          child: Text(modeLabel,
              style: TextStyle(
                  color: modeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 手机图标
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        modeColor,
                        modeColor.withValues(alpha: 0.6)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: modeColor.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.phone_android,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Web 预览模式',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '语音对话功能需要在 Android 手机上运行\n请下载 APK 安装后体验完整功能',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 28),
                // 功能特性列表
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📱 Android 完整功能',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._featureItems([
                        ('mic', AppTheme.primary, '实时语音录制与识别'),
                        ('volume_up', AppTheme.accent, 'AI 西班牙语语音播放'),
                        ('subtitles', AppTheme.warning, '中西双语实时字幕'),
                        ('record_voice_over', AppTheme.levelB1, '发音纠正与评分'),
                        ('psychology', AppTheme.levelA2, 'VAD 智能断句检测'),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌐 Web 预览可体验',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._featureItems([
                        ('home', AppTheme.primary, '首页 · 模式选择'),
                        ('menu_book', AppTheme.accent, '词汇本 · 熟悉度管理'),
                        ('bar_chart', AppTheme.levelA1, '学习进度 · 统计数据'),
                        ('settings', AppTheme.textSecondary, '设置页 · API Key 配置'),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('返回首页继续预览'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _featureItems(List<(String, Color, String)> items) {
    return items.map((item) {
      final (iconName, color, label) = item;
      final iconData = switch (iconName) {
        'mic' => Icons.mic,
        'volume_up' => Icons.volume_up,
        'subtitles' => Icons.subtitles,
        'record_voice_over' => Icons.record_voice_over,
        'psychology' => Icons.psychology,
        'home' => Icons.home_outlined,
        'menu_book' => Icons.menu_book_outlined,
        'bar_chart' => Icons.bar_chart,
        'settings' => Icons.settings_outlined,
        _ => Icons.check_circle_outline,
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _confirmEnd() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('结束对话', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          '确定要结束本次学习对话吗？对话记录将自动保存。',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续学习'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('结束'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _callController.endCall();
      if (mounted) Navigator.pop(context);
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  final CallState state;

  const _StatusIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      CallState.connecting => (AppTheme.warning, '连接中'),
      CallState.active => (AppTheme.success, '通话中'),
      CallState.error => (AppTheme.error, '错误'),
      CallState.idle => (AppTheme.textHint, '空闲'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
