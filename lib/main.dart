import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/food_database.dart';
import 'data/food_repository.dart';
import 'screens/home_screen.dart';
import 'services/ai/ai_controller.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko');
  await NotificationService.instance.init();

  final repository = FoodRepository(
    FoodDatabase.instance,
    NotificationService.instance,
  );
  await repository.load();

  final ai = AiController();
  // 모델 초기화는 백그라운드로(앱 시작을 막지 않음). 준비 전에는 Stub로 동작.
  unawaited(ai.init());

  runApp(FridgeApp(repository: repository, ai: ai));
}

class FridgeApp extends StatelessWidget {
  const FridgeApp({super.key, required this.repository, required this.ai});

  final FoodRepository repository;
  final AiController ai;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repository),
        ChangeNotifierProvider.value(value: ai),
      ],
      child: MaterialApp(
        title: '냉장고 지킴이',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko'), Locale('en')],
        locale: const Locale('ko'),
        home: const HomeScreen(),
      ),
    );
  }
}
