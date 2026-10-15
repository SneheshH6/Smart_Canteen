import 'package:cloud_firestore/cloud_firestore.dart';

class FoodReviewModel {
  final String reviewId;
  final String foodId;
  final String foodName;
  final String orderId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const FoodReviewModel({
    required this.reviewId,
    required this.foodId,
    required this.foodName,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'foodId': foodId,
      'foodName': foodName,
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FoodReviewModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    double parseDouble(dynamic value, double def) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? def;
      return def;
    }

    return FoodReviewModel(
      reviewId: (map['reviewId'] ?? docId ?? '').toString(),
      foodId: (map['foodId'] ?? '').toString(),
      foodName: (map['foodName'] ?? 'Food Item').toString(),
      orderId: (map['orderId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? 'Student').toString(),
      rating: parseDouble(map['rating'], 5.0),
      comment: (map['comment'] ?? '').toString(),
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory FoodReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FoodReviewModel.fromMap(data, doc.id);
  }
}
