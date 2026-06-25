import 'package:flutter_test/flutter_test.dart';
import 'package:foodlog/models/food_item.dart';
import 'package:foodlog/services/ai/ai_models.dart';

void main() {
  final now = DateTime(2026, 6, 25);

  group('FoodTextParser.parse', () {
    test('수량 + 보관위치 + 분류를 추출한다', () {
      final r = FoodTextParser.parse('냉동 삼겹살 2팩', now: now);
      expect(r.quantity, 2);
      expect(r.storage, StorageLocation.freezer);
      expect(r.category, FoodCategory.meat);
      expect(r.name.contains('삼겹살'), isTrue);
    });

    test('상대 날짜(내일)를 인식한다', () {
      final r = FoodTextParser.parse('내일까지 우유', now: now);
      expect(r.expiryDate, DateTime(2026, 6, 26));
      expect(r.category, FoodCategory.dairy);
    });

    test('오늘을 인식한다', () {
      final r = FoodTextParser.parse('오늘까지 시금치', now: now);
      expect(r.expiryDate, DateTime(2026, 6, 25));
      expect(r.category, FoodCategory.vegetable);
    });

    test('"N일 뒤" 표현을 인식한다', () {
      final r = FoodTextParser.parse('연어 3일 뒤', now: now);
      expect(r.expiryDate, DateTime(2026, 6, 28));
      expect(r.category, FoodCategory.seafood);
    });

    test('"M월 D일"이 이미 지났으면 내년으로 본다', () {
      final r = FoodTextParser.parse('우유 1월 5일', now: now);
      expect(r.expiryDate, DateTime(2027, 1, 5));
    });

    test('"M/D" 형식을 인식한다', () {
      final r = FoodTextParser.parse('치즈 12/1', now: now);
      expect(r.expiryDate, DateTime(2026, 12, 1));
    });

    test('정보가 없으면 기본값(수량 1)으로 둔다', () {
      final r = FoodTextParser.parse('사과', now: now);
      expect(r.quantity, 1);
      expect(r.storage, isNull);
      expect(r.expiryDate, isNull);
      expect(r.category, FoodCategory.fruit);
    });
  });

  group('AiPrompts', () {
    test('레시피 프롬프트에 재료명이 포함된다', () {
      final item = FoodItem(
        name: '시금치',
        category: FoodCategory.vegetable,
        storage: StorageLocation.fridge,
        expiryDate: now,
        addedDate: now,
      );
      final prompt = AiPrompts.recipe([item]);
      expect(prompt.contains('시금치'), isTrue);
    });
  });
}
