import 'package:flutter/material.dart';

import '../models/food_item.dart';

/// 식품 한 건을 보여주는 카드. 유통기한 D-day를 색으로 강조한다.
class FoodCard extends StatelessWidget {
  const FoodCard({super.key, required this.item, this.onTap});

  final FoodItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(item.category.emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(item.storage.icon,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${item.storage.label} · ${item.category.label}'
                          '${item.quantity > 1 ? ' · ${item.quantity}개' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DDayBadge(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

/// 남은 일수를 색상 배지로 표현.
class DDayBadge extends StatelessWidget {
  const DDayBadge({super.key, required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final d = item.daysLeft;
    final (Color bg, Color fg, String text) = switch (item.status) {
      FreshnessStatus.expired => (
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          d == -1 ? '하루 지남' : '${-d}일 지남',
        ),
      FreshnessStatus.soon => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          d == 0 ? '오늘까지' : 'D-$d',
        ),
      FreshnessStatus.fresh => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          'D-$d',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
