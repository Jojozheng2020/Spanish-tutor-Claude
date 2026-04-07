import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../controllers/progress_controller.dart';
import '../models/vocabulary.dart';

// ============================================================
// 词汇本页面
// ============================================================

class VocabPage extends StatefulWidget {
  const VocabPage({super.key});

  @override
  State<VocabPage> createState() => _VocabPageState();
}

class _VocabPageState extends State<VocabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _levels = ['全部', 'A1', 'A2', 'B1'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _levels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          title: Consumer<ProgressController>(
            builder: (_, ctrl, __) => Text('词汇本 · ${ctrl.vocabCount} 个'),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: _levels.map((l) => Tab(text: l)).toList(),
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textHint,
          ),
        ),
        body: Consumer<ProgressController>(
          builder: (_, ctrl, __) {
            if (ctrl.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary));
            }
            return TabBarView(
              controller: _tabController,
              children: _levels.map((level) {
                final words = level == '全部'
                    ? ctrl.vocabulary
                    : ctrl.getVocabByLevel(level);
                return _VocabList(words: words, ctrl: ctrl);
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _VocabList extends StatelessWidget {
  final List<Vocabulary> words;
  final ProgressController ctrl;

  const _VocabList({required this.words, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, color: AppTheme.textHint, size: 56),
            SizedBox(height: 12),
            Text('暂无词汇', style: TextStyle(color: AppTheme.textSecondary)),
            SizedBox(height: 6),
            Text('开始对话学习后，词汇会自动收录到这里',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final w = words[i];
        return _VocabCard(vocab: w, ctrl: ctrl);
      },
    );
  }
}

class _VocabCard extends StatelessWidget {
  final Vocabulary vocab;
  final ProgressController ctrl;

  const _VocabCard({required this.vocab, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final levelColor = switch (vocab.level) {
      'A2' => AppTheme.levelA2,
      'B1' => AppTheme.levelB1,
      _ => AppTheme.levelA1,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      vocab.spanish,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vocab.level,
                        style: TextStyle(color: levelColor, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  vocab.chinese,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          // 熟悉度星星
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () {
                  if (vocab.id != null) ctrl.updateFamiliarity(vocab.id!, i + 1);
                },
                child: Icon(
                  i < vocab.familiarity ? Icons.star : Icons.star_outline,
                  color: i < vocab.familiarity
                      ? AppTheme.warning
                      : AppTheme.textHint,
                  size: 18,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
