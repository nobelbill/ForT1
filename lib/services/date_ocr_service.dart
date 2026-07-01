import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 온디바이스 ML Kit 텍스트 인식으로 포장지의 유통기한을 읽어낸다.
class DateOcrService {
  DateOcrService()
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  /// 이미지에서 텍스트를 추출하고, 그 안에서 가장 그럴듯한 유통기한을 찾는다.
  /// 인식된 날짜가 없으면 null을 반환한다.
  Future<DateOcrResult> readExpiry(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    final date = parseExpiryDate(recognized.text);
    return DateOcrResult(rawText: recognized.text, date: date);
  }

  void dispose() => _recognizer.close();

  /// 자유 텍스트에서 날짜를 모두 찾아 가장 늦은 날짜(보통 유통기한)를 고른다.
  static DateTime? parseExpiryDate(String text) {
    final candidates = <DateTime>[];

    // YYYY.MM.DD / YYYY-MM-DD / YYYY/MM/DD / YYYY MM DD
    final ymd = RegExp(r'(20\d{2})\s*[.\-/년]\s*(\d{1,2})\s*[.\-/월]\s*(\d{1,2})');
    for (final m in ymd.allMatches(text)) {
      final d = _build(m.group(1), m.group(2), m.group(3));
      if (d != null) candidates.add(d);
    }

    // YYYYMMDD (8 connected digits)
    final compact = RegExp(r'(?<!\d)(20\d{2})(\d{2})(\d{2})(?!\d)');
    for (final m in compact.allMatches(text)) {
      final d = _build(m.group(1), m.group(2), m.group(3));
      if (d != null) candidates.add(d);
    }

    // YY.MM.DD  (두 자리 연도, 20YY로 가정)
    final shortYmd = RegExp(r'(?<!\d)(\d{2})\s*[.\-/]\s*(\d{1,2})\s*[.\-/]\s*(\d{1,2})(?!\d)');
    for (final m in shortYmd.allMatches(text)) {
      final d = _build('20${m.group(1)}', m.group(2), m.group(3));
      if (d != null) candidates.add(d);
    }

    if (candidates.isEmpty) return null;
    candidates.sort();
    // 포장지에는 제조일+유통기한이 함께 있는 경우가 많아, 가장 늦은 날짜를 택한다.
    return candidates.last;
  }

  static DateTime? _build(String? y, String? mo, String? d) {
    final year = int.tryParse(y ?? '');
    final month = int.tryParse(mo ?? '');
    final day = int.tryParse(d ?? '');
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 2000 || year > 2100) return null;
    return DateTime(year, month, day);
  }
}

class DateOcrResult {
  final String rawText;
  final DateTime? date;
  const DateOcrResult({required this.rawText, required this.date});
}
