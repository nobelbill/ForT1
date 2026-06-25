import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';

import 'ai_assistant.dart';
import 'ai_config.dart';
import 'gemma_assistant.dart';
import 'stub_assistant.dart';

enum AiStatus { stub, downloading, ready, error }

/// 온디바이스 LLM 모델의 생명주기를 관리하고, 현재 사용할 [AiAssistant] 를 노출한다.
/// 모델이 준비되지 않았으면 자동으로 규칙 기반 [StubAssistant] 로 폴백한다.
class AiController extends ChangeNotifier {
  AiController();

  final AiAssistant _stub = const StubAssistant();
  GemmaAssistant? _gemma;

  AiStatus _status = AiStatus.stub;
  int _progress = 0;
  String? _error;

  AiStatus get status => _status;
  int get progress => _progress;
  String? get error => _error;
  bool get modelReady => _status == AiStatus.ready && _gemma != null;

  /// 모델이 준비됐으면 LLM 어시스턴트, 아니면 Stub.
  AiAssistant get assistant => modelReady ? _gemma! : _stub;

  bool get canDownload => AiConfig.hasModelSource;

  /// 앱 시작 시 호출. 엔진을 등록하고 이미 설치된 모델이 있으면 활성화한다.
  Future<void> init() async {
    try {
      await FlutterGemma.initialize(
        inferenceEngines: const [MediaPipeEngine()],
        huggingFaceToken:
            AiConfig.huggingFaceToken.isEmpty ? null : AiConfig.huggingFaceToken,
      );
      final installed = await FlutterGemma.listInstalledModels();
      if (installed.isNotEmpty) {
        await _activate();
      }
    } catch (_) {
      // 미지원 플랫폼/초기화 실패 → Stub 유지(앱은 정상 동작).
      _status = AiStatus.stub;
    }
    notifyListeners();
  }

  /// 모델을 (필요 시 다운로드 후) 로드한다.
  Future<void> downloadAndLoad() async {
    if (!canDownload) {
      _error = '모델 소스가 설정되지 않았어요. AiConfig.modelUrl 또는 localModelPath 를 지정하세요.';
      _status = AiStatus.error;
      notifyListeners();
      return;
    }
    _status = AiStatus.downloading;
    _progress = 0;
    _error = null;
    notifyListeners();
    try {
      final builder = FlutterGemma.installModel(modelType: ModelType.gemmaIt);
      final configured = AiConfig.localModelPath.isNotEmpty
          ? builder.fromFile(AiConfig.localModelPath)
          : builder
              .fromNetwork(
                AiConfig.modelUrl,
                token: AiConfig.huggingFaceToken.isEmpty
                    ? null
                    : AiConfig.huggingFaceToken,
              )
              .withProgress((p) {
              _progress = p;
              notifyListeners();
            });
      await configured.install();
      await _activate();
    } catch (e) {
      _error = '$e';
      _status = AiStatus.error;
    }
    notifyListeners();
  }

  Future<void> _activate() async {
    final model =
        await FlutterGemma.getActiveModel(maxTokens: AiConfig.maxTokens);
    _gemma = GemmaAssistant(model);
    _status = AiStatus.ready;
  }
}
