import 'package:flutter/material.dart';

/// Paleta "Peso a Peso": cuaderno contable / ledger, en tonos violeta.
///
/// UX11: es una extensión del tema, con una variante clara (papel) y una
/// oscura (el mismo cuaderno de noche). Se lee con `context.colors`, para que
/// cada widget se repinte al cambiar el modo del sistema. Ambas variantes
/// cumplen contraste AA (4,5:1) para texto sobre paper y paperDeep.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.paper,
    required this.paperDeep,
    required this.rule,
    required this.ink,
    required this.inkSoft,
    required this.green,
    required this.rust,
    required this.isDark,
  });

  final Color paper;
  final Color paperDeep;
  final Color rule;
  final Color ink;
  final Color inkSoft;
  final Color green;
  final Color rust;
  final bool isDark;

  static const light = AppPalette(
    paper: Color(0xFFF4F0F6),
    paperDeep: Color(0xFFE7DEEC),
    rule: Color(0xFFC7B4D1),
    ink: Color(0xFF4B2E6B),
    inkSoft: Color(0xFF6E5A7B),
    green: Color(0xFF3E654A),
    rust: Color(0xFFA3352B),
    isDark: false,
  );

  static const dark = AppPalette(
    paper: Color(0xFF1B1520),
    paperDeep: Color(0xFF262030),
    rule: Color(0xFF4E4259),
    ink: Color(0xFFEDE4F4),
    inkSoft: Color(0xFFB6A6C3),
    green: Color(0xFF8CC39C),
    rust: Color(0xFFF08C80),
    isDark: true,
  );

  /// Color de una categoría tal como se muestra. Los colores guardados están
  /// pensados para el papel claro; sobre el fondo oscuro se aclaran para que
  /// íconos y barras se sigan distinguiendo (3:1 o más).
  Color category(int colorValue) {
    final c = Color(colorValue);
    return isDark ? Color.lerp(c, Colors.white, 0.4)! : c;
  }

  @override
  AppPalette copyWith({
    Color? paper,
    Color? paperDeep,
    Color? rule,
    Color? ink,
    Color? inkSoft,
    Color? green,
    Color? rust,
    bool? isDark,
  }) =>
      AppPalette(
        paper: paper ?? this.paper,
        paperDeep: paperDeep ?? this.paperDeep,
        rule: rule ?? this.rule,
        ink: ink ?? this.ink,
        inkSoft: inkSoft ?? this.inkSoft,
        green: green ?? this.green,
        rust: rust ?? this.rust,
        isDark: isDark ?? this.isDark,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      paper: Color.lerp(paper, other.paper, t)!,
      paperDeep: Color.lerp(paperDeep, other.paperDeep, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      green: Color.lerp(green, other.green, t)!,
      rust: Color.lerp(rust, other.rust, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Paleta del tema actual (clara u oscura). Sin el tema de la app (p. ej.
  /// un MaterialApp de prueba), la clara.
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
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

ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final c = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    extensions: [c],
    scaffoldBackgroundColor: c.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.green,
      brightness: brightness,
      surface: c.paper,
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
    ).apply(bodyColor: c.ink, displayColor: c.ink),
    dividerColor: c.rule,
    appBarTheme: AppBarTheme(
      backgroundColor: c.paper,
      foregroundColor: c.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.wordmark,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        color: c.ink,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.paperDeep,
      selectedItemColor: c.green,
      unselectedItemColor: c.inkSoft,
      type: BottomNavigationBarType.fixed,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.green,
      linearTrackColor: c.paperDeep,
    ),
    // Los botones rellenos usan ink, rust o green de fondo: el texto va en
    // color papel para que contraste en ambos modos (con el blanco por
    // defecto, en oscuro quedaría blanco sobre lavanda claro).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(foregroundColor: c.paper),
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: TextStyle(fontFamily: AppFonts.body, color: c.paper),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.paper),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.paper),
  );
}
