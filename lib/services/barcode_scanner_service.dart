import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// 온디바이스 ML Kit 바코드 스캐너. 이미지에서 상품 바코드를 읽는다.
class BarcodeScannerService {
  BarcodeScannerService() : _scanner = BarcodeScanner();

  final BarcodeScanner _scanner;

  /// 이미지에서 첫 번째로 인식된 바코드 값을 반환한다. 없으면 null.
  Future<String?> scanFromFile(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final barcodes = await _scanner.processImage(input);
    if (barcodes.isEmpty) return null;
    final first = barcodes.first;
    return first.rawValue ?? first.displayValue;
  }

  void dispose() => _scanner.close();
}
