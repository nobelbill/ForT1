import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';
import '../services/barcode_scanner_service.dart';
import '../services/date_ocr_service.dart';

/// 식품 추가 화면. 바코드 스캔 / 유통기한 OCR / 수동 입력을 지원한다.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _picker = ImagePicker();
  final _barcodeService = BarcodeScannerService();
  final _ocrService = DateOcrService();

  final _nameController = TextEditingController();
  final _memoController = TextEditingController();

  FoodCategory _category = FoodCategory.etc;
  StorageLocation _storage = StorageLocation.fridge;
  DateTime _expiry = DateTime.now().add(const Duration(days: 7));
  int _quantity = 1;
  String? _barcode;

  bool _scanningBarcode = false;
  bool _scanningDate = false;

  @override
  void dispose() {
    _barcodeService.dispose();
    _ocrService.dispose();
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    setState(() => _scanningBarcode = true);
    try {
      final code = await _barcodeService.scanFromFile(picked.path);
      if (!mounted) return;
      if (code == null) {
        _snack('바코드를 찾지 못했어요. 다시 시도해 주세요.');
      } else {
        setState(() => _barcode = code);
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = '상품 ($code)';
        }
        _snack('바코드 인식: $code');
      }
    } catch (_) {
      if (mounted) _snack('바코드 인식에 실패했어요.');
    } finally {
      if (mounted) setState(() => _scanningBarcode = false);
    }
  }

  Future<void> _scanDate() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;
    setState(() => _scanningDate = true);
    try {
      final result = await _ocrService.readExpiry(picked.path);
      if (!mounted) return;
      if (result.date == null) {
        _snack('날짜를 인식하지 못했어요. 직접 선택해 주세요.');
      } else {
        setState(() => _expiry = result.date!);
        _snack('유통기한 인식: ${_fmt(result.date!)}');
      }
    } catch (_) {
      if (mounted) _snack('유통기한 인식에 실패했어요.');
    } finally {
      if (mounted) setState(() => _scanningDate = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ko'),
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('식품 이름을 입력해 주세요.');
      return;
    }
    final item = FoodItem(
      name: name,
      category: _category,
      storage: _storage,
      expiryDate: _expiry,
      addedDate: DateTime.now(),
      quantity: _quantity,
      memo: _memoController.text.trim(),
      barcode: _barcode,
    );
    await context.read<FoodRepository>().add(item);
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  String _fmt(DateTime d) => DateFormat('yyyy.MM.dd').format(d);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('식품 추가')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // AI 빠른 입력
          Row(
            children: [
              Expanded(
                child: _ScanButton(
                  icon: Icons.qr_code_scanner,
                  label: '바코드 스캔',
                  busy: _scanningBarcode,
                  onPressed: _scanBarcode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScanButton(
                  icon: Icons.document_scanner_outlined,
                  label: '유통기한 촬영',
                  busy: _scanningDate,
                  onPressed: _scanDate,
                ),
              ),
            ],
          ),
          if (_barcode != null) ...[
            const SizedBox(height: 8),
            Text('바코드: $_barcode',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 20),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '식품 이름',
              hintText: '예: 우유',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // 유통기한
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '유통기한',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(_fmt(_expiry),
                  style: theme.textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: 20),

          Text('분류', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FoodCategory.values.map((c) {
              return ChoiceChip(
                label: Text('${c.emoji} ${c.label}'),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text('보관 위치', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: StorageLocation.values.map((s) {
              return ChoiceChip(
                avatar: Icon(s.icon, size: 18),
                label: Text(s.label),
                selected: _storage == s,
                onSelected: (_) => setState(() => _storage = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Text('수량', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton.outlined(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 44,
                child: Text('$_quantity',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge),
              ),
              IconButton.outlined(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _memoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        children: [
          busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
