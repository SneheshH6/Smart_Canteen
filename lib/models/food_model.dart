import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel {
  final String foodId;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool available;
  final double rating;
  final int ratingCount;
  final int preparationTime; // in minutes
  final bool isVeg;
  final int calories;
  final DateTime createdAt;

  const FoodModel({
    required this.foodId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.available,
    this.rating = 4.5,
    this.ratingCount = 20,
    this.preparationTime = 10,
    this.isVeg = true,
    this.calories = 300,
    required this.createdAt,
  });

  int get prepTimeMinutes => preparationTime;

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'available': available,
      'rating': rating,
      'ratingCount': ratingCount,
      'preparationTime': preparationTime,
      'isVeg': isVeg,
      'calories': calories,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FoodModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    double parseDouble(dynamic value, double defaultValue) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    int parseInt(dynamic value, int defaultValue) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return FoodModel(
      foodId: (map['foodId'] ?? documentId ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: parseDouble(map['price'], 0.0),
      category: (map['category'] ?? 'All').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      available: (map['available'] ?? true) as bool,
      rating: parseDouble(map['rating'], 4.5),
      ratingCount: parseInt(map['ratingCount'], 20),
      preparationTime: parseInt(map['preparationTime'], 10),
      isVeg: (map['isVeg'] ?? true) as bool,
      calories: parseInt(map['calories'], 250),
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory FoodModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FoodModel.fromMap(data, doc.id);
  }

  FoodModel copyWith({
    String? foodId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? available,
    double? rating,
    int? ratingCount,
    int? preparationTime,
    bool? isVeg,
    int? calories,
    DateTime? createdAt,
  }) {
    return FoodModel(
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      available: available ?? this.available,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      preparationTime: preparationTime ?? this.preparationTime,
      isVeg: isVeg ?? this.isVeg,
      calories: calories ?? this.calories,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
