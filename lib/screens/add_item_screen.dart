import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../models/food_item.dart';
import '../services/barcode_scanner_service.dart';
import '../services/date_ocr_service.dart';
import '../theme.dart';

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

  FoodCategory _category = FoodCategory.dairy;
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
        _snack('바코드 인식 완료 · $code');
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
        _snack('유통기한 인식 · ${_fmt(result.date!)}');
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

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _fmt(DateTime d) => DateFormat('yyyy.MM.dd').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식품 추가',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
        children: [
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
                  icon: Icons.center_focus_weak,
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
                style: const TextStyle(fontSize: 12.5, color: FreshTokens.sub)),
          ],
          const SizedBox(height: 18),

          const _FieldLabel('식품 이름'),
          _TextField(controller: _nameController, hint: '예: 우유'),
          const SizedBox(height: 18),

          const _FieldLabel('유통기한'),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: _fieldDecoration(),
              child: Row(
                children: [
                  Text(_fmt(_expiry),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: FreshTokens.text)),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined,
                      size: 19, color: FreshTokens.sub),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const _FieldLabel('분류'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FoodCategory.values
                .map((c) => _ChoiceChip(
                      label: '${c.emoji} ${c.label}',
                      active: _category == c,
                      onTap: () => setState(() => _category = c),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          const _FieldLabel('보관 위치'),
          Row(
            children: StorageLocation.values
                .map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ChoiceChip(
                        label: s.label,
                        active: _storage == s,
                        onTap: () => setState(() => _storage = s),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),

          Row(
            children: [
              const Text('수량',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: FreshTokens.text)),
              const Spacer(),
              _StepperButton(
                icon: Icons.remove,
                onTap: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              SizedBox(
                width: 48,
                child: Text('$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: FreshTokens.text)),
              ),
              _StepperButton(
                icon: Icons.add,
                onTap: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 18),

          const _FieldLabel('메모 (선택)'),
          _TextField(
            controller: _memoController,
            hint: '예: 개봉함, 빨리 먹기',
            maxLines: 2,
          ),
          const SizedBox(height: 26),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, weight: 700),
            label: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _fieldDecoration() => BoxDecoration(
      color: FreshTokens.fieldBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: FreshTokens.fieldBorder),
    );

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: FreshTokens.sub)),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: FreshTokens.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: FreshTokens.faint),
        filled: true,
        fillColor: FreshTokens.fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FreshTokens.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FreshTokens.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FreshTokens.accent, width: 1.6),
        ),
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
    return InkWell(
      onTap: busy ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: FreshTokens.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FreshTokens.cardBorder),
          boxShadow: const [FreshTokens.cardShadow],
        ),
        child: Column(
          children: [
            busy
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: FreshTokens.accent),
                  )
                : Icon(icon, size: 26, color: FreshTokens.text),
            const SizedBox(height: 9),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FreshTokens.text)),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? FreshTokens.chipActiveBg : FreshTokens.chipBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FreshTokens.chipBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    active ? FreshTokens.chipActiveFg : FreshTokens.chipFg)),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: FreshTokens.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FreshTokens.cardBorder),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? FreshTokens.text : FreshTokens.faint),
      ),
    );
  }
}
