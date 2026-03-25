// Web-only implementation — compiled only when dart.library.html is available.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Opens a GitHub OAuth popup and invokes [callback] with [true] on success,
/// [false] if the user denied or an error occurred.
void startOAuth(String url, void Function(bool success) callback) {
  html.window.open(
    url,
    'github_oauth',
    'width=600,height=700,menubar=no,toolbar=no',
  );
  html.window.onMessage.take(1).listen((event) {
    if (event.data is String &&
        (event.data as String).startsWith('github_oauth:')) {
      final code =
          (event.data as String).split(':').sublist(1).join(':');
      callback(code != 'error');
    }
  });
}
