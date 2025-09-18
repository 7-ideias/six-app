// Implementação específica para web
import 'dart:html' as html;

class WebHelpers {
  String getOrigin() {
    return html.window.location.origin;
  }

  void openNewTab(String url) {
    html.window.open(url, '_blank');
  }

  void setLocalStorage(String key, String value) {
    html.window.localStorage[key] = value;
  }

  String? getLocalStorage(String key) {
    return html.window.localStorage[key];
  }

  void removeLocalStorage(String key) {
    html.window.localStorage.remove(key);
  }

  void redirectTo(String url) {
    html.window.location.href = url;
  }
}
