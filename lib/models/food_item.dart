import 'package:flutter/material.dart';

/// 보관 위치.
enum StorageLocation {
  fridge,
  freezer,
  pantry;

  String get label => switch (this) {
        StorageLocation.fridge => '냉장',
        StorageLocation.freezer => '냉동',
        StorageLocation.pantry => '실온',
      };

  IconData get icon => switch (this) {
        StorageLocation.fridge => Icons.kitchen_outlined,
        StorageLocation.freezer => Icons.ac_unit,
        StorageLocation.pantry => Icons.shelves,
      };
}

/// 식품 분류.
enum FoodCategory {
  vegetable,
  fruit,
  meat,
  seafood,
  dairy,
  beverage,
  sauce,
  frozen,
  etc;

  String get label => switch (this) {
        FoodCategory.vegetable => '채소',
        FoodCategory.fruit => '과일',
        FoodCategory.meat => '육류',
        FoodCategory.seafood => '수산물',
        FoodCategory.dairy => '유제품',
        FoodCategory.beverage => '음료',
        FoodCategory.sauce => '양념',
        FoodCategory.frozen => '냉동식품',
        FoodCategory.etc => '기타',
      };

  String get emoji => switch (this) {
        FoodCategory.vegetable => '🥬',
        FoodCategory.fruit => '🍎',
        FoodCategory.meat => '🥩',
        FoodCategory.seafood => '🐟',
        FoodCategory.dairy => '🥛',
        FoodCategory.beverage => '🥤',
        FoodCategory.sauce => '🧂',
        FoodCategory.frozen => '🧊',
        FoodCategory.etc => '🛒',
      };
}

/// 유통기한 임박 상태.
enum FreshnessStatus { expired, soon, fresh }

/// 냉장고에 보관 중인 식품 한 건.
class FoodItem {
  final int? id;
  final String name;
  final FoodCategory category;
  final StorageLocation storage;

  /// 유통기한(날짜만 의미를 가진다).
  final DateTime expiryDate;
  final DateTime addedDate;
  final int quantity;
  final String memo;
  final String? barcode;
  final String? imagePath;

  const FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.storage,
    required this.expiryDate,
    required this.addedDate,
    this.quantity = 1,
    this.memo = '',
    this.barcode,
    this.imagePath,
  });

  /// 오늘 자정 기준 남은 일수. 음수면 이미 만료된 것.
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return exp.difference(today).inDays;
  }

  FreshnessStatus get status {
    final d = daysLeft;
    if (d < 0) return FreshnessStatus.expired;
    if (d <= 3) return FreshnessStatus.soon;
    return FreshnessStatus.fresh;
  }

  FoodItem copyWith({
    int? id,
    String? name,
    FoodCategory? category,
    StorageLocation? storage,
    DateTime? expiryDate,
    DateTime? addedDate,
    int? quantity,
    String? memo,
    String? barcode,
    String? imagePath,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      storage: storage ?? this.storage,
      expiryDate: expiryDate ?? this.expiryDate,
      addedDate: addedDate ?? this.addedDate,
      quantity: quantity ?? this.quantity,
      memo: memo ?? this.memo,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'storage': storage.name,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'quantity': quantity,
      'memo': memo,
      'barcode': barcode,
      'imagePath': imagePath,
    };
  }

  factory FoodItem.fromMap(Map<String, Object?> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: FoodCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => FoodCategory.etc,
      ),
      storage: StorageLocation.values.firstWhere(
        (s) => s.name == map['storage'],
        orElse: () => StorageLocation.fridge,
      ),
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] as int),
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate'] as int),
      quantity: (map['quantity'] as int?) ?? 1,
      memo: (map['memo'] as String?) ?? '',
      barcode: map['barcode'] as String?,
      imagePath: map['imagePath'] as String?,
    );
  }
}
