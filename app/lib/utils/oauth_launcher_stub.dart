// Native stub (macOS / iOS / Android / desktop).
// Opens the URL in the system browser.
// The caller should poll the /github/profile/ API to detect completion.
import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the system browser and returns immediately.
/// [callback] is intentionally NOT called here — instead the screen polls
/// the backend profile endpoint to detect when auth has completed.
void startOAuth(String url, void Function(bool success) callback) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
