import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../controllers/settings_controller.dart';

// ============================================================
// 设置页面 — API Key 配置、音色选择、连接测试
// ============================================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

// 连接测试状态
enum _TestState { idle, testing, success, failed }

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  bool _showApiKey = false;
  _TestState _testState = _TestState.idle;
  String _testMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<SettingsController>();
      _apiKeyController.text = ctrl.apiKey;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  // ============================================================
  // 测试 API Key 连通性（发送一个轻量 HTTP 请求）
  // 使用 DashScope 文本模型 API 做简单验证，Web 端也可正常发起
  // ============================================================
  Future<void> _testConnection(SettingsController ctrl) async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      _showSnackBar('请先输入 API Key', isError: true);
      return;
    }
    if (!key.startsWith('sk-')) {
      _showSnackBar('API Key 格式不正确，应以 sk- 开头', isError: true);
      return;
    }

    setState(() {
      _testState = _TestState.testing;
      _testMessage = '正在连接阿里云服务器…';
    });

    try {
      // 使用 DashScope 文本生成 API 做轻量验证
      // 只发一个极短请求，费用可忽略（< 0.001 元）
      final useIntl = ctrl.useIntlEndpoint;
      final baseHost = useIntl
          ? 'dashscope-intl.aliyuncs.com'
          : 'dashscope.aliyuncs.com';
      final uri = Uri.parse('https://$baseHost/api/v1/services/aigc/text-generation/generation');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'qwen-turbo',
          'input': {
            'messages': [
              {'role': 'user', 'content': 'hi'}
            ]
          },
          'parameters': {'max_tokens': 1}
        }),
      ).timeout(const Duration(seconds: 12));

      if (!mounted) return;

      final code = response.statusCode;
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (code == 200) {
        setState(() {
          _testState = _TestState.success;
          _testMessage = '✅ 连接成功！API Key 有效，模型响应正常';
        });
        // 同时自动保存
        await ctrl.saveApiKey(key);
      } else if (code == 401) {
        setState(() {
          _testState = _TestState.failed;
          _testMessage = '❌ API Key 无效或已过期，请重新获取';
        });
      } else if (code == 403) {
        setState(() {
          _testState = _TestState.failed;
          _testMessage = '❌ 无权限：请确认已开通百炼大模型服务';
        });
      } else if (code == 429) {
        // 429 说明 Key 是有效的，只是触发了限速
        setState(() {
          _testState = _TestState.success;
          _testMessage = '✅ API Key 有效（已触发限速，稍后正常使用）';
        });
        await ctrl.saveApiKey(key);
      } else {
        final errMsg = body['message'] ?? body['error']?['message'] ?? 'code $code';
        setState(() {
          _testState = _TestState.failed;
          _testMessage = '❌ 请求失败：$errMsg';
        });
      }
    } on http.ClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _testState = _TestState.failed;
        _testMessage = '❌ 网络错误：${e.message}\n（请检查网络连接或尝试切换端点）';
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('TimeoutException') || msg.contains('timed out')) {
        setState(() {
          _testState = _TestState.failed;
          _testMessage = '❌ 连接超时：网络不可达\n中国大陆请关闭"国际端点"；海外请开启';
        });
      } else {
        setState(() {
          _testState = _TestState.failed;
          _testMessage = '❌ 未知错误：$msg';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsController>(
        builder: (_, ctrl, __) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // API Key 配置
              _SectionTitle(title: 'API 配置'),
              const SizedBox(height: 8),
              _buildApiKeyCard(ctrl),
              const SizedBox(height: 8),

              // 连接测试结果卡片（始终显示）
              _buildTestResultCard(),
              const SizedBox(height: 20),

              // 音色选择
              _SectionTitle(title: '音色选择'),
              const SizedBox(height: 8),
              _buildVoiceCard(ctrl),
              const SizedBox(height: 20),

              // 端点配置
              _SectionTitle(title: '连接设置'),
              const SizedBox(height: 8),
              _buildEndpointCard(ctrl),
              const SizedBox(height: 20),

              // 说明
              _buildHelpCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApiKeyCard(SettingsController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_outlined, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              const Text('DashScope API Key',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (ctrl.hasApiKey)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('已设置',
                      style: TextStyle(color: AppTheme.success, fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: !_showApiKey,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            onChanged: (_) {
              // 输入变化后重置测试状态
              if (_testState != _TestState.idle) {
                setState(() => _testState = _TestState.idle);
              }
            },
            decoration: InputDecoration(
              hintText: 'sk-xxxxxxxxxxxxxxxx',
              suffixIcon: IconButton(
                icon: Icon(
                  _showApiKey ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _showApiKey = !_showApiKey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 保存按钮
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final key = _apiKeyController.text.trim();
                    if (key.isEmpty) {
                      _showSnackBar('请输入 API Key', isError: true);
                      return;
                    }
                    if (!key.startsWith('sk-')) {
                      _showSnackBar('API Key 格式不正确，应以 sk- 开头', isError: true);
                      return;
                    }
                    await ctrl.saveApiKey(key);
                    _showSnackBar('API Key 已保存');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.bgCardLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('保存'),
                ),
              ),
              const SizedBox(width: 10),
              // 测试连接按钮
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _testState == _TestState.testing
                      ? null
                      : () => _testConnection(ctrl),
                  icon: _testState == _TestState.testing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _testState == _TestState.success
                              ? Icons.check_circle_outline
                              : _testState == _TestState.failed
                                  ? Icons.error_outline
                                  : Icons.wifi_tethering,
                          size: 16,
                        ),
                  label: Text(
                    _testState == _TestState.testing
                        ? '测试中…'
                        : _testState == _TestState.success
                            ? '测试通过'
                            : _testState == _TestState.failed
                                ? '测试失败'
                                : '测试连接',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _testState == _TestState.success
                        ? AppTheme.success
                        : _testState == _TestState.failed
                            ? AppTheme.error
                            : AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 测试结果详情卡片
  Widget _buildTestResultCard() {
    if (_testState == _TestState.idle) return const SizedBox.shrink();

    final isSuccess = _testState == _TestState.success;
    final isTesting = _testState == _TestState.testing;
    final color = isTesting
        ? AppTheme.warning
        : isSuccess
            ? AppTheme.success
            : AppTheme.error;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isTesting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(
                  isSuccess ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 16,
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isTesting ? '正在连接阿里云服务器，请稍候…' : _testMessage,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCard(SettingsController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.record_voice_over_outlined, color: AppTheme.accent, size: 18),
              SizedBox(width: 8),
              Text('AI 老师音色',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.availableVoices.map((voice) {
              final selected = ctrl.voice == voice;
              return GestureDetector(
                onTap: () => ctrl.saveVoice(voice),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.accent.withValues(alpha: 0.2)
                        : AppTheme.bgCardLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppTheme.accent
                          : AppTheme.bgCardLight,
                    ),
                  ),
                  child: Text(
                    voice,
                    style: TextStyle(
                      color: selected ? AppTheme.accent : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointCard(SettingsController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.language, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('使用国际端点（新加坡）',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                Text('中国大陆请关闭 · 海外用户可开启',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: ctrl.useIntlEndpoint,
            onChanged: (v) {
              ctrl.saveUseIntlEndpoint(v);
              // 切换端点后重置测试状态
              setState(() => _testState = _TestState.idle);
            },
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgCardLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.help_outline, color: AppTheme.textSecondary, size: 16),
              SizedBox(width: 8),
              Text('如何获取 API Key？',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '1. 访问 https://dashscope.aliyuncs.com\n'
            '2. 注册/登录阿里云账号\n'
            '3. 开通百炼大模型服务\n'
            '4. 在「API Key 管理」中创建 Key\n'
            '5. 复制 sk- 开头的 Key 填写到上方\n'
            '6. 点击「测试连接」验证是否可用',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.6),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
