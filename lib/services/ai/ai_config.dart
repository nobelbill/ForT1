/// 온디바이스 LLM 설정.
///
/// 개발 단계 권장:
/// - 모델: Gemma 3 1B IT (int4, ~550MB) — 가장 작고 빨라 반복 개발에 적합
/// - 탑재: 런타임 다운로드(아래 [modelUrl]). 앱/깃에 1GB 모델을 넣지 않는다.
/// - 기기 테스트 팁: 미리 받은 .task 파일을 `adb push` 한 뒤
///   [AiAssistant] 구현에서 fromFile(localModelPath)로 로드하면 재다운로드가 없다.
///
/// 게이트된(HuggingFace 라이선스 동의 필요) 모델은 [huggingFaceToken] 를 설정한다.
class AiConfig {
  AiConfig._();

  /// MediaPipe LLM Inference용 Gemma 모델(.task) 다운로드 URL.
  /// 개발자가 자신의 (라이선스 동의된) 링크로 교체한다.
  static const String modelUrl = String.fromEnvironment(
    'GEMMA_MODEL_URL',
    defaultValue: '', // 예: https://huggingface.co/<repo>/resolve/main/gemma-3-1b-it-int4.task
  );

  /// 게이트 모델 다운로드용 HuggingFace 토큰(선택).
  static const String huggingFaceToken = String.fromEnvironment(
    'HF_TOKEN',
    defaultValue: '',
  );

  /// adb push 등으로 기기에 미리 넣어둔 모델 경로(선택).
  /// 비어 있지 않으면 네트워크 대신 이 파일을 사용한다.
  static const String localModelPath = String.fromEnvironment(
    'GEMMA_MODEL_PATH',
    defaultValue: '',
  );

  /// 생성 길이 상한.
  static const int maxTokens = 1024;

  static bool get hasModelSource =>
      modelUrl.isNotEmpty || localModelPath.isNotEmpty;
}
