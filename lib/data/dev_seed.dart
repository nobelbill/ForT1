import '../models/food_item.dart';
import 'food_repository.dart';

/// 개발/데모용 샘플 데이터.
///
/// [main] 에서 디버그 모드 + DB가 비어 있을 때만 호출한다.
/// 만료/임박/여유 상태가 골고루 보이도록 유통기한을 오늘 기준 상대일로 구성한다.
Future<void> seedSampleData(FoodRepository repo) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime inDays(int d) => today.add(Duration(days: d));

  final samples = <FoodItem>[
    FoodItem(
      name: '유기농 우유',
      category: FoodCategory.dairy,
      storage: StorageLocation.fridge,
      expiryDate: inDays(2),
      addedDate: inDays(-5),
      quantity: 1,
      memo: '개봉함 · 빨리 드세요',
      barcode: '8801056012345',
    ),
    FoodItem(
      name: '시금치',
      category: FoodCategory.vegetable,
      storage: StorageLocation.fridge,
      expiryDate: inDays(0), // 오늘까지
      addedDate: inDays(-3),
    ),
    FoodItem(
      name: '노르웨이 연어',
      category: FoodCategory.seafood,
      storage: StorageLocation.fridge,
      expiryDate: inDays(1),
      addedDate: inDays(-1),
      memo: '스테이크용',
    ),
    FoodItem(
      name: '그릭 요거트',
      category: FoodCategory.dairy,
      storage: StorageLocation.fridge,
      expiryDate: inDays(-2), // 만료됨
      addedDate: inDays(-9),
      quantity: 2,
    ),
    FoodItem(
      name: '대패 삼겹살',
      category: FoodCategory.meat,
      storage: StorageLocation.freezer,
      expiryDate: inDays(24),
      addedDate: inDays(-6),
      quantity: 2,
    ),
    FoodItem(
      name: '손만두',
      category: FoodCategory.frozen,
      storage: StorageLocation.freezer,
      expiryDate: inDays(60),
      addedDate: inDays(-10),
    ),
    FoodItem(
      name: '아삭 사과',
      category: FoodCategory.fruit,
      storage: StorageLocation.fridge,
      expiryDate: inDays(9),
      addedDate: inDays(-4),
      quantity: 5,
    ),
    FoodItem(
      name: '구워먹는 치즈',
      category: FoodCategory.dairy,
      storage: StorageLocation.fridge,
      expiryDate: inDays(6),
      addedDate: inDays(-7),
    ),
    FoodItem(
      name: '생수 2L',
      category: FoodCategory.beverage,
      storage: StorageLocation.pantry,
      expiryDate: inDays(120),
      addedDate: inDays(-2),
      quantity: 6,
    ),
  ];

  for (final item in samples) {
    await repo.add(item);
  }
}
