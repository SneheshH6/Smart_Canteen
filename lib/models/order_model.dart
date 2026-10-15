import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'order_item_model.dart';

class OrderStatusConstants {
  // Canonical statuses
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String processing = 'processing';
  static const String ready = 'ready';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  // Backwards-compatibility aliases
  static const String placed = 'pending';
  static const String preparing = 'processing';

  static const List<String> allStatuses = [
    pending,
    accepted,
    processing,
    ready,
    completed,
  ];

  static String normalize(String? status) {
    if (status == null) return pending;
    final lower = status.trim().toLowerCase();
    if (lower == 'pending' || lower == 'placed' || lower == 'order placed' || lower == 'new' || lower == 'new orders') {
      return pending;
    }
    if (lower == 'accepted' || lower == 'kitchen accepted') {
      return accepted;
    }
    if (lower == 'processing' || lower == 'preparing' || lower == 'kitchen preparing' || lower == 'cooking') {
      return processing;
    }
    if (lower == 'ready' || lower == 'ready for pickup') {
      return ready;
    }
    if (lower == 'completed' || lower == 'order completed' || lower == 'done') {
      return completed;
    }
    if (lower == 'cancelled' || lower == 'canceled') {
      return cancelled;
    }
    return pending;
  }

  static String getLabel(String? status) {
    switch (normalize(status)) {
      case pending:
        return 'Order Placed';
      case accepted:
        return 'Kitchen Accepted';
      case processing:
        return 'Kitchen Preparing';
      case ready:
        return 'Ready for Pickup';
      case completed:
        return 'Order Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return 'Order Placed';
    }
  }

  static String getStatusDescription(String? status, {String? reason}) {
    switch (normalize(status)) {
      case pending:
        return 'Order sent to Kitchen. Waiting for acceptance.';
      case accepted:
        return 'Kitchen has accepted your order.';
      case processing:
        return 'Kitchen is processing & preparing your meal.';
      case ready:
        return 'Your food is ready for pickup at the counter!';
      case completed:
        return 'Order completed & handed over. Enjoy your meal!';
      case cancelled:
        if (reason != null && reason.trim().isNotEmpty) {
          return 'Cancelled by Kitchen: $reason';
        }
        return 'Your order was cancelled by the kitchen.';
      default:
        return 'Your order has been received.';
    }
  }

  static String? getNextStatus(String? currentStatus) {
    switch (normalize(currentStatus)) {
      case pending:
        return accepted;
      case accepted:
        return processing;
      case processing:
        return ready;
      case ready:
        return completed;
      case completed:
      case cancelled:
      default:
        return null;
    }
  }

  static String? getKitchenActionLabel(String? currentStatus) {
    switch (normalize(currentStatus)) {
      case pending:
        return 'Accept Order';
      case accepted:
        return 'Preparing';
      case processing:
        return 'Ready for Pickup';
      case ready:
        return 'Order Completed';
      default:
        return null;
    }
  }
}

class OrderModel {
  final String orderId;
  final String tokenNumber;
  final String userId;
  final String userName;
  final String studentName;
  final String userEmail;
  final String userPhone;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String? pickupNotes;
  final String? cancellationReason;
  final String? cancelledBy;
  final bool isRefunded;
  final double refundAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.orderId,
    required this.tokenNumber,
    required this.userId,
    required this.userName,
    String? studentName,
    this.userEmail = '',
    this.userPhone = '',
    required this.items,
    required this.totalAmount,
    this.paymentMethod = 'Wallet',
    this.paymentStatus = 'Paid',
    this.orderStatus = OrderStatusConstants.pending,
    this.pickupNotes,
    this.cancellationReason,
    this.cancelledBy,
    this.isRefunded = false,
    this.refundAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  }) : studentName = studentName ?? userName;

  int get itemCount => items.fold(0, (acc, item) => acc + item.quantity);

  String get foodItemsSummary =>
      items.map((e) => '${e.name} × ${e.quantity}').join(', ');

  String get normalizedStatus => OrderStatusConstants.normalize(orderStatus);
  String get statusLabel => OrderStatusConstants.getLabel(orderStatus);
  String get statusDescription =>
      OrderStatusConstants.getStatusDescription(orderStatus, reason: cancellationReason);

  bool get isPending => normalizedStatus == OrderStatusConstants.pending;
  bool get isPlaced => isPending;
  bool get isAccepted => normalizedStatus == OrderStatusConstants.accepted;
  bool get isProcessing => normalizedStatus == OrderStatusConstants.processing;
  bool get isPreparing => isProcessing;
  bool get isReady => normalizedStatus == OrderStatusConstants.ready;
  bool get isCompleted => normalizedStatus == OrderStatusConstants.completed;
  bool get isCancelled => normalizedStatus == OrderStatusConstants.cancelled;

  bool get isActive => isPending || isAccepted || isProcessing || isReady;

  int get statusStepIndex {
    switch (normalizedStatus) {
      case OrderStatusConstants.pending:
        return 0;
      case OrderStatusConstants.accepted:
        return 1;
      case OrderStatusConstants.processing:
        return 2;
      case OrderStatusConstants.ready:
        return 3;
      case OrderStatusConstants.completed:
        return 4;
      default:
        return 0;
    }
  }

  Color get statusColor {
    switch (normalizedStatus) {
      case OrderStatusConstants.pending:
        return const Color(0xFFD97706); // Amber
      case OrderStatusConstants.accepted:
        return const Color(0xFF7C3AED); // Purple / Indigo
      case OrderStatusConstants.processing:
        return const Color(0xFF2563EB); // Royal Blue
      case OrderStatusConstants.ready:
        return const Color(0xFF059669); // Emerald Green
      case OrderStatusConstants.completed:
        return const Color(0xFF059669); // Green / Success
      case OrderStatusConstants.cancelled:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Color get statusBgColor {
    switch (normalizedStatus) {
      case OrderStatusConstants.pending:
        return const Color(0xFFFEF3C7);
      case OrderStatusConstants.accepted:
        return const Color(0xFFEDE9FE);
      case OrderStatusConstants.processing:
        return const Color(0xFFDBEAFE);
      case OrderStatusConstants.ready:
        return const Color(0xFFD1FAE5);
      case OrderStatusConstants.completed:
        return const Color(0xFFD1FAE5);
      case OrderStatusConstants.cancelled:
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  IconData get statusIcon {
    switch (normalizedStatus) {
      case OrderStatusConstants.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatusConstants.accepted:
        return Icons.thumb_up_alt_rounded;
      case OrderStatusConstants.processing:
        return Icons.soup_kitchen_rounded;
      case OrderStatusConstants.ready:
        return Icons.notifications_active_rounded;
      case OrderStatusConstants.completed:
        return Icons.check_circle_rounded;
      case OrderStatusConstants.cancelled:
        return Icons.cancel_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'tokenNumber': tokenNumber,
      'userId': userId,
      'userName': userName,
      'studentName': studentName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'items': items.map((i) => i.toMap()).toList(),
      'foodItems': items.map((i) => i.toMap()).toList(),
      'quantity': itemCount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'orderStatus': OrderStatusConstants.normalize(orderStatus),
      'pickupNotes': pickupNotes,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      'isRefunded': isRefunded,
      'refundAmount': refundAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
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

    double parseDouble(dynamic value, double def) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? def;
      return def;
    }

    final rawItems = map['items'] ?? map['foodItems'];
    final List<OrderItemModel> itemsList = [];
    if (rawItems is Iterable) {
      for (final i in rawItems) {
        if (i is Map) {
          try {
            itemsList.add(OrderItemModel.fromMap(Map<String, dynamic>.from(i)));
          } catch (e) {
            debugPrint('Error parsing order item: $e');
          }
        }
      }
    }

    final sName = (map['studentName'] ?? map['userName'] ?? 'Student').toString();

    return OrderModel(
      orderId: (map['orderId'] ?? documentId ?? '').toString(),
      tokenNumber: (map['tokenNumber'] ?? '#100').toString(),
      userId: (map['userId'] ?? '').toString(),
      userName: sName,
      studentName: sName,
      userEmail: (map['userEmail'] ?? '').toString(),
      userPhone: (map['userPhone'] ?? '').toString(),
      items: itemsList,
      totalAmount: parseDouble(map['totalAmount'], 0.0),
      paymentMethod: (map['paymentMethod'] ?? 'Wallet').toString(),
      paymentStatus: (map['paymentStatus'] ?? 'Paid').toString(),
      orderStatus: OrderStatusConstants.normalize(map['orderStatus']?.toString()),
      pickupNotes: map['pickupNotes']?.toString(),
      cancellationReason: map['cancellationReason']?.toString(),
      cancelledBy: map['cancelledBy']?.toString(),
      isRefunded: map['isRefunded'] == true,
      refundAmount: parseDouble(map['refundAmount'], 0.0),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt'] ?? map['createdAt']),
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return OrderModel.fromMap(data, doc.id);
  }

  OrderModel copyWith({
    String? orderId,
    String? tokenNumber,
    String? userId,
    String? userName,
    String? studentName,
    String? userEmail,
    String? userPhone,
    List<OrderItemModel>? items,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    String? pickupNotes,
    String? cancellationReason,
    String? cancelledBy,
    bool? isRefunded,
    double? refundAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final name = userName ?? this.userName;
    return OrderModel(
      orderId: orderId ?? this.orderId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      userId: userId ?? this.userId,
      userName: name,
      studentName: studentName ?? name,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus != null
          ? OrderStatusConstants.normalize(orderStatus)
          : this.orderStatus,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      isRefunded: isRefunded ?? this.isRefunded,
      refundAmount: refundAmount ?? this.refundAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
