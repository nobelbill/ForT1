import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';
import '../theme.dart';
import '../widgets/food_card.dart';

/// 식품 상세 화면. 정보 확인 및 삭제(소진/폐기) 처리.
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy년 M월 d일 (E)', 'ko');

    final tiles = <(String, String)>[
      ('유통기한', df.format(item.expiryDate)),
      ('보관 위치', item.storage.label),
      ('분류', item.category.label),
      ('수량', '${item.quantity}개'),
      ('등록일', df.format(item.addedDate)),
      if (item.barcode != null) ('바코드', item.barcode!),
      if (item.memo.isNotEmpty) ('메모', item.memo),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
        children: [
          Column(
            children: [
              Container(
                width: 98,
                height: 98,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FreshTokens.accentSoft,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(item.category.emoji,
                    style: const TextStyle(fontSize: 52)),
              ),
              const SizedBox(height: 12),
              Text(item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: FreshTokens.text)),
              const SizedBox(height: 12),
              DDayBadge(item: item, large: true),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              color: FreshTokens.card,
              borderRadius: BorderRadius.circular(FreshTokens.cardRadius),
              border: Border.all(color: FreshTokens.cardBorder),
              boxShadow: const [FreshTokens.cardShadow],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                for (var i = 0; i < tiles.length; i++)
                  _InfoRow(
                    label: tiles[i].$1,
                    value: tiles[i].$2,
                    showDivider: i != tiles.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SoftButton(
            label: '소진 / 삭제',
            icon: Icons.delete_outline,
            onTap: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FreshTokens.card,
        title: const Text('삭제할까요?'),
        content: Text('"${item.name}"을(를) 목록에서 제거합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<FoodRepository>().remove(item);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: FreshTokens.divider))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13.5, color: FreshTokens.sub)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: FreshTokens.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FreshTokens.accentSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: FreshTokens.accent),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: FreshTokens.accent)),
          ],
        ),
      ),
    );
  }
}
