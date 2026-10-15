import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'cart_provider.dart';

class OrderProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  String? _errorMessage;
  StreamSubscription? _ordersSubscription;

  List<OrderModel> get allOrders => _allOrders;
  List<OrderModel> get activeOrders =>
      _allOrders.where((o) => o.isActive).toList();
  List<OrderModel> get completedOrders =>
      _allOrders.where((o) => o.isCompleted).toList();
  List<OrderModel> get pastOrders =>
      _allOrders.where((o) => !o.isActive).toList();

  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get errorMessage => _errorMessage;

  void initOrdersStream(String userId) {
    _isLoading = true;
    notifyListeners();

    _ordersSubscription?.cancel();
    _ordersSubscription =
        _firestoreService.getUserOrdersStream(userId).listen(
      (orders) {
        _allOrders = orders;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<OrderModel?> placeOrder({
    required UserModel user,
    required CartProvider cart,
    required String paymentMethod,
    String? pickupNotes,
  }) async {
    if (cart.items.isEmpty) {
      _errorMessage = 'Your cart is empty. Please add food items first.';
      notifyListeners();
      return null;
    }

    _isPlacingOrder = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final total = cart.grandTotal;

      // CANTEEN SCHEDULE CHECK (IST: 8:00 AM - 5:30 PM)
      final schedule = await _firestoreService.getCanteenSchedule();
      if (!schedule.isCanteenOpen) {
        _isPlacingOrder = false;
        _errorMessage = 'Canteen is currently closed. Ordering will reopen tomorrow at ${schedule.openTimeFormatted}.';
        notifyListeners();
        return null;
      }

      // FOOD STOCK / AVAILABILITY CHECK
      for (final cartItem in cart.itemsList) {
        final foodDoc = await _firestoreService.getFoodById(cartItem.food.foodId);
        if (foodDoc != null && !foodDoc.available) {
          _isPlacingOrder = false;
          _errorMessage = '"${foodDoc.name}" is currently SOLD OUT. Please remove it from your tray to proceed.';
          notifyListeners();
          return null;
        }
      }

      // PREPAID WALLET BALANCE CHECK
      final isWalletPayment = paymentMethod.toLowerCase().contains('wallet') ||
          paymentMethod.toLowerCase().contains('meal pass');

      if (isWalletPayment) {
        final currentBalance = await _firestoreService.getWalletBalance(user.userId);
        if (currentBalance < total) {
          final shortfall = total - currentBalance;
          _isPlacingOrder = false;
          _errorMessage = 'Insufficient wallet balance. Please add ₹${shortfall.toStringAsFixed(0)}.';
          notifyListeners();
          return null;
        }
      }

      final now = DateTime.now();
      final random = Random();
      final randomToken = random.nextInt(90) + 10; // e.g. 10 - 99
      final orderRandomSuffix = random.nextInt(9000) + 1000;
      final orderId = 'ORD-${now.millisecondsSinceEpoch.toString().substring(7)}-$orderRandomSuffix';
      final tokenNumber = '#$randomToken';

      final List<OrderItemModel> orderItems = cart.itemsList.map((cartItem) {
        return OrderItemModel(
          foodId: cartItem.food.foodId,
          name: cartItem.food.name,
          price: cartItem.food.price,
          quantity: cartItem.quantity,
          imageUrl: cartItem.food.imageUrl,
          specialInstructions: cartItem.specialInstructions,
        );
      }).toList();

      final itemsSummary = orderItems.map((e) => '${e.name} × ${e.quantity}').join(', ');

      // Deduct wallet balance if paying with wallet
      if (isWalletPayment) {
        await _firestoreService.deductWalletMoney(
          user.userId,
          total,
          orderId: orderId,
          description: itemsSummary,
        );
      }

      final newOrder = OrderModel(
        orderId: orderId,
        tokenNumber: tokenNumber,
        userId: user.userId,
        userName: user.name,
        studentName: user.name,
        userEmail: user.email,
        userPhone: user.phone,
        items: orderItems,
        totalAmount: total,
        paymentMethod: paymentMethod,
        paymentStatus: (isWalletPayment || paymentMethod.toUpperCase().contains('UPI') || paymentMethod.toUpperCase().contains('CARD')) ? 'Paid' : 'Pending',
        orderStatus: OrderStatusConstants.pending,
        pickupNotes: pickupNotes,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.createOrder(newOrder);

      // Clear cart on successful order creation
      cart.clearCart();

      _isPlacingOrder = false;
      notifyListeners();
      return newOrder;
    } catch (e) {
      _isPlacingOrder = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return null;
    }
  }

  Stream<OrderModel?> getSingleOrderStream(String orderId) {
    return _firestoreService.getOrderStream(orderId);
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? cancellationReason,
    String? cancelledBy,
  }) async {
    final canonical = OrderStatusConstants.normalize(newStatus);
    await _firestoreService.updateOrderStatus(
      orderId,
      canonical,
      cancellationReason: cancellationReason,
      cancelledBy: cancelledBy,
    );
  }

  Future<void> cancelOrder(
    String orderId, {
    required String reason,
    String cancelledBy = 'Kitchen',
  }) async {
    await _firestoreService.cancelOrder(
      orderId,
      reason: reason,
      cancelledBy: cancelledBy,
    );
  }

  Future<String?> advanceOrderToNextStatus(OrderModel order) async {
    final next = OrderStatusConstants.getNextStatus(order.orderStatus);
    if (next != null) {
      await _firestoreService.updateOrderStatus(order.orderId, next);
      return next;
    }
    return null;
  }

  Future<void> advanceOrderStatus(String orderId, String nextStatus) async {
    final canonical = OrderStatusConstants.normalize(nextStatus);
    await _firestoreService.updateOrderStatus(orderId, canonical);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
