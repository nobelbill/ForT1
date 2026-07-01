import 'package:flutter/foundation.dart';

import 'ai_assistant.dart';
import 'stub_assistant.dart';

/// 현재 사용할 [AiAssistant] 를 노출한다.
///
/// 지금은 오프라인 규칙 기반([StubAssistant])으로 동작한다. 온디바이스 LLM은
/// 툴체인 호환성이 정리되면 [AiAssistant] 구현만 추가해 다시 붙일 수 있다.
class AiController extends ChangeNotifier {
  AiController();

  final AiAssistant _stub = const StubAssistant();

  /// 레시피 추천 / 자연어 입력에 사용할 어시스턴트.
  AiAssistant get assistant => _stub;

  /// LLM 추론 사용 여부(현재는 규칙 기반이므로 false).
  bool get isLlm => _stub.isLlm;

  Future<void> init() async {}
}
