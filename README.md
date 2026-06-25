# 냉장고 지킴이 (Fridge Keeper)

냉장고 속 식품의 **유통기한을 관리**하고, 임박 시 **로컬 알림**으로 알려주는 Flutter 앱입니다.
온디바이스 AI(Google ML Kit)로 바코드와 유통기한 날짜를 인식해 빠르게 등록할 수 있습니다.
모든 데이터는 **기기 내부(로컬)** 에만 저장되며 외부 서버를 사용하지 않습니다.

## 주요 기능

- 🧊 **식품 관리**: 냉장 / 냉동 / 실온별로 식품을 등록·분류
- 🤖 **온디바이스 AI 인식** (네트워크 불필요)
  - **바코드 스캔** — 상품 바코드를 촬영해 빠르게 등록 (ML Kit Barcode Scanning)
  - **유통기한 OCR** — 포장지의 날짜를 촬영하면 자동 인식 (ML Kit Text Recognition)
- ⏰ **유통기한 임박 알림** — 만료 3일 전 오전에 로컬 푸시 알림 (`flutter_local_notifications`)
- 🚦 **D-day 배지** — 만료(빨강) / 임박(주황) / 여유(초록) 색상 구분, 임박순 자동 정렬
- 📊 전체 / 임박 / 만료 개수 요약
- ✨ **온디바이스 LLM (Gemma)** — 완전 오프라인 (`flutter_gemma`)
  - **AI 레시피 추천** — 임박 식품으로 만들 수 있는 요리를 제안 (음식물 쓰레기 ↓)
  - **자연어 입력** — "냉동 삼겹살 2팩 12월 1일" 한 줄로 폼 자동 완성
  - 모델 미설치/저사양 기기에서는 **규칙 기반 폴백**으로 동작 (graceful degradation)
- 💾 **100% 로컬 저장** (sqflite)

## 아키텍처

```
lib/
├─ main.dart                  앱 진입점 (초기화 + Provider 주입)
├─ theme.dart                 Material 3 테마
├─ models/
│  └─ food_item.dart          식품 모델 + 보관위치/분류/신선도 상태
├─ data/
│  ├─ food_database.dart      sqflite 로컬 DB
│  └─ food_repository.dart    상태 관리(ChangeNotifier) + 알림 예약 연동
├─ services/
│  ├─ barcode_scanner_service.dart   ML Kit 바코드 스캔
│  ├─ date_ocr_service.dart          ML Kit 텍스트 인식 + 날짜 파싱
│  ├─ notification_service.dart      로컬 알림 예약/취소
│  └─ ai/
│     ├─ ai_config.dart       모델 URL/토큰/경로 설정
│     ├─ ai_models.dart       ParsedFood · 규칙기반 파서 · 프롬프트
│     ├─ ai_assistant.dart    추상 인터페이스
│     ├─ stub_assistant.dart  규칙 기반 폴백 구현
│     ├─ gemma_assistant.dart flutter_gemma(LLM) 구현
│     └─ ai_controller.dart   모델 생명주기 + 활성 어시스턴트 선택
├─ screens/
│  ├─ home_screen.dart        목록 + 필터 + 요약 + 레시피/알림 진입
│  ├─ add_item_screen.dart    추가(자연어/바코드/OCR/수동)
│  ├─ item_detail_screen.dart 상세 + 삭제
│  └─ recipe_screen.dart      AI 레시피 추천(스트리밍)
└─ widgets/
   └─ food_card.dart          카드 + D-day 배지
```

- **상태 관리**: `provider` (`ChangeNotifier`)
- **저장소**: `sqflite` (코드 생성 불필요, 손수 작성한 SQL)

## 실행 방법

Flutter SDK(stable)가 설치된 환경에서:

```bash
flutter pub get
flutter run            # 실기기 또는 에뮬레이터 (카메라/알림은 실기기 권장)
```

> 카메라(바코드/OCR)와 알림 기능은 **실제 기기**에서 가장 잘 동작합니다.

## 테스트

```bash
flutter analyze        # 정적 분석
flutter test           # 날짜 파서 / 신선도 상태 단위 테스트
```

## 온디바이스 LLM 설정 (개발)

레시피 추천 / 자연어 입력은 **Gemma** 모델을 기기에서 직접 구동합니다(`flutter_gemma` + MediaPipe).
모델 파일(약 0.5~1GB)은 앱/깃에 포함하지 않고 **런타임에 한 번 설치**합니다.

```bash
# 1) HuggingFace 등에서 받은 .task 모델 URL을 주입해 실행 (권장: Gemma 3 1B int4)
flutter run --dart-define=GEMMA_MODEL_URL=https://huggingface.co/<repo>/resolve/main/<model>.task

# 게이트된(라이선스 동의 필요) 모델이면 토큰도 함께
flutter run \
  --dart-define=GEMMA_MODEL_URL=<url> \
  --dart-define=HF_TOKEN=hf_xxx

# 2) 또는 모델을 기기에 미리 넣고(adb push) 로컬 경로로 로드 — 재다운로드 없음
adb push gemma-3-1b-it-int4.task /data/local/tmp/gemma.task
flutter run --dart-define=GEMMA_MODEL_PATH=/data/local/tmp/gemma.task
```

설정값은 `lib/services/ai/ai_config.dart` 에서 관리합니다. **URL/경로가 없으면** AI 기능은
자동으로 규칙 기반 폴백으로 동작하므로 앱은 그대로 실행됩니다.

> iOS 추가 설정: `Podfile` 에 `platform :ios, '16.0'` 와 `use_frameworks! :linkage => :static`,
> 대형 모델 사용 시 `Runner.entitlements` 메모리 entitlement. (`flutter_gemma` README 참고)

## 권한

- **Android**: `POST_NOTIFICATIONS`(알림), `RECEIVE_BOOT_COMPLETED`(재부팅 후 알림 재등록), 카메라 촬영(IMAGE_CAPTURE 인텐트)
- **iOS**: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`

## 기술 스택

Flutter 3.44 · Dart 3.12 · ML Kit (Barcode / Text Recognition) · flutter_gemma (on-device LLM, MediaPipe) · sqflite · provider · flutter_local_notifications · timezone · intl
