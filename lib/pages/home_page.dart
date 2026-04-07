import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../controllers/progress_controller.dart';
import '../controllers/settings_controller.dart';
import '../services/prompt_service.dart';
import 'call_page.dart';
import 'vocab_page.dart';
import 'progress_page.dart';
import 'settings_page.dart';

// ============================================================
// 首页 — 风格一：深海军蓝 + 橙色，模式选择 + 进度概览
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HomeTab(),
    VocabPage(),
    ProgressPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressController>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: '词汇本',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: '我的进度',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 首页标签内容
// ============================================================

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(child: _buildWelcomeCard(context)),
          SliverToBoxAdapter(child: _buildLevelProgress(context)),
          SliverToBoxAdapter(child: _buildModeSectionTitle()),
          SliverToBoxAdapter(child: _buildModeCards(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppTheme.bgDark,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('S', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Spanish Voice Tutor'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.bgCardLight, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Hola! 开始今天的学习',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Consumer<ProgressController>(
                  builder: (_, ctrl, __) => Text(
                    '已学习 ${ctrl.vocabCount} 个词汇 · ${ctrl.totalStudyFormatted}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ApiKeyWarning(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // AI 老师头像
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
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
    );
  }

  Widget _buildLevelProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('课程进度', style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 12),
          Consumer<ProgressController>(
            builder: (_, ctrl, __) => Row(
              children: [
                _LevelProgressCard(
                  level: 'A1',
                  label: '入门级',
                  progress: ctrl.getLevelProgress('A1'),
                  color: AppTheme.levelA1,
                ),
                const SizedBox(width: 10),
                _LevelProgressCard(
                  level: 'A2',
                  label: '初级',
                  progress: ctrl.getLevelProgress('A2'),
                  color: AppTheme.levelA2,
                ),
                const SizedBox(width: 10),
                _LevelProgressCard(
                  level: 'B1',
                  label: '中级',
                  progress: ctrl.getLevelProgress('B1'),
                  color: AppTheme.levelB1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSectionTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text('选择学习模式', style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      )),
    );
  }

  Widget _buildModeCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _ModeCard(
            icon: Icons.school_outlined,
            title: '教学模式',
            subtitle: 'AI 老师带你系统学习西班牙语',
            gradient: const [Color(0xFF1E3A5F), Color(0xFF243447)],
            accentColor: AppTheme.primary,
            onTap: () => _startCall(context, mode: 'teacher'),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.chat_bubble_outline,
            title: '自由对话',
            subtitle: '模拟真实场景，自由练习口语',
            gradient: const [Color(0xFF1A3B2E), Color(0xFF243447)],
            accentColor: AppTheme.accent,
            onTap: () => _startCall(context, mode: 'freetalk'),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.quiz_outlined,
            title: '测验模式',
            subtitle: '翻译、听说、造句全方位测验',
            gradient: const [Color(0xFF3B1A2E), Color(0xFF243447)],
            accentColor: AppTheme.warning,
            onTap: () => _startCall(context, mode: 'quiz'),
          ),
        ],
      ),
    );
  }

  void _startCall(BuildContext context, {required String mode}) {
    final settingsCtrl = context.read<SettingsController>();
    if (!settingsCtrl.hasApiKey) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('需要设置 API Key',
              style: TextStyle(color: AppTheme.textPrimary)),
          content: const Text(
            '请先在设置中填写阿里云 DashScope API Key，才能开始语音对话。',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
              child: const Text('去设置'),
            ),
          ],
        ),
      );
      return;
    }

    final instructions = switch (mode) {
      'freetalk' => PromptService.freeTalk(level: 'A1'),
      'quiz' => PromptService.quiz(level: 'A1', unitName: '综合测验'),
      _ => PromptService.teacher(level: 'A1', unitName: '打招呼与自我介绍'),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          mode: mode,
          instructions: instructions,
        ),
      ),
    );
  }
}

// ============================================================
// 子组件
// ============================================================

class _ApiKeyWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (_, ctrl, __) {
        if (ctrl.hasApiKey) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsPage())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.warning_amber_outlined,
                    color: AppTheme.warning, size: 14),
                SizedBox(width: 6),
                Text('点击设置 API Key',
                    style: TextStyle(color: AppTheme.warning, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  final String level;
  final String label;
  final double progress;
  final Color color;

  const _LevelProgressCard({
    required this.level,
    required this.label,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(level,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.bgCardLight,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(progress * 100).toInt()}%',
                style: const TextStyle(
                    color: AppTheme.textHint, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bgCardLight),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: accentColor.withValues(alpha: 0.6), size: 16),
          ],
        ),
      ),
    );
  }
}
