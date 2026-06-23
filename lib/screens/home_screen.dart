import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';
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

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FoodRepository>();
    final items = repo.byStorage(_filter);

    return Scaffold(
      appBar: AppBar(
        title: const Text('냉장고 지킴이'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddItemScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('식품 추가'),
      ),
      body: repo.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: repo.load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _Summary(repo: repo)),
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return FoodCard(
                            item: item,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ItemDetailScreen(item: item),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.repo});
  final FoodRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = repo.items.length;
    if (total == 0) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _Stat(label: '전체', value: '$total', color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          _Stat(
            label: '임박',
            value: '${repo.soonCount}',
            color: const Color(0xFFE65100),
          ),
          const SizedBox(width: 10),
          _Stat(
            label: '만료',
            value: '${repo.expiredCount}',
            color: const Color(0xFFC62828),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelMedium),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('전체'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final s in StorageLocation.values) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: Icon(s.icon, size: 18),
              label: Text(s.label),
              selected: selected == s,
              onSelected: (_) => onSelected(s),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🧊', style: theme.textTheme.displayMedium),
          const SizedBox(height: 12),
          Text('냉장고가 비어 있어요',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '오른쪽 아래 버튼으로 식품을 추가해 보세요.\n바코드나 유통기한 촬영으로 빠르게 등록할 수 있어요.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
