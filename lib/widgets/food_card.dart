import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../theme.dart';

/// 식품 한 건을 보여주는 카드. 유통기한 D-day를 색으로 강조한다.
class FoodCard extends StatelessWidget {
  const FoodCard({super.key, required this.item, this.onTap});

  final FoodItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = '${item.storage.label} · ${item.category.label}'
        '${item.quantity > 1 ? ' · ${item.quantity}개' : ''}';

    return Material(
      color: FreshTokens.card,
      borderRadius: BorderRadius.circular(FreshTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FreshTokens.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: FreshTokens.card,
            borderRadius: BorderRadius.circular(FreshTokens.cardRadius),
            border: Border.all(color: FreshTokens.cardBorder),
            boxShadow: const [FreshTokens.cardShadow],
          ),
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              _EmojiTile(emoji: item.category.emoji),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: FreshTokens.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: FreshTokens.sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              DDayBadge(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FreshTokens.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 25)),
    );
  }
}

/// 남은 일수를 색상 배지로 표현.
class DDayBadge extends StatelessWidget {
  const DDayBadge({super.key, required this.item, this.large = false});

  final FoodItem item;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = FreshTokens.badgeColors(item.status);
    final d = item.daysLeft;
    final text = switch (item.status) {
      FreshnessStatus.expired => d == -1 ? '하루 지남' : '${-d}일 지남',
      FreshnessStatus.soon => d == 0 ? '오늘까지' : 'D-$d',
      FreshnessStatus.fresh => 'D-$d',
    };

    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(large ? 13 : 11),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: large ? 15 : 12.5,
        ),
      ),
    );
  }
}
