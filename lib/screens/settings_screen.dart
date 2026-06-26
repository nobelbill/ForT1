import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dev_seed.dart';
import '../data/food_repository.dart';
import '../services/ai/ai_controller.dart';
import '../theme.dart';

/// 설정 탭: AI 모델 관리, 데이터, 앱 정보.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiController>();
    final repo = context.watch<FoodRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionLabel('AI 도우미'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(ai.modelReady ? Icons.bolt : Icons.psychology_outlined,
                        color: FreshTokens.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ai.modelReady ? '온디바이스 AI 켜짐' : '기본 추천 모드',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: FreshTokens.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ai.modelReady
                      ? '기기 안에서 직접 추론해요. 인터넷·서버 없이 동작합니다.'
                      : '모델을 설치하면 재료 맞춤 레시피와 더 똑똑한 자연어 입력을 사용할 수 있어요.',
                  style: const TextStyle(
                      fontSize: 13, height: 1.5, color: FreshTokens.sub),
                ),
                if (!ai.modelReady) ...[
                  const SizedBox(height: 14),
                  if (ai.status == AiStatus.downloading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text('다운로드 중... ${ai.progress}%',
                            style: const TextStyle(
                                fontSize: 13, color: FreshTokens.sub)),
                      ],
                    )
                  else if (ai.canDownload)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.read<AiController>().downloadAndLoad(),
                        icon: const Icon(Icons.download),
                        label: const Text('AI 모델 설치'),
                      ),
                    )
                  else
                    const Text(
                      '개발 설정: --dart-define=GEMMA_MODEL_URL 로 모델을 지정하세요.',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: FreshTokens.faint),
                    ),
                  if (ai.status == AiStatus.error && ai.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('오류: ${ai.error}',
                          style: const TextStyle(
                              fontSize: 12, color: FreshTokens.expFg)),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('데이터'),
          _Card(
            child: Column(
              children: [
                _Tile(
                  icon: Icons.inventory_2_outlined,
                  title: '보관 중인 식품',
                  trailing: '${repo.items.length}개',
                ),
                if (kDebugMode) ...[
                  const Divider(height: 20),
                  _ActionTile(
                    icon: Icons.refresh,
                    title: '샘플 데이터 다시 넣기',
                    subtitle: '개발용 데모 데이터를 추가합니다',
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await seedSampleData(context.read<FoodRepository>());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('샘플 데이터를 추가했어요.')),
                        );
                      }
                    },
                  ),
                ],
                const Divider(height: 20),
                _ActionTile(
                  icon: Icons.delete_sweep_outlined,
                  title: '전체 삭제',
                  subtitle: '모든 식품 기록을 지웁니다',
                  danger: true,
                  onTap: () => _confirmClearAll(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('정보'),
          _Card(
            child: Column(
              children: const [
                _Tile(
                  icon: Icons.lock_outline,
                  title: '저장 방식',
                  trailing: '100% 로컬',
                ),
                Divider(height: 20),
                _Tile(
                  icon: Icons.info_outline,
                  title: '냉장고 지킴이',
                  trailing: 'v1.0',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FreshTokens.card,
        title: const Text('전체 삭제할까요?'),
        content: const Text('모든 식품 기록이 삭제됩니다. 되돌릴 수 없어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: FreshTokens.expFg),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final repo = context.read<FoodRepository>();
    for (final item in repo.items.toList()) {
      await repo.remove(item);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: FreshTokens.sub)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FreshTokens.card,
        borderRadius: BorderRadius.circular(FreshTokens.cardRadius),
        border: Border.all(color: FreshTokens.cardBorder),
        boxShadow: const [FreshTokens.cardShadow],
      ),
      child: child,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, this.trailing});
  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FreshTokens.sub),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: FreshTokens.text)),
        ),
        if (trailing != null)
          Text(trailing!,
              style: const TextStyle(fontSize: 14, color: FreshTokens.sub)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? FreshTokens.expFg : FreshTokens.text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? FreshTokens.expFg : FreshTokens.sub),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: FreshTokens.faint)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FreshTokens.faint),
          ],
        ),
      ),
    );
  }
}
