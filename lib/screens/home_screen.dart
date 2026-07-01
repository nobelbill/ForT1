import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HapticFeedback.selectionClick();
    Navigator.of(context).push(_slideRoute(ItemDetailScreen(item: item)));
  }

  void _openAdd() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(_slideRoute(const AddItemScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FoodRepository>();
    final items = repo.byStorage(_filter);
    final hasAlert = repo.soonCount > 0 || repo.expiredCount > 0;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: FreshTokens.fab,
        foregroundColor: FreshTokens.onFab,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('식품 추가',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: repo.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: repo.load,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    pinned: true,
                    backgroundColor: FreshTokens.bg,
                    surfaceTintColor: Colors.transparent,
                    title: const Text('🌿  냉장고 지킴이',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20)),
                    actions: [
                      _BellAction(
                        hasAlert: hasAlert,
                        onTap: () => _showReminders(repo),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  if (repo.items.isNotEmpty)
                    SliverToBoxAdapter(child: _Stats(repo: repo)),
                  SliverToBoxAdapter(
                    child: _FilterBar(
                      selected: _filter,
                      onSelected: (f) {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f);
                      },
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
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _Entrance(
                          // 필터 전환 시에도 자연스럽게 다시 등장.
                          key: ValueKey('${_filter?.name}_${items[i].id}'),
                          index: i,
                          child: FoodCard(
                            item: items[i],
                            onTap: () => _openItem(items[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _showReminders(FoodRepository repo) {
    HapticFeedback.selectionClick();
    final urgent =
        repo.items.where((e) => e.status != FreshnessStatus.fresh).toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FreshTokens.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        _openItem(item);
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

/// 오른쪽에서 밀려들어오며 페이드되는 네이티브풍 화면 전환.
Route<T> _slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 리스트 아이템이 처음 나타날 때 살짝 떠오르며 페이드인.
class _Entrance extends StatefulWidget {
  const _Entrance({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _anim =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    // 인덱스에 따라 살짝씩 늦게 시작(스태거).
    Future<void>.delayed(
      Duration(milliseconds: 40 * (widget.index.clamp(0, 8))),
      () {
        if (mounted) _c.forward();
      },
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _anim.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _BellAction extends StatelessWidget {
  const _BellAction({required this.hasAlert, required this.onTap});
  final bool hasAlert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: FreshTokens.card,
        side: const BorderSide(color: FreshTokens.cardBorder),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 22, color: FreshTokens.text),
          if (hasAlert)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: FreshTokens.expFg,
                  shape: BoxShape.circle,
                  border: Border.all(color: FreshTokens.card, width: 1.5),
                ),
              ),
            ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: value),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Text('$v',
                  style: TextStyle(
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: fg)),
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? FreshTokens.chipActiveBg : FreshTokens.chipBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color:
                  active ? FreshTokens.chipActiveBg : FreshTokens.chipBorder),
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
