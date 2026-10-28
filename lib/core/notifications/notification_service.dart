import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'habitual_reminders.dart';

/// RF20: notificación local cuando un gasto recurrente se registra
/// automáticamente (catch-up de RF12) y deja a su categoría en 80%/100% del
/// presupuesto. Pide el permiso correspondiente en Android 13+.
///
/// RF48: también muestra los recordatorios de gastos habituales, con las
/// acciones "Registrar" y "Hoy no" (ver habitual_reminders.dart).
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  /// Respuesta a una notificación con la app abierta. La fija RootShell para
  /// usar su propia conexión a la base (y que las pantallas se actualicen).
  void Function(NotificationResponse response)? onForegroundResponse;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // En iOS las acciones se declaran por categoría, antes de usarlas.
    final habitualCategory = DarwinNotificationCategory(
      kHabitualDarwinCategory,
      actions: [
        DarwinNotificationAction.plain(kHabitualRegisterAction, 'Registrar'),
        DarwinNotificationAction.plain(kHabitualSkipAction, 'Hoy no'),
      ],
    );
    final iosSettings = DarwinInitializationSettings(
        notificationCategories: [habitualCategory]);
    final macSettings = DarwinInitializationSettings(
        notificationCategories: [habitualCategory]);
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macSettings,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) =>
          onForegroundResponse?.call(response),
      onDidReceiveBackgroundNotificationResponse:
          habitualNotificationBackgroundHandler,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showBudgetAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Alertas de presupuesto',
      channelDescription:
          'Avisa cuando un gasto recurrente automático deja una categoría cerca o sobre su presupuesto.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      web: WebNotificationDetails(),
    );
    await _plugin.show(
        id: id, title: title, body: body, notificationDetails: details);
  }
}
