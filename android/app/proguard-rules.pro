# Google ML Kit 텍스트 인식: 라틴 스크립트만 사용하므로
# 번들되지 않은 다른 스크립트 인식기 클래스에 대한 R8 경고를 무시한다.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
