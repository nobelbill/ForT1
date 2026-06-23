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
│  └─ notification_service.dart      로컬 알림 예약/취소
├─ screens/
│  ├─ home_screen.dart        목록 + 필터 + 요약
│  ├─ add_item_screen.dart    추가(바코드/OCR/수동)
│  └─ item_detail_screen.dart 상세 + 삭제
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

## 권한

- **Android**: `POST_NOTIFICATIONS`(알림), `RECEIVE_BOOT_COMPLETED`(재부팅 후 알림 재등록), 카메라 촬영(IMAGE_CAPTURE 인텐트)
- **iOS**: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`

## 기술 스택

Flutter 3.44 · Dart 3.12 · ML Kit (Barcode / Text Recognition) · sqflite · provider · flutter_local_notifications · timezone · intl
