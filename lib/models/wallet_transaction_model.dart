import 'package:cloud_firestore/cloud_firestore.dart';

class WalletTransactionModel {
  final String transactionId;
  final String userId;
  final String? orderId;
  final String type; // 'credit' (money added) or 'debit' (food purchase)
  final double amount;
  final double balanceAfter;
  final String description; // e.g. "Chicken Biriyani × 1", "Wallet Top-Up via UPI"
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.transactionId,
    required this.userId,
    this.orderId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'userId': userId,
      'orderId': orderId,
      'type': type,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
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

    return WalletTransactionModel(
      transactionId: (map['transactionId'] ?? documentId ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      orderId: map['orderId']?.toString(),
      type: (map['type'] ?? 'debit').toString().toLowerCase(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (map['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      description: (map['description'] ?? 'Wallet Transaction').toString(),
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory WalletTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return WalletTransactionModel.fromMap(data, doc.id);
  }
}
