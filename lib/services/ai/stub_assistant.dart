import '../../models/food_item.dart';
import 'ai_assistant.dart';
import 'ai_models.dart';

/// LLM이 없을 때 동작하는 규칙 기반 대체 도우미.
/// 결정적(deterministic)이라 테스트와 저사양 기기 폴백에 적합하다.
class StubAssistant implements AiAssistant {
  const StubAssistant();

  @override
  bool get isLlm => false;

  @override
  Stream<String> suggestRecipes(List<FoodItem> items) async* {
    if (items.isEmpty) {
      yield '임박한 재료가 없어요. 여유로울 때 장을 봐두면 좋아요. 🛒';
      return;
    }
    final names = items.map((e) => e.name).take(5).join(', ');
    yield '곧 소비하면 좋은 재료: $names\n\n';
    yield '• 한 그릇 볶음/덮밥 — 위 재료를 잘게 썰어 한 번에 볶아내면 간단해요.\n';
    yield '• 국/찌개 — 자투리 채소와 단백질을 함께 끓여 보세요.\n';
    yield '• 오븐/팬 구이 — 손질 후 소금·후추로 굽기만 해도 한 끼 완성.\n\n';
    yield 'ℹ️ 온디바이스 AI 모델을 설치하면 재료에 딱 맞는 레시피를 제안해 드려요.';
  }

  @override
  Future<ParsedFood> parseFood(String text) async {
    return FoodTextParser.parse(text);
  }
}
