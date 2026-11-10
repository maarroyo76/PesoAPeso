import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../data/local/app_database.dart';
import '../notifications/mobile_platform.dart';
import 'quick_widget.dart';

/// RF39: el widget existe solo en Android. En iOS, web, escritorio y tests
/// estas funciones no hacen nada.
bool get _enabled => isAndroidDevice;

/// Guarda los accesos rápidos para el widget y le pide redibujarse.
Future<void> syncQuickWidget(List<QuickExpenseTemplate> templates) async {
  if (!_enabled) return;
  try {
    for (final e in quickWidgetData(templates).entries) {
      await HomeWidget.saveWidgetData<Object>(e.key, e.value);
    }
    await HomeWidget.updateWidget(
        qualifiedAndroidName: kQuickWidgetAndroidClass);
  } catch (e) {
    // Un widget desactualizado no debe interrumpir la app.
    debugPrint('Widget: $e');
  }
}

/// El enlace con que el widget abrió la app, si fue así.
Future<Uri?> initialWidgetUri() async {
  if (!_enabled) return null;
  try {
    return await HomeWidget.initiallyLaunchedFromHomeWidget();
  } catch (e) {
    debugPrint('Widget: $e');
    return null;
  }
}

/// Los toques en el widget mientras la app ya está abierta.
Stream<Uri?> widgetClicks() =>
    _enabled ? HomeWidget.widgetClicked : const Stream.empty();
