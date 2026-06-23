import 'package:flutter/foundation.dart';

import '../models/food_item.dart';
import '../services/notification_service.dart';
import 'food_database.dart';

/// 식품 목록의 단일 진실 공급원. 추가/삭제 시 알림 예약도 함께 처리한다.
class FoodRepository extends ChangeNotifier {
  FoodRepository(this._db, this._notifications);

  final FoodDatabase _db;
  final NotificationService _notifications;

  List<FoodItem> _items = [];
  bool _loading = true;

  /// 유통기한 임박순으로 정렬된 전체 목록.
  List<FoodItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _db.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<void> add(FoodItem item) async {
    final saved = await _db.insert(item);
    _items = [..._items, saved]..sort(_byExpiry);
    notifyListeners();
    await _notifications.scheduleForItem(saved);
  }

  Future<void> update(FoodItem item) async {
    await _db.update(item);
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx != -1) _items[idx] = item;
    _items.sort(_byExpiry);
    notifyListeners();
    if (item.id != null) {
      await _notifications.cancelForItem(item.id!);
      await _notifications.scheduleForItem(item);
    }
  }

  Future<void> remove(FoodItem item) async {
    if (item.id == null) return;
    await _db.delete(item.id!);
    _items.removeWhere((e) => e.id == item.id);
    notifyListeners();
    await _notifications.cancelForItem(item.id!);
  }

  /// 위치 필터를 적용한 목록.
  List<FoodItem> byStorage(StorageLocation? storage) {
    if (storage == null) return items;
    return _items.where((e) => e.storage == storage).toList();
  }

  int get expiredCount =>
      _items.where((e) => e.status == FreshnessStatus.expired).length;

  int get soonCount =>
      _items.where((e) => e.status == FreshnessStatus.soon).length;

  static int _byExpiry(FoodItem a, FoodItem b) =>
      a.expiryDate.compareTo(b.expiryDate);
}
