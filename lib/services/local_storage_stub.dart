class LocalStorageImpl {
  static final Map<String, String> _memoryStore = {};

  static void saveString(String key, String value) {
    _memoryStore[key] = value;
  }

  static String? getString(String key) {
    return _memoryStore[key];
  }

  static void remove(String key) {
    _memoryStore.remove(key);
  }
}
