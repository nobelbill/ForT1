import '../../models/food_item.dart';
import 'ai_models.dart';

/// 온디바이스 AI 도우미 인터페이스.
///
/// 구현은 두 가지:
/// - [GemmaAssistant]: 실제 온디바이스 LLM(flutter_gemma)
/// - [StubAssistant]: 모델이 없을 때 쓰는 규칙 기반 대체
abstract class AiAssistant {
  /// 실제 LLM 추론이 가능한지(모델 로드됨). Stub은 false.
  bool get isLlm;

  /// 임박 식품으로 레시피를 추천한다. 토큰 단위로 스트리밍.
  Stream<String> suggestRecipes(List<FoodItem> items);

  /// 자연어 문장에서 식품 정보를 추출한다.
  Future<ParsedFood> parseFood(String text);
}
