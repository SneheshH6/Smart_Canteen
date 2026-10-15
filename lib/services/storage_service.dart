import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Curated high-resolution image presets for Canteen dishes
  static const List<String> foodImagePresets = [
    'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=800&q=80', // Masala Dosa
    'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?auto=format&fit=crop&w=800&q=80', // Puttu Kadala / Vada
    'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&q=80', // Appam Egg Curry
    'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?auto=format&fit=crop&w=800&q=80', // Idli Sambar
    'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=800&q=80', // Biriyani
    'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=800&q=80', // Samosa
    'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80', // Egg Puffs
    'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=800&q=80', // Lime Juice
    'https://images.unsplash.com/photo-1546173159-315724a31696?auto=format&fit=crop&w=800&q=80', // Mango Juice
  ];

  /// Simulates / uploads dish image to Cloud Storage and returns a public download URL
  Future<String> uploadFoodImage({
    required String filePath,
    required String foodName,
  }) async {
    debugPrint('Uploading food image for: $foodName from: $filePath');
    // In demo / sandbox mode, returns selected high quality preset
    return foodImagePresets[0];
  }
}
