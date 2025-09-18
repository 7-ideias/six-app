// Stub para plataformas não-web
class WebHelpers {
  String getOrigin() => '';
  void openNewTab(String url) {}
  void setLocalStorage(String key, String value) {}
  String? getLocalStorage(String key) => null;
  void removeLocalStorage(String key) {}
  void redirectTo(String url) {}
}
