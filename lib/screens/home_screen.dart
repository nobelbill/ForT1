import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';
import '../theme.dart';
import '../widgets/food_card.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StorageLocation? _filter;

  void _openItem(FoodItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FoodRepository>();
    final items = repo.byStorage(_filter);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddItemScreen()),
        ),
        backgroundColor: FreshTokens.fab,
        foregroundColor: FreshTokens.onFab,
        elevation: 6,
        icon: const Icon(Icons.add, weight: 700),
        label: const Text('식품 추가',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        bottom: false,
        child: repo.loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: repo.load,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _Header(repo: repo)),
                    if (repo.items.isNotEmpty)
                      SliverToBoxAdapter(child: _Stats(repo: repo)),
                    SliverToBoxAdapter(
                      child: _FilterBar(
                        selected: _filter,
                        onSelected: (f) => setState(() => _filter = f),
                      ),
                    ),
                    if (items.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                        sliver: SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => FoodCard(
                            item: items[i],
                            onTap: () => _openItem(items[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.repo});
  final FoodRepository repo;

  @override
  Widget build(BuildContext context) {
    final hasAlert = repo.soonCount > 0 || repo.expiredCount > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 16, 6),
      child: Row(
        children: [
          const Text(FreshTokens.appEmoji, style: TextStyle(fontSize: 22)),
          const SizedBox(width: 9),
          const Text(
            '냉장고 지킴이',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              letterSpacing: -0.4,
              color: FreshTokens.text,
            ),
          ),
          const Spacer(),
          _BellButton(
            hasAlert: hasAlert,
            onTap: () => _showReminders(context, repo),
          ),
        ],
      ),
    );
  }

  void _showReminders(BuildContext context, FoodRepository repo) {
    final urgent = repo.items
        .where((e) => e.status != FreshnessStatus.fresh)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FreshTokens.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text('유통기한 알림',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: FreshTokens.text)),
            ),
            if (urgent.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 4, 16),
                child: Text('임박하거나 만료된 식품이 없어요. 👍',
                    style: TextStyle(color: FreshTokens.sub)),
              )
            else
              ...urgent.take(6).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FoodCard(
                      item: item,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ItemDetailScreen(item: item),
                        ));
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.hasAlert, required this.onTap});
  final bool hasAlert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: FreshTokens.card,
          shape: BoxShape.circle,
          border: Border.all(color: FreshTokens.cardBorder),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded,
                size: 22, color: FreshTokens.text),
            if (hasAlert)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: FreshTokens.expFg,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.repo});
  final FoodRepository repo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _StatCard(
            label: '전체',
            value: repo.items.length,
            bg: FreshTokens.accentSoft,
            fg: FreshTokens.accent,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: '임박',
            value: repo.soonCount,
            bg: FreshTokens.soonBg,
            fg: FreshTokens.soonFg,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: '만료',
            value: repo.expiredCount,
            bg: FreshTokens.expBg,
            fg: FreshTokens.expFg,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });
  final String label;
  final int value;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: fg)),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FreshTokens.sub)),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});
  final StorageLocation? selected;
  final ValueChanged<StorageLocation?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _Chip(
            label: '전체',
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final s in StorageLocation.values) ...[
            const SizedBox(width: 8),
            _Chip(
              label: s.label,
              active: selected == s,
              onTap: () => onSelected(s),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: active ? FreshTokens.chipActiveBg : FreshTokens.chipBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FreshTokens.chipBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? FreshTokens.chipActiveFg : FreshTokens.chipFg,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, 40, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🧊', style: TextStyle(fontSize: 62)),
            SizedBox(height: 11),
            Text('여기엔 아직 없어요',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: FreshTokens.text)),
            SizedBox(height: 8),
            Text(
              '+ 식품 추가 버튼으로 등록해 보세요.\n바코드나 유통기한 촬영으로 빠르게 등록돼요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, height: 1.65, color: FreshTokens.sub),
            ),
          ],
        ),
      ),
    );
  }
}
