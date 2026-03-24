/// Conditional export: web popup on web, system browser on native.
export 'oauth_launcher_stub.dart'
    if (dart.library.html) 'oauth_launcher_web.dart';
