import 'package:flutter_test/flutter_test.dart';
import 'package:smart_canteen/core/utils/currency_formatter.dart';
import 'package:smart_canteen/core/utils/validators.dart';
import 'package:smart_canteen/models/feedback_model.dart';
import 'package:smart_canteen/models/food_model.dart';
import 'package:smart_canteen/models/order_item_model.dart';
import 'package:smart_canteen/models/order_model.dart';
import 'package:smart_canteen/models/user_model.dart';
import 'package:smart_canteen/providers/cart_provider.dart';
import 'package:smart_canteen/services/auth_service.dart';
import 'package:smart_canteen/services/payment_service.dart';

void main() {
  group('Validators Tests', () {
    test('Email validator validates valid and invalid emails', () {
      expect(Validators.validateEmail('student@canteen.com'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('Password validator validates minimum length', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
    });

    test('Phone validator validates 10 digits', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
    });

    test('Confirm password validator checks equality', () {
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
      expect(Validators.validateConfirmPassword('pass123', 'pass456'), isNotNull);
    });
  });

  group('Currency Formatter Tests', () {
    test('CurrencyFormatter formats Rupee symbol properly', () {
      expect(CurrencyFormatter.format(60.0), contains('60'));
      expect(CurrencyFormatter.format(130.50), contains('130.50'));
    });
  });

  group('Model Serialization Tests', () {
    test('UserModel serializes and deserializes correctly with memberId / studentId', () {
      final now = DateTime.now();
      final user = UserModel(
        userId: 'test_u1',
        studentId: 'USR2026-104',
        name: 'Rahul Sharma',
        email: 'rahul@canteen.com',
        phone: '9876543210',
        role: 'user',
        createdAt: now,
      );

      expect(user.isUser, isTrue);
      expect(user.isStudent, isTrue); // backward compatibility alias
      expect(user.isAdmin, isFalse);
      expect(user.isStaff, isFalse);
      expect(user.studentId, equals('USR2026-104'));
      expect(user.memberId, equals('USR2026-104'));

      final map = user.toMap();
      final fromMap = UserModel.fromMap(map, 'test_u1');
      expect(fromMap.userId, equals('test_u1'));
      expect(fromMap.studentId, equals('USR2026-104'));
      expect(fromMap.memberId, equals('USR2026-104'));
      expect(fromMap.name, equals('Rahul Sharma'));
      expect(fromMap.email, equals('rahul@canteen.com'));
      expect(fromMap.isUser, isTrue);
    });

    test('FoodModel serializes correctly', () {
      final food = FoodModel(
        foodId: 'bf_01',
        name: 'Masala Dosa',
        description: 'Crispy golden dosa filled with a flavorful masala potato filling, served as a delicious and satisfying breakfast.',
        price: 90.0,
        category: 'Breakfast',
        imageUrl: 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=800&q=80',
        available: true,
        createdAt: DateTime.now(),
      );

      expect(food.foodId, equals('bf_01'));
      expect(food.price, equals(90.0));
      expect(food.available, isTrue);
    });
  });

  group('AuthService One-Time Registration & Duplicate Prevention Tests', () {
    test('signUpWithEmailPassword rejects duplicate email registration', () async {
      final authService = AuthService();
      expect(
        () async => await authService.signUpWithEmailPassword(
          name: 'Snehesh',
          studentId: 'USR-NEW-99',
          email: 'user@canteen.com', // Pre-existing email
          phone: '9876543210',
          password: 'password123',
        ),
        throwsA(contains('An account with this email already exists')),
      );
    });

    test('signUpWithEmailPassword rejects duplicate User ID registration', () async {
      final authService = AuthService();
      expect(
        () async => await authService.signUpWithEmailPassword(
          name: 'Another User',
          studentId: 'USR2026-001', // Pre-existing user ID
          email: 'unique_user@canteen.com',
          phone: '9876543211',
          password: 'password123',
        ),
        throwsA(contains('This User ID is already registered')),
      );
    });

    test('signUpWithEmailPassword succeeds for unique credentials and assigns user role', () async {
      final authService = AuthService();
      final uniqueEmail = 'new_user_${DateTime.now().millisecondsSinceEpoch}@canteen.com';
      final uniqueId = 'USR_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final user = await authService.signUpWithEmailPassword(
        name: 'New Registered User',
        studentId: uniqueId,
        email: uniqueEmail,
        phone: '9876543219',
        password: 'password123',
      );

      expect(user.isUser, isTrue);
      expect(user.email, equals(uniqueEmail));
      expect(user.studentId, equals(uniqueId));
      expect(user.userId, isNotEmpty);
    });
  });

  group('CartProvider Tests', () {
    test('CartProvider correctly calculates subtotal and grandTotal', () {
      final cart = CartProvider();
      final food1 = FoodModel(
        foodId: 'bf_01',
        name: 'Masala Dosa',
        description: 'Crispy golden dosa',
        price: 90.0,
        category: 'Breakfast',
        imageUrl: '',
        available: true,
        createdAt: DateTime.now(),
      );
      final food2 = FoodModel(
        foodId: 'cd_01',
        name: 'Lime Juice',
        description: 'Fresh lime juice',
        price: 25.0,
        category: 'Cool Drinks',
        imageUrl: '',
        available: true,
        createdAt: DateTime.now(),
      );

      expect(cart.totalCount, equals(0));
      expect(cart.subtotal, equals(0.0));
      expect(cart.grandTotal, equals(0.0));

      cart.addItem(food1, quantity: 2);
      expect(cart.totalCount, equals(2));
      expect(cart.subtotal, equals(180.0));
      expect(cart.canteenConvenienceFee, equals(5.0));
      expect(cart.grandTotal, equals(185.0));

      cart.addItem(food2, quantity: 1);
      expect(cart.totalCount, equals(3));
      expect(cart.subtotal, equals(205.0));
      expect(cart.grandTotal, equals(210.0));

      cart.updateQuantity('bf_01', 1);
      expect(cart.totalCount, equals(2));
      expect(cart.subtotal, equals(115.0));

      cart.removeItem('bf_01');
      expect(cart.totalCount, equals(1));
      expect(cart.subtotal, equals(25.0));

      cart.clearCart();
      expect(cart.totalCount, equals(0));
      expect(cart.subtotal, equals(0.0));
    });
  });

  group('OrderModel and 5-Step Status Flow Tests', () {
    test('OrderModel calculations and 5-step strict status sequence works accurately', () {
      final now = DateTime.now();
      final order = OrderModel(
        orderId: 'ORD_1001',
        tokenNumber: '#TK042',
        userId: 'student_1',
        userName: 'Priya Patel',
        userEmail: 'priya@college.edu',
        items: [
          const OrderItemModel(
            foodId: 'f1',
            name: 'Masala Dosa',
            price: 90.0,
            quantity: 2,
            imageUrl: '',
          ),
          const OrderItemModel(
            foodId: 'f2',
            name: 'Lime Juice',
            price: 25.0,
            quantity: 1,
            imageUrl: '',
          ),
        ],
        totalAmount: 205.0,
        paymentMethod: 'UPI',
        paymentStatus: 'Paid',
        orderStatus: OrderStatusConstants.placed,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Placed
      expect(order.itemCount, equals(3));
      expect(order.isPlaced, isTrue);
      expect(order.isPending, isTrue);
      expect(order.isActive, isTrue);
      expect(order.isCompleted, isFalse);
      expect(order.statusStepIndex, equals(0));
      expect(order.statusLabel, equals('Order Placed'));
      expect(OrderStatusConstants.getNextStatus(order.orderStatus), equals(OrderStatusConstants.accepted));
      expect(OrderStatusConstants.getKitchenActionLabel(order.orderStatus), equals('Accept Order'));

      // 2. Accepted
      final acceptedOrder = order.copyWith(orderStatus: OrderStatusConstants.accepted);
      expect(acceptedOrder.isAccepted, isTrue);
      expect(acceptedOrder.isActive, isTrue);
      expect(acceptedOrder.statusStepIndex, equals(1));
      expect(acceptedOrder.statusLabel, equals('Kitchen Accepted'));
      expect(OrderStatusConstants.getNextStatus(acceptedOrder.orderStatus), equals(OrderStatusConstants.preparing));
      expect(OrderStatusConstants.getKitchenActionLabel(acceptedOrder.orderStatus), equals('Preparing'));

      // 3. Preparing
      final preparingOrder = order.copyWith(orderStatus: OrderStatusConstants.preparing);
      expect(preparingOrder.isPreparing, isTrue);
      expect(preparingOrder.isActive, isTrue);
      expect(preparingOrder.statusStepIndex, equals(2));
      expect(preparingOrder.statusLabel, equals('Kitchen Preparing'));
      expect(OrderStatusConstants.getNextStatus(preparingOrder.orderStatus), equals(OrderStatusConstants.ready));
      expect(OrderStatusConstants.getKitchenActionLabel(preparingOrder.orderStatus), equals('Ready for Pickup'));

      // 4. Ready
      final readyOrder = order.copyWith(orderStatus: OrderStatusConstants.ready);
      expect(readyOrder.isReady, isTrue);
      expect(readyOrder.isActive, isTrue);
      expect(readyOrder.statusStepIndex, equals(3));
      expect(readyOrder.statusLabel, equals('Ready for Pickup'));
      expect(OrderStatusConstants.getNextStatus(readyOrder.orderStatus), equals(OrderStatusConstants.completed));
      expect(OrderStatusConstants.getKitchenActionLabel(readyOrder.orderStatus), equals('Order Completed'));

      // 5. Completed
      final completedOrder = order.copyWith(orderStatus: OrderStatusConstants.completed);
      expect(completedOrder.isCompleted, isTrue);
      expect(completedOrder.isActive, isFalse);
      expect(completedOrder.statusStepIndex, equals(4));
      expect(completedOrder.statusLabel, equals('Order Completed'));
      expect(OrderStatusConstants.getNextStatus(completedOrder.orderStatus), isNull);
      expect(OrderStatusConstants.getKitchenActionLabel(completedOrder.orderStatus), isNull);
    });
  });

  group('PaymentService Tests', () {
    test('PaymentService simulates successful payment', () async {
      final paymentService = PaymentService();
      final result = await paymentService.processPayment(
        amount: 250.0,
        orderId: 'ORD_TEST_01',
        methodType: PaymentMethodType.upi,
        forceFailure: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(PaymentStatus.successful));
      expect(result.transactionId, startsWith('TXN_'));
    });

    test('PaymentService handles forced failure scenario gracefully', () async {
      final paymentService = PaymentService();
      final result = await paymentService.processPayment(
        amount: 150.0,
        orderId: 'ORD_TEST_02',
        methodType: PaymentMethodType.mealPass,
        forceFailure: true,
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PaymentStatus.failed));
      expect(result.transactionId, startsWith('TXN_FAIL_'));
    });
  });

  group('FeedbackModel Tests', () {
    test('FeedbackModel serializes and computes averageRating accurately', () {
      final now = DateTime.now();
      final feedback = FeedbackModel(
        feedbackId: 'fb_101',
        userId: 'student_1',
        userName: 'Priya Patel',
        orderId: 'ORD_1001',
        foodRating: 4.0,
        serviceRating: 5.0,
        type: FeedbackTypeConstants.feedback,
        comment: 'Delicious Masala Dosa and quick counter service!',
        createdAt: now,
      );

      expect(feedback.averageRating, equals(4.5));
      expect(feedback.type, equals('Feedback'));

      final map = feedback.toMap();
      final fromMap = FeedbackModel.fromMap(map, 'fb_101');
      expect(fromMap.feedbackId, equals('fb_101'));
      expect(fromMap.foodRating, equals(4.0));
      expect(fromMap.serviceRating, equals(5.0));
      expect(fromMap.comment, equals('Delicious Masala Dosa and quick counter service!'));
    });
  });
}
