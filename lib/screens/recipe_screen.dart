import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';
import '../services/ai/ai_controller.dart';
import '../theme.dart';

/// 임박 식품으로 레시피를 추천하는 화면. 온디바이스 LLM(없으면 규칙기반)을 사용.
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  String _output = '';
  bool _running = false;
  StreamSubscription<String>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<FoodItem> _targetItems(FoodRepository repo) {
    final urgent = repo.items
        .where((e) => e.status != FreshnessStatus.fresh)
        .toList();
    if (urgent.isNotEmpty) return urgent.take(8).toList();
    return repo.items.take(5).toList(); // 임박 없으면 가장 가까운 것들
  }

  Future<void> _run() async {
    final repo = context.read<FoodRepository>();
    final ai = context.read<AiController>();
    final items = _targetItems(repo);

    await _sub?.cancel();
    setState(() {
      _output = '';
      _running = true;
    });

    _sub = ai.assistant.suggestRecipes(items).listen(
      (chunk) => setState(() => _output += chunk),
      onError: (_) => setState(() {
        _output += '\n\n추천 중 오류가 발생했어요.';
        _running = false;
      }),
      onDone: () => setState(() => _running = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FoodRepository>();
    final items = _targetItems(repo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 레시피 추천',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _RecipeInfoBanner(),
          const SizedBox(height: 16),
          const Text('이 재료로 만들어요',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: FreshTokens.text)),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('냉장고에 재료가 없어요. 먼저 식품을 추가해 주세요.',
                style: TextStyle(color: FreshTokens.sub))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: FreshTokens.accentSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${e.category.emoji} ${e.name}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: FreshTokens.accent)),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (items.isEmpty || _running) ? null : _run,
            icon: _running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_running ? '추천 생성 중...' : '레시피 추천 받기'),
          ),
          if (_output.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FreshTokens.card,
                borderRadius: BorderRadius.circular(FreshTokens.cardRadius),
                border: Border.all(color: FreshTokens.cardBorder),
                boxShadow: const [FreshTokens.cardShadow],
              ),
              child: Text(_output,
                  style: const TextStyle(
                      fontSize: 14.5, height: 1.6, color: FreshTokens.text)),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecipeInfoBanner extends StatelessWidget {
  const _RecipeInfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FreshTokens.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FreshTokens.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.tips_and_updates_outlined,
              size: 20, color: FreshTokens.accent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '임박한 재료로 만들 수 있는 요리를 제안해요. 오프라인에서 바로 동작합니다.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.5, color: FreshTokens.sub),
            ),
          ),
        ],
      ),
    );
  }
}
