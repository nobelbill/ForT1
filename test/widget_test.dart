import 'package:flutter_test/flutter_test.dart';
import 'package:foodlog/models/food_item.dart';
import 'package:foodlog/services/date_ocr_service.dart';

void main() {
  group('DateOcrService.parseExpiryDate', () {
    test('YYYY.MM.DD 형식을 인식한다', () {
      expect(
        DateOcrService.parseExpiryDate('유통기한 2026.06.23'),
        DateTime(2026, 6, 23),
      );
    });

    test('YYYY-MM-DD / YYYYMMDD 형식을 인식한다', () {
      expect(DateOcrService.parseExpiryDate('2026-12-01'),
          DateTime(2026, 12, 1));
      expect(DateOcrService.parseExpiryDate('20261201'),
          DateTime(2026, 12, 1));
    });

    test('한국어 표기(YYYY년 MM월 DD일)를 인식한다', () {
      expect(
        DateOcrService.parseExpiryDate('제조 2026년 1월 5일'),
        DateTime(2026, 1, 5),
      );
    });

    test('여러 날짜 중 가장 늦은 날짜(유통기한)를 고른다', () {
      const text = '제조일자 2026.06.01  유통기한 2026.06.30';
      expect(
        DateOcrService.parseExpiryDate(text),
        DateTime(2026, 6, 30),
      );
    });

    test('날짜가 없으면 null을 반환한다', () {
      expect(DateOcrService.parseExpiryDate('내용량 500g'), isNull);
    });

    test('잘못된 월/일은 무시한다', () {
      expect(DateOcrService.parseExpiryDate('2026.13.40'), isNull);
    });
  });

  group('FoodItem.status', () {
    FoodItem itemDueIn(int days) => FoodItem(
          name: '테스트',
          category: FoodCategory.etc,
          storage: StorageLocation.fridge,
          expiryDate: DateTime.now().add(Duration(days: days)),
          addedDate: DateTime.now(),
        );

    test('지난 날짜는 expired', () {
      expect(itemDueIn(-1).status, FreshnessStatus.expired);
    });

    test('3일 이내는 soon', () {
      expect(itemDueIn(2).status, FreshnessStatus.soon);
    });

    test('여유 있으면 fresh', () {
      expect(itemDueIn(10).status, FreshnessStatus.fresh);
    });
  });
}
