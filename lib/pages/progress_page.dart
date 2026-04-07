import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../controllers/progress_controller.dart';
import '../models/session_history.dart';

// ============================================================
// 学习进度页面
// ============================================================

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(title: const Text('我的进度')),
        body: Consumer<ProgressController>(
          builder: (_, ctrl, __) {
            if (ctrl.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary));
            }
            return RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.bgCard,
              onRefresh: ctrl.loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsRow(ctrl),
                  const SizedBox(height: 20),
                  _buildLevelSection(context, ctrl, 'A1', '入门级', AppTheme.levelA1),
                  const SizedBox(height: 12),
                  _buildLevelSection(context, ctrl, 'A2', '初级', AppTheme.levelA2),
                  const SizedBox(height: 12),
                  _buildLevelSection(context, ctrl, 'B1', '中级', AppTheme.levelB1),
                  const SizedBox(height: 20),
                  _buildRecentSessions(ctrl),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(ProgressController ctrl) {
    return Row(
      children: [
        _StatCard(
          label: '学习时长',
          value: ctrl.totalStudyFormatted,
          icon: Icons.timer_outlined,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: '完成单元',
          value: '${ctrl.completedUnitsTotal}',
          icon: Icons.check_circle_outline,
          color: AppTheme.accent,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: '已学词汇',
          value: '${ctrl.vocabCount}',
          icon: Icons.menu_book_outlined,
          color: AppTheme.warning,
        ),
      ],
    );
  }

  Widget _buildLevelSection(BuildContext context, ProgressController ctrl,
      String level, String label, Color color) {
    final progress = ctrl.getLevelProgress(level);
    final completed = ctrl.completedByLevel[level] ?? 0;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(level,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              const Spacer(),
              Text('$completed / 10 单元',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.bgCardLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(progress * 100).toInt()}% 完成',
              style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(ProgressController ctrl) {
    if (ctrl.recentSessions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最近学习记录',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...ctrl.recentSessions.take(5).map((s) => _SessionItem(session: s)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textHint, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  final SessionHistory session;

  const _SessionItem({required this.session});

  String get _modeLabel => switch (session.mode) {
        'freetalk' => '自由对话',
        'quiz' => '测验模式',
        _ => '教学模式',
      };

  Color get _modeColor => switch (session.mode) {
        'freetalk' => AppTheme.accent,
        'quiz' => AppTheme.warning,
        _ => AppTheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _modeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              switch (session.mode) {
                'freetalk' => Icons.chat_bubble_outline,
                'quiz' => Icons.quiz_outlined,
                _ => Icons.school_outlined,
              },
              color: _modeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_modeLabel,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(
                  session.level != null
                      ? '${session.level} · ${session.formattedDuration}'
                      : session.formattedDuration,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(session.createdAt),
            style: const TextStyle(color: AppTheme.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
