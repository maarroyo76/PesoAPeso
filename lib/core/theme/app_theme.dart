import 'package:flutter/material.dart';

/// Paleta "Peso a Peso": cuaderno contable / ledger, ahora en tonos violeta.
class AppColors {
  static const paper = Color(0xFFF4F0F6);
  static const paperDeep = Color(0xFFE7DEEC);
  static const rule = Color(0xFFC7B4D1);
  static const ink = Color(0xFF4B2E6B);
  static const inkSoft = Color(0xFF7C6789);
  static const green = Color(0xFF4F7A5C);
  static const rust = Color(0xFFA3352B);
}

/// Un color por categoría, igual que en el mockup, para mantener consistencia
/// entre gráficos, chips y barras de progreso.
class AppCategoryColors {
  static const alimentacion = Color(0xFF2F6F4E);
  static const transporte = Color(0xFFB8842E);
  static const vivienda = Color(0xFF3B6B78);
  static const ocio = Color(0xFF6B3F5C);
  static const salud = Color(0xFF4B7A3E);
  static const compras = Color(0xFF8A5A2B);
}

/// Tipografías de la marca: Crimson Pro para todo el contenido (wordmark en
/// itálica, encabezados, y también el resto de la UI/labels). IBM Plex Mono
/// se reserva solo para montos: es una decisión funcional, no estética — los
/// dígitos monoespaciados alinean las cifras en columna al comparar montos,
/// algo que Crimson Pro no puede hacer al ser proporcional.
class AppFonts {
  static const wordmark = 'CrimsonPro';
  static const body = 'CrimsonPro';
  static const amount = 'IBMPlexMono';
}

/// Estilo reutilizable para montos en pesos (tabular, monoespaciado).
const appAmountTextStyle = TextStyle(
  fontFamily: AppFonts.amount,
  fontFeatures: [FontFeature.tabularFigures()],
);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      surface: AppColors.paper,
    ),
    fontFamily: AppFonts.body,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: AppFonts.wordmark,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.wordmark,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontFamily: AppFonts.wordmark,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
      ),
    ),
    dividerColor: AppColors.rule,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.wordmark,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        color: AppColors.ink,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.paperDeep,
      selectedItemColor: AppColors.green,
      unselectedItemColor: AppColors.inkSoft,
      type: BottomNavigationBarType.fixed,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.green,
      linearTrackColor: AppColors.paperDeep,
    ),
  );
}
