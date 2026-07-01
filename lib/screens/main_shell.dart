import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'home_screen.dart';
import 'recipe_screen.dart';
import 'settings_screen.dart';

/// 하단 탭 내비게이션을 제공하는 앱 셸. 탭 간 상태를 유지한다.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [HomeScreen(), RecipeScreen(), SettingsScreen()];

  void _onTap(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        backgroundColor: FreshTokens.card,
        indicatorColor: FreshTokens.accentSoft,
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen, color: FreshTokens.accent),
            label: '냉장고',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome, color: FreshTokens.accent),
            label: '레시피',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune, color: FreshTokens.accent),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
