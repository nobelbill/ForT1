import 'dart:convert';

import 'package:flutter_gemma/flutter_gemma.dart';

import '../../models/food_item.dart';
import 'ai_assistant.dart';
import 'ai_models.dart';

/// flutter_gemma 기반 온디바이스 LLM 도우미.
/// 모델은 [AiController] 가 로드해 주입한다.
class GemmaAssistant implements AiAssistant {
  GemmaAssistant(this._model);

  final InferenceModel _model;

  @override
  bool get isLlm => true;

  @override
  Stream<String> suggestRecipes(List<FoodItem> items) async* {
    final session = await _model.createSession(
      temperature: 0.8,
      topK: 40,
      systemInstruction: AiPrompts.recipeSystem,
    );
    try {
      await session.addQueryChunk(Message.text(text: AiPrompts.recipe(items)));
      yield* session.getResponseAsync();
    } finally {
      await session.close();
    }
  }

  @override
  Future<ParsedFood> parseFood(String text) async {
    final session = await _model.createSession(temperature: 0.2, topK: 1);
    try {
      await session.addQueryChunk(Message.text(text: AiPrompts.parseFood(text)));
      final raw = await session.getResponse();
      final parsed = _parseJson(raw, text);
      // LLM 결과가 비면 규칙 기반으로 폴백.
      return parsed ?? FoodTextParser.parse(text);
    } catch (_) {
      return FoodTextParser.parse(text);
    } finally {
      await session.close();
    }
  }

  ParsedFood? _parseJson(String raw, String original) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final map = jsonDecode(raw.substring(start, end + 1)) as Map;
      final name = (map['name'] as String?)?.trim();
      if (name == null || name.isEmpty) return null;
      return ParsedFood(
        name: name,
        quantity: (map['quantity'] as num?)?.toInt().clamp(1, 999) ?? 1,
        storage: _storage(map['storage'] as String?),
        expiryDate: _date(map['expiry'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  StorageLocation? _storage(String? s) => switch (s) {
        '냉장' => StorageLocation.fridge,
        '냉동' => StorageLocation.freezer,
        '실온' => StorageLocation.pantry,
        _ => null,
      };

  DateTime? _date(String? s) => s == null ? null : DateTime.tryParse(s);
}
