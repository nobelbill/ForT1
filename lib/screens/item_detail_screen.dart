import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';
import '../widgets/food_card.dart';

/// 식품 상세 화면. 정보 확인 및 삭제(소진/폐기) 처리.
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('yyyy년 M월 d일 (E)', 'ko');

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Text(item.category.emoji,
                    style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text(item.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                DDayBadge(item: item),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _InfoTile(
            icon: Icons.event_busy_outlined,
            label: '유통기한',
            value: df.format(item.expiryDate),
          ),
          _InfoTile(
            icon: item.storage.icon,
            label: '보관 위치',
            value: item.storage.label,
          ),
          _InfoTile(
            icon: Icons.category_outlined,
            label: '분류',
            value: item.category.label,
          ),
          _InfoTile(
            icon: Icons.tag,
            label: '수량',
            value: '${item.quantity}개',
          ),
          _InfoTile(
            icon: Icons.event_available_outlined,
            label: '등록일',
            value: df.format(item.addedDate),
          ),
          if (item.barcode != null)
            _InfoTile(
              icon: Icons.qr_code,
              label: '바코드',
              value: item.barcode!,
            ),
          if (item.memo.isNotEmpty)
            _InfoTile(
              icon: Icons.sticky_note_2_outlined,
              label: '메모',
              value: item.memo,
            ),
          const SizedBox(height: 28),
          FilledButton.tonalIcon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('소진 / 삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
