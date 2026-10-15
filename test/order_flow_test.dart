import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/models/food_model.dart';
import 'package:smart_canteen/models/order_model.dart';
import 'package:smart_canteen/models/user_model.dart';
import 'package:smart_canteen/services/firestore_service.dart';
import 'package:smart_canteen/providers/cart_provider.dart';
import 'package:smart_canteen/providers/order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Complete Order Flow: Student Checkout -> Kitchen Queue -> Preparation -> User Tracking', () async {
    final firestoreService = FirestoreService();
    final orderProvider = OrderProvider();
    final cartProvider = CartProvider();

    // 1. Setup Student and Food item (Masala Dosa)
    final testStudent = UserModel(
      userId: 'test_student_001',
      name: 'Rohan Sharma',
      email: 'rohan@canteen.edu',
      phone: '9876543210',
      role: 'student',
      walletBalance: 500.0,
      createdAt: DateTime.now(),
    );

    final dosaFood = FoodModel(
      foodId: 'food_masala_dosa',
      name: 'Masala Dosa',
      description: 'Crispy rice crepe filled with spiced potato masala',
      price: 60.0,
      category: 'South Indian',
      imageUrl: 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600',
      available: true,
      preparationTime: 10,
      createdAt: DateTime.now(),
    );

    cartProvider.addItem(dosaFood, quantity: 1, specialInstructions: 'Extra crispy please');

    // Listen to Kitchen Orders Stream
    List<OrderModel> kitchenOrdersList = [];
    final kitchenSubscription = firestoreService.getAllOrdersStream().listen((orders) {
      kitchenOrdersList = orders;
    });

    // 2. Student places order via OrderProvider
    final placedOrder = await orderProvider.placeOrder(
      user: testStudent,
      cart: cartProvider,
      paymentMethod: 'UPI',
    );

    expect(placedOrder, isNotNull);
    expect(placedOrder!.orderId.isNotEmpty, isTrue);
    expect(placedOrder.tokenNumber.isNotEmpty, isTrue);
    expect(placedOrder.userName, equals('Rohan Sharma'));
    expect(placedOrder.totalAmount, equals(65.0)); // 60 + 5 fee
    expect(OrderStatusConstants.normalize(placedOrder.orderStatus), equals(OrderStatusConstants.pending));

    // Yield to allow stream events to propagate
    await Future.delayed(const Duration(milliseconds: 50));

    // 3. Verify Kitchen Module immediately receives the order without refresh
    expect(kitchenOrdersList.any((o) => o.orderId == placedOrder.orderId), isTrue);
    final kitchenReceivedOrder = kitchenOrdersList.firstWhere((o) => o.orderId == placedOrder.orderId);
    expect(kitchenReceivedOrder.isPending, isTrue);
    expect(kitchenReceivedOrder.items.first.name, equals('Masala Dosa'));

    // 4. Kitchen staff accepts the order
    await orderProvider.advanceOrderStatus(placedOrder.orderId, OrderStatusConstants.accepted);
    await Future.delayed(const Duration(milliseconds: 50));

    final acceptedOrder = kitchenOrdersList.firstWhere((o) => o.orderId == placedOrder.orderId);
    expect(acceptedOrder.isAccepted, isTrue);
    expect(acceptedOrder.orderStatus, equals(OrderStatusConstants.accepted));

    // 5. Kitchen staff begins preparing the food
    await orderProvider.advanceOrderStatus(placedOrder.orderId, OrderStatusConstants.processing);
    await Future.delayed(const Duration(milliseconds: 50));

    final preparingOrder = kitchenOrdersList.firstWhere((o) => o.orderId == placedOrder.orderId);
    expect(preparingOrder.isProcessing, isTrue);

    // 6. Kitchen staff marks order Ready for Pickup
    await orderProvider.advanceOrderStatus(placedOrder.orderId, OrderStatusConstants.ready);
    await Future.delayed(const Duration(milliseconds: 50));

    final readyOrder = kitchenOrdersList.firstWhere((o) => o.orderId == placedOrder.orderId);
    expect(readyOrder.isReady, isTrue);

    // 7. Kitchen staff hands over food and completes order
    await orderProvider.advanceOrderStatus(placedOrder.orderId, OrderStatusConstants.completed);
    await Future.delayed(const Duration(milliseconds: 50));

    final completedOrder = kitchenOrdersList.firstWhere((o) => o.orderId == placedOrder.orderId);
    expect(completedOrder.isCompleted, isTrue);

    // 8. Verify user's order stream reflects completion in real time
    final userOrder = await firestoreService.getOrderStream(placedOrder.orderId).first;
    expect(userOrder, isNotNull);
    expect(userOrder!.isCompleted, isTrue);

    await kitchenSubscription.cancel();
  });
}
