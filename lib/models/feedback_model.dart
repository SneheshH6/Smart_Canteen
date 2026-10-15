import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackTypeConstants {
  static const String feedback = 'Feedback';
  static const String complaint = 'Complaint';
  static const String suggestion = 'Suggestion';

  static const List<String> allTypes = [feedback, complaint, suggestion];
}

class FeedbackModel {
  final String feedbackId;
  final String userId;
  final String userName;
  final String orderId;
  final String foodId;
  final double foodRating;
  final double serviceRating;
  final String type; // 'Feedback', 'Complaint', 'Suggestion'
  final String comment;
  final DateTime createdAt;

  const FeedbackModel({
    required this.feedbackId,
    required this.userId,
    required this.userName,
    required this.orderId,
    this.foodId = '',
    required this.foodRating,
    required this.serviceRating,
    this.type = FeedbackTypeConstants.feedback,
    required this.comment,
    required this.createdAt,
  });

  double get averageRating => (foodRating + serviceRating) / 2;

  Map<String, dynamic> toMap() {
    return {
      'feedbackId': feedbackId,
      'userId': userId,
      'userName': userName,
      'orderId': orderId,
      'foodId': foodId,
      'foodRating': foodRating,
      'serviceRating': serviceRating,
      'type': type,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    double parseRating(dynamic value, double def) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? def;
      return def;
    }

    return FeedbackModel(
      feedbackId: (map['feedbackId'] ?? docId ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? 'User').toString(),
      orderId: (map['orderId'] ?? '').toString(),
      foodId: (map['foodId'] ?? '').toString(),
      foodRating: parseRating(map['foodRating'] ?? map['rating'], 5.0),
      serviceRating: parseRating(map['serviceRating'], 5.0),
      type: (map['type'] ?? FeedbackTypeConstants.feedback).toString(),
      comment: (map['comment'] ?? '').toString(),
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FeedbackModel.fromMap(data, doc.id);
  }
}
