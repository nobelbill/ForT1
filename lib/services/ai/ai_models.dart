import '../../models/food_item.dart';

/// 자연어 입력에서 추출한 식품 정보(부분적일 수 있음).
class ParsedFood {
  final String name;
  final int quantity;
  final StorageLocation? storage;
  final FoodCategory? category;
  final DateTime? expiryDate;

  const ParsedFood({
    required this.name,
    this.quantity = 1,
    this.storage,
    this.category,
    this.expiryDate,
  });
}

/// 규칙 기반 자연어 파서.
///
/// LLM이 없을 때(저사양 기기·모델 미설치·테스트)도 "내일까지 우유 2개" 같은
/// 입력을 구조화한다. LLM 구현은 이 파서를 폴백으로 활용할 수 있다.
class FoodTextParser {
  FoodTextParser._();

  /// 분류 추정용 키워드 사전.
  static const Map<FoodCategory, List<String>> _categoryKeywords = {
    FoodCategory.vegetable: ['시금치', '상추', '당근', '양파', '오이', '대파', '브로콜리', '채소'],
    FoodCategory.fruit: ['사과', '바나나', '딸기', '포도', '귤', '오렌지', '배', '키위', '과일'],
    FoodCategory.meat: ['삼겹살', '소고기', '돼지', '닭', '계란', '달걀', '베이컨', '고기', '육류'],
    FoodCategory.seafood: ['연어', '고등어', '새우', '오징어', '조개', '생선', '회', '수산'],
    FoodCategory.dairy: ['우유', '치즈', '요거트', '버터', '생크림', '유제품'],
    FoodCategory.beverage: ['주스', '콜라', '사이다', '맥주', '커피', '음료', '물'],
    FoodCategory.sauce: ['간장', '고추장', '된장', '케첩', '마요', '소스', '양념', '기름'],
    FoodCategory.frozen: ['만두', '피자', '아이스크림', '냉동'],
  };

  static const Map<StorageLocation, List<String>> _storageKeywords = {
    StorageLocation.fridge: ['냉장'],
    StorageLocation.freezer: ['냉동'],
    StorageLocation.pantry: ['실온', '상온'],
  };

  /// [text] 를 파싱한다. [now] 는 상대 날짜(오늘/내일) 기준이며 테스트에서 주입한다.
  static ParsedFood parse(String text, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    var working = ' $text ';

    // 1) 보관 위치
    StorageLocation? storage;
    _storageKeywords.forEach((loc, kws) {
      for (final kw in kws) {
        if (working.contains(kw)) {
          storage ??= loc;
          working = working.replaceAll(kw, ' ');
        }
      }
    });

    // 2) 유통기한
    final (expiry, afterDate) = _extractDate(working, today);
    working = afterDate;

    // 3) 수량
    final (qty, afterQty) = _extractQuantity(working);
    working = afterQty;

    // 4) 분류 (이름 추출 전에 키워드로 추정)
    FoodCategory? category;
    _categoryKeywords.forEach((cat, kws) {
      if (category != null) return;
      if (kws.any((kw) => working.contains(kw))) category = cat;
    });

    // 5) 남은 텍스트에서 이름 정리
    final name = _cleanName(working);

    return ParsedFood(
      name: name,
      quantity: qty,
      storage: storage,
      category: category,
      expiryDate: expiry,
    );
  }

  static (DateTime?, String) _extractDate(String text, DateTime today) {
    // 상대 표현
    final relatives = {
      '오늘': 0,
      '내일': 1,
      '모레': 2,
      '글피': 3,
    };
    for (final entry in relatives.entries) {
      if (text.contains(entry.key)) {
        return (today.add(Duration(days: entry.value)),
            text.replaceAll(entry.key, ' '));
      }
    }

    // "N일 뒤/후/안"
    final inDays = RegExp(r'(\d{1,3})\s*일\s*(뒤|후|안|내)');
    final mInDays = inDays.firstMatch(text);
    if (mInDays != null) {
      final n = int.tryParse(mInDays.group(1)!) ?? 0;
      return (today.add(Duration(days: n)), text.replaceAll(inDays, ' '));
    }

    // "M월 D일" (연도 없음 → 올해, 이미 지났으면 내년)
    final md = RegExp(r'(\d{1,2})\s*월\s*(\d{1,2})\s*일?');
    final mMd = md.firstMatch(text);
    if (mMd != null) {
      final mo = int.tryParse(mMd.group(1)!);
      final d = int.tryParse(mMd.group(2)!);
      final built = _buildMonthDay(mo, d, today);
      if (built != null) return (built, text.replaceAll(md, ' '));
    }

    // "M/D" 또는 "M.D"
    final slash = RegExp(r'(?<!\d)(\d{1,2})\s*[./]\s*(\d{1,2})(?!\d)');
    final mSlash = slash.firstMatch(text);
    if (mSlash != null) {
      final mo = int.tryParse(mSlash.group(1)!);
      final d = int.tryParse(mSlash.group(2)!);
      final built = _buildMonthDay(mo, d, today);
      if (built != null) return (built, text.replaceAll(slash, ' '));
    }

    return (null, text);
  }

  static DateTime? _buildMonthDay(int? mo, int? d, DateTime today) {
    if (mo == null || d == null) return null;
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    var date = DateTime(today.year, mo, d);
    if (date.isBefore(today)) date = DateTime(today.year + 1, mo, d);
    return date;
  }

  static (int, String) _extractQuantity(String text) {
    final qty = RegExp(r'(\d{1,3})\s*(개|팩|병|봉|봉지|장|통|줄|모|판)');
    final m = qty.firstMatch(text);
    if (m != null) {
      final n = int.tryParse(m.group(1)!) ?? 1;
      return (n.clamp(1, 999), text.replaceAll(qty, ' '));
    }
    return (1, text);
  }

  static String _cleanName(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'[까지|에|을|를|이|가|은|는]\s'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? '식품' : cleaned;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// 레시피/자연어 프롬프트 생성기.
class AiPrompts {
  AiPrompts._();

  static const recipeSystem =
      '너는 냉장고 속 재료로 만들 수 있는 한국 가정식 요리를 제안하는 도우미야. '
      '간결하게, 한국어로 답해.';

  /// 임박 식품 목록으로 레시피 추천 프롬프트를 만든다.
  static String recipe(List<FoodItem> items) {
    final lines = items.map((e) {
      final d = e.daysLeft;
      final when = d < 0 ? '만료됨' : (d == 0 ? '오늘까지' : 'D-$d');
      return '- ${e.name} (${e.category.label}, $when)';
    }).join('\n');
    return '다음은 곧 소비해야 할 냉장고 재료야:\n$lines\n\n'
        '이 재료들을 활용한 요리 3가지를 추천해줘. '
        '각 요리마다 이름과 1~2문장의 간단한 설명만 적어줘.';
  }

  /// 자연어 → JSON 추출 프롬프트.
  static String parseFood(String text) {
    return '다음 문장에서 식품 정보를 JSON으로만 추출해. '
        '키: name(문자열), quantity(정수), storage("냉장"|"냉동"|"실온"), '
        'expiry("YYYY-MM-DD" 또는 null). 설명 없이 JSON만 출력해.\n'
        '문장: "$text"';
  }
}
