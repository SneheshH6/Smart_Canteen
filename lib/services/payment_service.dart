import 'dart:async';
import 'package:flutter/foundation.dart';

enum PaymentStatus {
  pending,
  successful,
  failed,
}

enum PaymentMethodType {
  upi,
  mealPass,
  counterCash,
  card,
}

class PaymentResult {
  final bool isSuccess;
  final String transactionId;
  final String message;
  final PaymentStatus status;
  final DateTime timestamp;

  const PaymentResult({
    required this.isSuccess,
    required this.transactionId,
    required this.message,
    required this.status,
    required this.timestamp,
  });
}

abstract class BasePaymentService {
  Future<PaymentResult> processPayment({
    required double amount,
    required String orderId,
    required PaymentMethodType methodType,
    String? upiId,
    bool forceFailure = false,
  });
}

/// Safe Mock/Sandbox payment implementation for Development & Academic Project evaluation
/// Does not collect or store sensitive credentials (no card numbers, CVVs, or bank passwords).
class PaymentService implements BasePaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  @override
  Future<PaymentResult> processPayment({
    required double amount,
    required String orderId,
    required PaymentMethodType methodType,
    String? upiId,
    bool forceFailure = false,
  }) async {
    debugPrint('Processing payment of ₹$amount for Order: $orderId via ${methodType.name}');

    // Simulate realistic payment gateway processing delay
    await Future.delayed(const Duration(milliseconds: 1800));

    if (forceFailure) {
      return PaymentResult(
        isSuccess: false,
        transactionId: 'TXN_FAIL_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Payment was declined by the bank. Please try another payment method.',
        status: PaymentStatus.failed,
        timestamp: DateTime.now(),
      );
    }

    final txnId = 'TXN_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    return PaymentResult(
      isSuccess: true,
      transactionId: txnId,
      message: 'Payment of ₹${amount.toStringAsFixed(2)} completed successfully.',
      status: PaymentStatus.successful,
      timestamp: DateTime.now(),
    );
  }

  String getMethodDisplayName(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.upi:
        return 'UPI / GPay / PhonePe / Paytm';
      case PaymentMethodType.mealPass:
        return 'Campus Meal Pass / User Wallet';
      case PaymentMethodType.counterCash:
        return 'Pay Cash at Canteen Counter';
      case PaymentMethodType.card:
        return 'Credit / Debit Card (Sandbox)';
    }
  }
}
