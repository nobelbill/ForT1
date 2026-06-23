import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'data/food_database.dart';
import 'data/food_repository.dart';
import 'screens/home_screen.dart';
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

  runApp(FridgeApp(repository: repository));
}

class FridgeApp extends StatelessWidget {
  const FridgeApp({super.key, required this.repository});

  final FoodRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: repository,
      child: MaterialApp(
        title: '냉장고 지킴이',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
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
