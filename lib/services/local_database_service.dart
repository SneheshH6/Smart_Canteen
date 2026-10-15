import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalDatabaseService {
  static const String boxName = 'smart_canteen_db';
  static Box? _box;
  static final Map<String, dynamic> _memoryFallback = {};

  /// Initialize Hive local database
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(boxName);
      debugPrint('📦 Hive Local Database initialized successfully. Keys loaded: ${_box?.keys.length ?? 0}');
    } catch (e) {
      debugPrint('⚠️ Hive initialization error: $e. Falling back to in-memory store.');
    }
  }

  static void saveString(String key, String value) {
    try {
      if (_box != null && _box!.isOpen) {
        _box!.put(key, value);
      } else {
        _memoryFallback[key] = value;
      }
    } catch (e) {
      debugPrint('Hive put error for $key: $e');
      _memoryFallback[key] = value;
    }
  }

  static String? getString(String key) {
    try {
      if (_box != null && _box!.isOpen) {
        final val = _box!.get(key);
        if (val is String) return val;
      }
      final fallback = _memoryFallback[key];
      if (fallback is String) return fallback;
      return null;
    } catch (e) {
      debugPrint('Hive get error for $key: $e');
      final fallback = _memoryFallback[key];
      if (fallback is String) return fallback;
      return null;
    }
  }

  static void saveJson(String key, dynamic value) {
    try {
      final jsonString = jsonEncode(value, toEncodable: (nonEncodable) {
        if (nonEncodable is DateTime) {
          return nonEncodable.toIso8601String();
        }
        return nonEncodable.toString();
      });
      if (_box != null && _box!.isOpen) {
        _box!.put(key, jsonString);
      } else {
        _memoryFallback[key] = jsonString;
      }
    } catch (e) {
      debugPrint('Hive saveJson error for $key: $e');
    }
  }

  static dynamic getJson(String key) {
    try {
      String? jsonString;
      if (_box != null && _box!.isOpen) {
        final val = _box!.get(key);
        if (val is String && val.isNotEmpty) {
          jsonString = val;
        }
      }
      jsonString ??= _memoryFallback[key] as String?;

      if (jsonString == null || jsonString.isEmpty) return null;
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Hive getJson error for $key: $e');
      return null;
    }
  }

  static void remove(String key) {
    try {
      if (_box != null && _box!.isOpen) {
        _box!.delete(key);
      }
      _memoryFallback.remove(key);
    } catch (e) {
      debugPrint('Hive remove error for $key: $e');
      _memoryFallback.remove(key);
    }
  }

  static Future<void> clearAll() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.clear();
      }
      _memoryFallback.clear();
    } catch (e) {
      debugPrint('Hive clearAll error: $e');
      _memoryFallback.clear();
    }
  }
}
