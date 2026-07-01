import 'package:flutter/material.dart';

import 'models/food_item.dart';

/// "Fresh" 비주얼 방향의 디자인 토큰.
/// 산뜻한 데이라이트 · 화이트 카드 · 가든 그린.
class FreshTokens {
  FreshTokens._();

  static const bg = Color(0xFFEDF2EA);
  static const card = Color(0xFFFFFFFF);
  static const cardBorder = Color.fromRGBO(20, 40, 25, 0.07);

  static const text = Color(0xFF15231A);
  static const sub = Color(0xFF5E6C61);
  static const faint = Color(0xFF93A096);

  static const accent = Color(0xFF1F7A3D);
  static const accentSoft = Color(0xFFE4F1E7);
  static const onAccent = Color(0xFFFFFFFF);

  static const chipBg = Color(0xFFFFFFFF);
  static const chipFg = Color(0xFF3A463E);
  static const chipActiveBg = Color(0xFF1F7A3D);
  static const chipActiveFg = Color(0xFFFFFFFF);
  static const chipBorder = Color.fromRGBO(20, 40, 25, 0.10);

  static const fab = Color(0xFF1F7A3D);
  static const onFab = Color(0xFFFFFFFF);

  // 신선도 배지
  static const freshBg = Color(0xFFE4F1E7);
  static const freshFg = Color(0xFF1F7A3D);
  static const soonBg = Color(0xFFFFF0D9);
  static const soonFg = Color(0xFFB96309);
  static const expBg = Color(0xFFFBE4E1);
  static const expFg = Color(0xFFC0392F);

  static const divider = Color.fromRGBO(20, 40, 25, 0.07);
  static const fieldBg = Color(0xFFFFFFFF);
  static const fieldBorder = Color.fromRGBO(20, 40, 25, 0.14);

  static const cardRadius = 24.0;
  static const cardShadow = BoxShadow(
    color: Color.fromRGBO(28, 60, 38, 0.06),
    blurRadius: 18,
    offset: Offset(0, 6),
  );

  static const appEmoji = '🌿';

  /// 신선도 상태별 (배경색, 글자색).
  static (Color bg, Color fg) badgeColors(FreshnessStatus status) {
    return switch (status) {
      FreshnessStatus.expired => (expBg, expFg),
      FreshnessStatus.soon => (soonBg, soonFg),
      FreshnessStatus.fresh => (freshBg, freshFg),
    };
  }
}

/// Fresh 방향에 맞춘 Material 3 라이트 테마.
ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: FreshTokens.accent,
    onPrimary: FreshTokens.onAccent,
    secondary: FreshTokens.accent,
    onSecondary: FreshTokens.onAccent,
    surface: FreshTokens.card,
    onSurface: FreshTokens.text,
    onSurfaceVariant: FreshTokens.sub,
    surfaceContainerHighest: FreshTokens.accentSoft,
    outline: FreshTokens.faint,
    outlineVariant: FreshTokens.cardBorder,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FreshTokens.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: FreshTokens.bg,
      foregroundColor: FreshTokens.text,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: FreshTokens.divider),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF121A14),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FreshTokens.fab,
        foregroundColor: FreshTokens.onFab,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}
