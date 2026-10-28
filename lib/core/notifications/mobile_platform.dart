import 'mobile_platform_native.dart'
    if (dart.library.js_interop) 'mobile_platform_web.dart';

/// true solo en Android e iOS, donde hay notificaciones programadas. Falso en
/// web, escritorio y en los tests (que corren en el sistema anfitrión).
bool get isMobileDevice => isMobilePlatform();
