import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/canteen_schedule_model.dart';
import '../models/feedback_model.dart';
import '../models/food_model.dart';
import '../models/food_review_model.dart';
import '../models/order_item_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/wallet_transaction_model.dart';
import 'firebase_service.dart';
import 'local_storage_service.dart';

class FirestoreService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static const String _keyUsers = 'smart_canteen_users';
  static const String _keyOrders = 'smart_canteen_orders';
  static const String _keyTransactions = 'smart_canteen_wallet_txns';
  static const String _keyFeedbacks = 'smart_canteen_feedbacks';
  static const String _keyFoodReviews = 'smart_canteen_food_reviews';
  static const String _keyFoodsCatalog = 'smart_canteen_foods_catalog';
  static const String _keyCanteenSchedule = 'smart_canteen_schedule';

  static CanteenScheduleModel _mockCanteenSchedule = _initCanteenSchedule();
  static final StreamController<CanteenScheduleModel> _mockCanteenScheduleController =
      StreamController<CanteenScheduleModel>.broadcast();

  // In-memory backing cache/store for instant response with permanent Local Storage persistence
  static final Map<String, UserModel> _mockUsers = _initUsers();
  static final StreamController<UserModel?> _mockUserUpdatesController =
      StreamController<UserModel?>.broadcast();
  static final StreamController<List<UserModel>> _mockUsersStreamController =
      StreamController<List<UserModel>>.broadcast();

  static List<UserModel> _getSortedUsersList() {
    final list = _mockUsers.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static final List<WalletTransactionModel> _mockWalletTransactions = _initTransactions();
  static final StreamController<List<WalletTransactionModel>> _mockWalletTransactionsStreamController =
      StreamController<List<WalletTransactionModel>>.broadcast();

  static final List<FoodModel> _mockFoods = _initFoods();
  static final StreamController<List<FoodModel>> _mockFoodsStreamController =
      StreamController<List<FoodModel>>.broadcast();

  static final List<FoodReviewModel> _mockFoodReviews = _initFoodReviews();
  static final StreamController<List<FoodReviewModel>> _mockFoodReviewsStreamController =
      StreamController<List<FoodReviewModel>>.broadcast();

  static final List<FeedbackModel> _mockFeedbacks = _initFeedbacks();
  static final StreamController<List<FeedbackModel>> _mockFeedbackStreamController =
      StreamController<List<FeedbackModel>>.broadcast();

  static final List<OrderModel> _mockOrders = _initOrders();
  static final StreamController<List<OrderModel>> _mockOrdersStreamController =
      StreamController<List<OrderModel>>.broadcast();

  static Map<String, UserModel> _initUsers() {
    final Map<String, UserModel> users = {
      'user_demo_01': UserModel(
        userId: 'user_demo_01',
        name: 'Snehesh',
        email: 'user@canteen.com',
        phone: '9876543210',
        role: 'user',
        walletBalance: 500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      'staff_demo_01': UserModel(
        userId: 'staff_demo_01',
        name: 'Chef Biju',
        email: 'staff@canteen.com',
        phone: '9876543211',
        role: 'staff',
        walletBalance: 0.0,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      'admin_demo_01': UserModel(
        userId: 'admin_demo_01',
        name: 'Dr. Suresh Kumar (Admin)',
        email: 'admin@canteen.com',
        phone: '9876543212',
        role: 'admin',
        walletBalance: 0.0,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
      ),
    };

    try {
      final saved = LocalStorageService.getJson(_keyUsers);
      if (saved is Map) {
        saved.forEach((key, val) {
          if (val is Map) {
            final u = UserModel.fromMap(Map<String, dynamic>.from(val));
            users[u.userId] = u;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved users from LocalStorage: $e');
    }

    return users;
  }

  static void _persistUsers() {
    try {
      final Map<String, dynamic> data = {};
      _mockUsers.forEach((id, user) {
        data[id] = user.toMap();
      });
      LocalStorageService.saveJson(_keyUsers, data);
    } catch (e) {
      debugPrint('Error persisting users to LocalStorage: $e');
    }
  }

  static CanteenScheduleModel _initCanteenSchedule() {
    try {
      final saved = LocalStorageService.getJson(_keyCanteenSchedule);
      if (saved is Map) {
        final schedule = CanteenScheduleModel.fromMap(Map<String, dynamic>.from(saved));
        // Reset manual override flags to ensure ordering is governed purely by IST schedule
        if (schedule.isManualForceOpen || schedule.isManualForceClosed) {
          final reset = schedule.copyWith(isManualForceOpen: false, isManualForceClosed: false);
          LocalStorageService.saveJson(_keyCanteenSchedule, reset.toMap());
          return reset;
        }
        return schedule;
      }
    } catch (e) {
      debugPrint('Error loading saved canteen schedule: $e');
    }
    final defaultSched = CanteenScheduleModel.defaultSchedule();
    LocalStorageService.saveJson(_keyCanteenSchedule, defaultSched.toMap());
    return defaultSched;
  }

  static void _persistCanteenSchedule() {
    try {
      LocalStorageService.saveJson(_keyCanteenSchedule, _mockCanteenSchedule.toMap());
    } catch (e) {
      debugPrint('Error persisting canteen schedule: $e');
    }
  }

  static List<WalletTransactionModel> _initTransactions() {
    final List<WalletTransactionModel> list = [];
    try {
      final saved = LocalStorageService.getJson(_keyTransactions);
      if (saved is List) {
        for (final item in saved) {
          if (item is Map) {
            list.add(WalletTransactionModel.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved transactions: $e');
    }
    return list;
  }

  static void _persistTransactions() {
    try {
      final data = _mockWalletTransactions.map((t) => t.toMap()).toList();
      LocalStorageService.saveJson(_keyTransactions, data);
    } catch (e) {
      debugPrint('Error persisting transactions: $e');
    }
  }

  static List<OrderModel> _initOrders() {
    final List<OrderModel> list = [
      OrderModel(
        orderId: 'ORD-548192',
        tokenNumber: '#42',
        userId: 'user_demo_01',
        userName: 'Student User',
        studentName: 'Student User',
        userEmail: 'user@canteen.com',
        userPhone: '9876543210',
        items: [
          const OrderItemModel(
            foodId: 'bf_01',
            name: 'Masala Dosa',
            price: 90.0,
            quantity: 1,
            imageUrl:
                'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=800&q=80',
            specialInstructions: 'Crispy, extra coconut chutney',
          ),
        ],
        totalAmount: 90.0,
        paymentMethod: 'UPI (Google Pay)',
        paymentStatus: 'Paid',
        orderStatus: OrderStatusConstants.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      OrderModel(
        orderId: 'ORD-910482',
        tokenNumber: '#104',
        userId: 'student_demo_01',
        userName: 'Snehesh',
        userEmail: 'student@canteen.com',
        userPhone: '9876543210',
        items: [
          const OrderItemModel(
            foodId: 'bf_01',
            name: 'Masala Dosa',
            price: 90.0,
            quantity: 1,
            imageUrl:
                'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=800&q=80',
          ),
          const OrderItemModel(
            foodId: 'cd_01',
            name: 'Lime Juice',
            price: 25.0,
            quantity: 2,
            imageUrl:
                'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=800&q=80',
          ),
        ],
        totalAmount: 145.0,
        paymentMethod: 'UPI',
        paymentStatus: 'Paid',
        orderStatus: OrderStatusConstants.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      ),
    ];

    try {
      final saved = LocalStorageService.getJson(_keyOrders);
      if (saved is List && saved.isNotEmpty) {
        final Map<String, OrderModel> map = {};
        for (final o in list) {
          map[o.orderId] = o;
        }
        for (final item in saved) {
          if (item is Map) {
            final o = OrderModel.fromMap(Map<String, dynamic>.from(item));
            map[o.orderId] = o;
          }
        }
        list.clear();
        list.addAll(map.values);
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error loading saved orders: $e');
    }
    return list;
  }

  static void _persistOrders() {
    try {
      final data = _mockOrders.map((o) => o.toMap()).toList();
      LocalStorageService.saveJson(_keyOrders, data);
    } catch (e) {
      debugPrint('Error persisting orders: $e');
    }
  }

  static List<FeedbackModel> _initFeedbacks() {
    final List<FeedbackModel> list = [
      FeedbackModel(
        feedbackId: 'fb_01',
        orderId: 'ORD-910482',
        userId: 'student_demo_01',
        userName: 'Snehesh',
        foodId: 'bf_01',
        foodRating: 5.0,
        serviceRating: 5.0,
        type: FeedbackTypeConstants.feedback,
        comment: 'Super fast delivery and the Masala Dosa was crunchy and warm!',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      FeedbackModel(
        feedbackId: 'fb_02',
        orderId: 'ORD-910399',
        userId: 'student_02',
        userName: 'Priya Patel',
        foodId: 'cd_01',
        foodRating: 4.8,
        serviceRating: 4.5,
        type: FeedbackTypeConstants.suggestion,
        comment: 'Lime Juice is super refreshing! Perfect for hot afternoons.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    try {
      final saved = LocalStorageService.getJson(_keyFeedbacks);
      if (saved is List && saved.isNotEmpty) {
        list.clear();
        for (final item in saved) {
          if (item is Map) {
            list.add(FeedbackModel.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved feedbacks: $e');
    }
    return list;
  }

  static void _persistFeedbacks() {
    try {
      final data = _mockFeedbacks.map((f) => f.toMap()).toList();
      LocalStorageService.saveJson(_keyFeedbacks, data);
    } catch (e) {
      debugPrint('Error persisting feedbacks: $e');
    }
  }

  static List<FoodModel> _initFoods() {
    final List<FoodModel> list = AppConstants.initialFoodItems
        .map((item) => FoodModel.fromMap(item))
        .toList();

    try {
      final saved = LocalStorageService.getJson(_keyFoodsCatalog);
      if (saved is List && saved.isNotEmpty) {
        final List<FoodModel> loaded = [];
        for (final item in saved) {
          if (item is Map) {
            loaded.add(FoodModel.fromMap(Map<String, dynamic>.from(item)));
          }
        }
        if (loaded.isNotEmpty) {
          return loaded;
        }
      }
    } catch (e) {
      debugPrint('Error loading saved foods catalog: $e');
    }
    return list;
  }

  static void _persistFoods() {
    try {
      final data = _mockFoods.map((f) => f.toMap()).toList();
      LocalStorageService.saveJson(_keyFoodsCatalog, data);
    } catch (e) {
      debugPrint('Error persisting foods catalog: $e');
    }
  }

  static List<FoodReviewModel> _initFoodReviews() {
    final List<FoodReviewModel> list = [
      FoodReviewModel(
        reviewId: 'rv_01',
        foodId: 'bf_01',
        foodName: 'Masala Dosa',
        orderId: 'ORD-910482',
        userId: 'student_demo_01',
        userName: 'Snehesh',
        rating: 5.0,
        comment: 'Crispy, hot, and tasty coconut chutney! Best breakfast item.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      FoodReviewModel(
        reviewId: 'rv_02',
        foodId: 'meals_01',
        foodName: 'Chicken Biriyani',
        orderId: 'ORD-910388',
        userId: 'student_02',
        userName: 'Priya Patel',
        rating: 4.9,
        comment: 'Aromatic basmati rice and flavorful chicken pieces. Highly recommended!',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];

    try {
      final saved = LocalStorageService.getJson(_keyFoodReviews);
      if (saved is List && saved.isNotEmpty) {
        list.clear();
        for (final item in saved) {
          if (item is Map) {
            list.add(FoodReviewModel.fromMap(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved food reviews: $e');
    }
    return list;
  }

  static void _persistFoodReviews() {
    try {
      final data = _mockFoodReviews.map((r) => r.toMap()).toList();
      LocalStorageService.saveJson(_keyFoodReviews, data);
    } catch (e) {
      debugPrint('Error persisting food reviews: $e');
    }
  }

  // ================= USERS =================

  Future<void> createUser(UserModel user) async {
    _mockUsers[user.userId] = user;
    _persistUsers();
    _mockUserUpdatesController.add(user);
    _mockUsersStreamController.add(_getSortedUsersList());

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(user.userId)
            .set(user.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore createUser error: $e');
      }
    }
  }

  Future<UserModel?> getUser(String userId) async {
    if (FirebaseService.isFirebaseReady) {
      try {
        final doc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(userId)
            .get();
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint('Firestore getUser error: $e');
      }
    }

    if (_mockUsers.containsKey(userId)) {
      return _mockUsers[userId];
    }

    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (FirebaseService.isFirebaseReady) {
      try {
        final query = await _firestore
            .collection(AppConstants.collectionUsers)
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          return UserModel.fromFirestore(query.docs.first);
        }
      } catch (e) {
        debugPrint('Firestore getUserByEmail error: $e');
      }
    }

    for (final user in _mockUsers.values) {
      if (user.email.trim().toLowerCase() == cleanEmail) {
        return user;
      }
    }
    return null;
  }

  Future<bool> isEmailRegistered(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (FirebaseService.isFirebaseReady) {
      try {
        final query = await _firestore
            .collection(AppConstants.collectionUsers)
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          return true;
        }
      } catch (e) {
        debugPrint('Firestore isEmailRegistered error: $e');
      }
    }

    for (final user in _mockUsers.values) {
      if (user.email.trim().toLowerCase() == cleanEmail) {
        return true;
      }
    }
    return false;
  }

  Future<bool> isUserIdRegistered(String userId) async {
    return isStudentIdRegistered(userId);
  }

  Future<bool> isStudentIdRegistered(String studentId) async {
    final cleanStudentId = studentId.trim().toUpperCase();
    if (cleanStudentId.isEmpty) return false;

    if (FirebaseService.isFirebaseReady) {
      try {
        final query = await _firestore
            .collection(AppConstants.collectionUsers)
            .where('studentId', isEqualTo: cleanStudentId)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          return true;
        }
      } catch (e) {
        debugPrint('Firestore isStudentIdRegistered error: $e');
      }
    }

    for (final user in _mockUsers.values) {
      if (user.studentId.trim().toUpperCase() == cleanStudentId) {
        return true;
      }
    }
    return false;
  }

  Future<void> updateUser(UserModel user) async {
    _mockUsers[user.userId] = user;
    _persistUsers();
    _mockUserUpdatesController.add(user);
    _mockUsersStreamController.add(_getSortedUsersList());

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(user.userId)
            .update(user.toMap());
      } catch (e) {
        debugPrint('Firestore updateUser error: $e');
      }
    }
  }

  // ================= WALLET & TRANSACTIONS =================

  Stream<UserModel?> getUserStream(String userId) {
    if (FirebaseService.isFirebaseReady) {
      try {
        return _firestore
            .collection(AppConstants.collectionUsers)
            .doc(userId)
            .snapshots()
            .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : _mockUsers[userId]);
      } catch (e) {
        debugPrint('Firestore getUserStream error: $e');
      }
    }

    return Stream<UserModel?>.multi((controller) {
      controller.add(_mockUsers[userId]);
      final sub = _mockUserUpdatesController.stream.listen((user) {
        if (user?.userId == userId) {
          controller.add(user);
        }
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  Future<double> getWalletBalance(String userId) async {
    final user = await getUser(userId);
    return user?.walletBalance ?? 0.0;
  }

  Future<double> addWalletMoney(
    String userId,
    double amount, {
    String description = 'Wallet Top-Up (UPI)',
  }) async {
    if (amount <= 0) throw 'Amount must be greater than zero.';

    final user = await getUser(userId);
    final currentBalance = user?.walletBalance ?? 0.0;
    final newBalance = currentBalance + amount;

    if (user != null) {
      final updatedUser = user.copyWith(walletBalance: newBalance);
      await updateUser(updatedUser);
    }

    // Record Transaction
    final txn = WalletTransactionModel(
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: 'credit',
      amount: amount,
      balanceAfter: newBalance,
      description: description,
      createdAt: DateTime.now(),
    );

    _mockWalletTransactions.insert(0, txn);
    _persistTransactions();
    _mockWalletTransactionsStreamController.add(List.from(_mockWalletTransactions));

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionWalletTransactions)
            .doc(txn.transactionId)
            .set(txn.toMap());
        debugPrint('Recorded Wallet Top-Up credit txn ${txn.transactionId} for UID $userId');
      } catch (e) {
        debugPrint('Firestore addWalletMoney txn error: $e');
      }
    }

    return newBalance;
  }

  Future<double> deductWalletMoney(
    String userId,
    double amount, {
    required String orderId,
    required String description,
  }) async {
    if (amount <= 0) throw 'Deduction amount must be greater than zero.';

    final user = await getUser(userId);
    final currentBalance = user?.walletBalance ?? 0.0;

    if (currentBalance < amount) {
      final shortfall = amount - currentBalance;
      throw 'Insufficient wallet balance. Please add ₹${shortfall.toStringAsFixed(0)}.';
    }

    final newBalance = currentBalance - amount;

    if (user != null) {
      final updatedUser = user.copyWith(walletBalance: newBalance);
      await updateUser(updatedUser);
    }

    // Record Transaction
    final txn = WalletTransactionModel(
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      orderId: orderId,
      type: 'debit',
      amount: amount,
      balanceAfter: newBalance,
      description: description,
      createdAt: DateTime.now(),
    );

    _mockWalletTransactions.insert(0, txn);
    _persistTransactions();
    _mockWalletTransactionsStreamController.add(List.from(_mockWalletTransactions));

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionWalletTransactions)
            .doc(txn.transactionId)
            .set(txn.toMap());
        debugPrint('Recorded Wallet purchase debit txn ${txn.transactionId} for order $orderId');
      } catch (e) {
        debugPrint('Firestore deductWalletMoney txn error: $e');
      }
    }

    return newBalance;
  }

  Stream<List<WalletTransactionModel>> getUserWalletTransactionsStream(String userId) {
    if (FirebaseService.isFirebaseReady) {
      try {
        return _firestore
            .collection(AppConstants.collectionWalletTransactions)
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) {
              return snapshot.docs
                  .map((doc) => WalletTransactionModel.fromFirestore(doc))
                  .toList();
            });
      } catch (e) {
        debugPrint('Firestore getUserWalletTransactionsStream error: $e');
      }
    }

    return Stream<List<WalletTransactionModel>>.multi((controller) {
      List<WalletTransactionModel> filter(List<WalletTransactionModel> list) {
        return list.where((t) => t.userId == userId).toList();
      }

      controller.add(filter(_mockWalletTransactions));
      final sub = _mockWalletTransactionsStreamController.stream.listen((txns) {
        controller.add(filter(txns));
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  // ================= FOODS =================

  Stream<List<FoodModel>> getFoodItemsStream({
    String? category,
    String? searchQuery,
    bool availableOnly = false,
  }) {
    return Stream<List<FoodModel>>.multi((controller) {
      List<FoodModel> latestFirestore = [];

      void emitCurrent() {
        List<FoodModel> currentList = [];
        if (latestFirestore.isNotEmpty) {
          final Map<String, FoodModel> map = {};
          for (final f in latestFirestore) {
            map[f.foodId] = f;
          }
          for (final f in _mockFoods) {
            if (!map.containsKey(f.foodId)) {
              map[f.foodId] = f;
            }
          }
          currentList = map.values.toList();
        } else {
          currentList = List.from(_mockFoods);
        }

        List<FoodModel> filtered = currentList.where((food) {
          if (availableOnly && !food.available) return false;
          if (category != null && category != 'All' && category.isNotEmpty && food.category != category) {
            return false;
          }
          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final queryLower = searchQuery.toLowerCase();
            final match = food.name.toLowerCase().contains(queryLower) ||
                food.description.toLowerCase().contains(queryLower) ||
                food.category.toLowerCase().contains(queryLower);
            if (!match) return false;
          }
          return true;
        }).toList();

        if (!controller.isClosed) {
          controller.add(filtered);
        }
      }

      // 1. Instant zero-lag emission
      emitCurrent();

      // 2. Listen to local stream controller
      final localSub = _mockFoodsStreamController.stream.listen((_) {
        emitCurrent();
      });

      // 3. Listen to live Firestore
      StreamSubscription? firestoreSub;
      if (FirebaseService.isFirebaseReady) {
        try {
          Query query = _firestore.collection(AppConstants.collectionFoods);
          firestoreSub = query.snapshots().listen((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              latestFirestore = snapshot.docs
                  .map((doc) => FoodModel.fromFirestore(doc))
                  .toList();
              // Sync to mockFoods in-memory
              for (final f in latestFirestore) {
                final idx = _mockFoods.indexWhere((m) => m.foodId == f.foodId);
                if (idx != -1) {
                  _mockFoods[idx] = f;
                } else {
                  _mockFoods.add(f);
                }
              }
              _persistFoods();
            } else if (_mockFoods.isNotEmpty) {
              seedInitialFoods();
            }
            emitCurrent();
          }, onError: (e) {
            debugPrint('Firestore getFoodItemsStream error: $e');
          });
        } catch (e) {
          debugPrint('Firestore getFoodItemsStream setup error: $e');
        }
      }

      controller.onCancel = () {
        localSub.cancel();
        firestoreSub?.cancel();
      };
    });
  }

  Stream<List<FoodModel>> getPopularFoodItemsStream() {
    if (FirebaseService.isFirebaseReady) {
      try {
        return _firestore
            .collection(AppConstants.collectionFoods)
            .where('rating', isGreaterThanOrEqualTo: 4.7)
            .limit(5)
            .snapshots()
            .map((snapshot) {
              if (snapshot.docs.isEmpty) {
                return _mockFoods.where((f) => f.rating >= 4.7).take(5).toList();
              }
              return snapshot.docs
                  .map((doc) => FoodModel.fromFirestore(doc))
                  .toList();
            });
      } catch (e) {
        debugPrint('Firestore popular stream error: $e');
      }
    }

    return Stream<List<FoodModel>>.multi((controller) {
      controller.add(_mockFoods.where((f) => f.rating >= 4.7).take(5).toList());
      final sub = _mockFoodsStreamController.stream.listen((_) {
        controller.add(_mockFoods.where((f) => f.rating >= 4.7).take(5).toList());
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  Future<FoodModel?> getFoodById(String foodId) async {
    if (FirebaseService.isFirebaseReady) {
      try {
        final doc = await _firestore
            .collection(AppConstants.collectionFoods)
            .doc(foodId)
            .get();
        if (doc.exists) {
          return FoodModel.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint('Firestore getFoodById error: $e');
      }
    }

    try {
      return _mockFoods.firstWhere((f) => f.foodId == foodId);
    } catch (_) {
      return null;
    }
  }

  Future<void> seedInitialFoods() async {
    if (!FirebaseService.isFirebaseReady) return;

    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionFoods)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('Seeding initial canteen food catalog to Firestore...');
        final batch = _firestore.batch();
        for (final item in AppConstants.initialFoodItems) {
          final food = FoodModel.fromMap(item);
          final docRef = _firestore
              .collection(AppConstants.collectionFoods)
              .doc(food.foodId);
          batch.set(docRef, food.toMap());
        }
        await batch.commit();
        debugPrint('Initial food items seeded successfully.');
      }
    } catch (e) {
      debugPrint('Error seeding foods: $e');
    }
  }


  // ================= FOOD REVIEWS & DYNAMIC RATING =================

  Future<void> submitFoodReview(FoodReviewModel review) async {
    _mockFoodReviews.insert(0, review);
    _persistFoodReviews();
    _mockFoodReviewsStreamController.add(List.from(_mockFoodReviews));

    // Dynamically recalculate Food item rating
    final index = _mockFoods.indexWhere((f) =>
        f.foodId == review.foodId ||
        f.name.toLowerCase().trim() == review.foodName.toLowerCase().trim());
    double newRating = review.rating;
    int newRatingCount = 1;

    if (index != -1) {
      final currentFood = _mockFoods[index];
      final currentCount = currentFood.ratingCount;
      final currentRating = currentFood.rating;

      if (currentCount > 0) {
        newRatingCount = currentCount + 1;
        final double totalScore = (currentRating * currentCount) + review.rating;
        final double computed = totalScore / newRatingCount;
        newRating = double.parse(computed.toStringAsFixed(1));
      } else {
        newRatingCount = 1;
        newRating = review.rating;
      }

      _mockFoods[index] = currentFood.copyWith(
        rating: newRating,
        ratingCount: newRatingCount,
      );
      _persistFoods();
      _mockFoodsStreamController.add(List.from(_mockFoods));
    }

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionFoodReviews)
            .doc(review.reviewId)
            .set(review.toMap());

        final targetFoodId = index != -1 ? _mockFoods[index].foodId : review.foodId;
        await _firestore
            .collection(AppConstants.collectionFoods)
            .doc(targetFoodId)
            .update({
          'rating': newRating,
          'ratingCount': newRatingCount,
        });
        debugPrint(
            'Saved review ${review.reviewId} and recalculated food rating to $newRating ($newRatingCount reviews)');
      } catch (e) {
        debugPrint('Firestore submitFoodReview error: $e');
      }
    }
  }

  Stream<List<FoodReviewModel>> getFoodReviewsStream(String foodId) {
    if (FirebaseService.isFirebaseReady) {
      try {
        return _firestore
            .collection(AppConstants.collectionFoodReviews)
            .where('foodId', isEqualTo: foodId)
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) {
              if (snapshot.docs.isEmpty) {
                return _mockFoodReviews.where((r) => r.foodId == foodId).toList();
              }
              return snapshot.docs
                  .map((doc) => FoodReviewModel.fromFirestore(doc))
                  .toList();
            });
      } catch (e) {
        debugPrint('Firestore getFoodReviewsStream error: $e');
      }
    }

    return Stream<List<FoodReviewModel>>.multi((controller) {
      List<FoodReviewModel> filter(List<FoodReviewModel> list) {
        return list.where((r) => r.foodId == foodId).toList();
      }

      controller.add(filter(_mockFoodReviews));
      final sub = _mockFoodReviewsStreamController.stream.listen((reviews) {
        controller.add(filter(reviews));
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  // ================= ORDERS =================

  Future<void> createOrder(OrderModel order) async {
    _mockOrders.removeWhere((o) => o.orderId == order.orderId);
    _mockOrders.insert(0, order);
    _persistOrders();
    _mockOrdersStreamController.add(List.from(_mockOrders));

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionOrders)
            .doc(order.orderId)
            .set(order.toMap(), SetOptions(merge: true));
        debugPrint('Order ${order.orderId} successfully persisted in Firestore for UID ${order.userId}');
      } catch (e) {
        debugPrint('Firestore createOrder error: $e');
      }
    }
  }

  Stream<List<OrderModel>> getUserOrdersStream(String userId) {
    return Stream<List<OrderModel>>.multi((controller) {
      List<OrderModel> latestFirestore = [];

      void emitCurrent() {
        final Map<String, OrderModel> mergedMap = {};
        for (final o in latestFirestore) {
          if (userId.isEmpty || o.userId == userId) {
            mergedMap[o.orderId] = o;
          }
        }
        for (final o in _mockOrders) {
          if (userId.isEmpty || o.userId == userId) {
            if (!mergedMap.containsKey(o.orderId) || o.updatedAt.isAfter(mergedMap[o.orderId]!.updatedAt)) {
              mergedMap[o.orderId] = o;
            }
          }
        }

        List<OrderModel> result = mergedMap.values.toList();
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (!controller.isClosed) {
          controller.add(result);
        }
      }

      emitCurrent();

      final localSub = _mockOrdersStreamController.stream.listen((_) {
        emitCurrent();
      });

      StreamSubscription? firestoreSub;
      if (FirebaseService.isFirebaseReady) {
        try {
          Query query = _firestore.collection(AppConstants.collectionOrders);
          if (userId.isNotEmpty) {
            query = query.where('userId', isEqualTo: userId);
          }
          firestoreSub = query.snapshots().listen((snapshot) {
            latestFirestore = [];
            for (final doc in snapshot.docs) {
              try {
                final o = OrderModel.fromFirestore(doc);
                latestFirestore.add(o);
                // Keep mock orders updated in memory
                final idx = _mockOrders.indexWhere((m) => m.orderId == o.orderId);
                if (idx != -1) {
                  if (o.updatedAt.isAfter(_mockOrders[idx].updatedAt)) {
                    _mockOrders[idx] = o;
                  }
                } else {
                  _mockOrders.insert(0, o);
                }
              } catch (e) {
                debugPrint('Error parsing doc ${doc.id} in getUserOrdersStream: $e');
              }
            }
            _persistOrders();
            emitCurrent();
          }, onError: (e) {
            debugPrint('Firestore getUserOrdersStream error: $e');
          });
        } catch (e) {
          debugPrint('Firestore getUserOrdersStream setup error: $e');
        }
      }

      controller.onCancel = () {
        localSub.cancel();
        firestoreSub?.cancel();
      };
    });
  }

  Stream<OrderModel?> getOrderStream(String orderId) {
    return Stream<OrderModel?>.multi((controller) {
      OrderModel? latestFirestoreOrder;

      void emitCurrent() {
        OrderModel? current;
        OrderModel? mockOrder;
        try {
          mockOrder = _mockOrders.firstWhere((o) => o.orderId == orderId);
        } catch (_) {
          mockOrder = null;
        }

        if (latestFirestoreOrder != null && mockOrder != null) {
          current = latestFirestoreOrder!.updatedAt.isAfter(mockOrder.updatedAt)
              ? latestFirestoreOrder
              : mockOrder;
        } else {
          current = latestFirestoreOrder ?? mockOrder;
        }

        if (!controller.isClosed) {
          controller.add(current);
        }
      }

      emitCurrent();

      final localSub = _mockOrdersStreamController.stream.listen((_) {
        emitCurrent();
      });

      StreamSubscription? firestoreSub;
      if (FirebaseService.isFirebaseReady) {
        try {
          firestoreSub = _firestore
              .collection(AppConstants.collectionOrders)
              .doc(orderId)
              .snapshots()
              .listen((doc) {
            if (doc.exists && doc.data() != null) {
              try {
                latestFirestoreOrder = OrderModel.fromFirestore(doc);
                final idx = _mockOrders.indexWhere((m) => m.orderId == orderId);
                if (idx != -1) {
                  if (latestFirestoreOrder!.updatedAt.isAfter(_mockOrders[idx].updatedAt)) {
                    _mockOrders[idx] = latestFirestoreOrder!;
                    _persistOrders();
                  }
                } else {
                  _mockOrders.insert(0, latestFirestoreOrder!);
                  _persistOrders();
                }
              } catch (e) {
                debugPrint('Error parsing order $orderId: $e');
              }
            }
            emitCurrent();
          }, onError: (e) {
            debugPrint('Firestore getOrderStream error: $e');
          });
        } catch (e) {
          debugPrint('Firestore getOrderStream setup error: $e');
        }
      }

      controller.onCancel = () {
        localSub.cancel();
        firestoreSub?.cancel();
      };
    });
  }

  Stream<List<OrderModel>> getAllOrdersStream({String? statusFilter}) {
    return Stream<List<OrderModel>>.multi((controller) {
      List<OrderModel> latestFirestore = [];

      void emitCurrent() {
        final Map<String, OrderModel> mergedMap = {};
        for (final o in latestFirestore) {
          mergedMap[o.orderId] = o;
        }
        for (final o in _mockOrders) {
          if (!mergedMap.containsKey(o.orderId) || o.updatedAt.isAfter(mergedMap[o.orderId]!.updatedAt)) {
            mergedMap[o.orderId] = o;
          }
        }

        List<OrderModel> result = mergedMap.values.toList();
        if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'All') {
          final normalizedFilter = OrderStatusConstants.normalize(statusFilter);
          result = result.where((o) => o.normalizedStatus == normalizedFilter).toList();
        }
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (!controller.isClosed) {
          controller.add(result);
        }
      }

      emitCurrent();

      final localSub = _mockOrdersStreamController.stream.listen((_) {
        emitCurrent();
      });

      StreamSubscription? firestoreSub;
      if (FirebaseService.isFirebaseReady) {
        try {
          firestoreSub = _firestore
              .collection(AppConstants.collectionOrders)
              .snapshots()
              .listen((snapshot) {
            latestFirestore = [];
            for (final doc in snapshot.docs) {
              try {
                final o = OrderModel.fromFirestore(doc);
                latestFirestore.add(o);
                final idx = _mockOrders.indexWhere((m) => m.orderId == o.orderId);
                if (idx != -1) {
                  if (o.updatedAt.isAfter(_mockOrders[idx].updatedAt)) {
                    _mockOrders[idx] = o;
                  }
                } else {
                  _mockOrders.insert(0, o);
                }
              } catch (e) {
                debugPrint('Error parsing doc ${doc.id} in getAllOrdersStream: $e');
              }
            }
            _persistOrders();
            emitCurrent();
          }, onError: (e) {
            debugPrint('Firestore getAllOrdersStream error: $e');
          });
        } catch (e) {
          debugPrint('Firestore getAllOrdersStream setup error: $e');
        }
      }

      controller.onCancel = () {
        localSub.cancel();
        firestoreSub?.cancel();
      };
    });
  }

  Stream<List<OrderModel>> getKitchenQueueStream() {
    return Stream<List<OrderModel>>.multi((controller) {
      List<OrderModel> latestFirestore = [];

      void emitCurrent() {
        final Map<String, OrderModel> mergedMap = {};
        for (final o in latestFirestore) {
          if (o.isActive) mergedMap[o.orderId] = o;
        }
        for (final o in _mockOrders) {
          if (o.isActive) mergedMap[o.orderId] = o;
        }

        List<OrderModel> result = mergedMap.values.toList();
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        if (!controller.isClosed) {
          controller.add(result);
        }
      }

      emitCurrent();

      final localSub = _mockOrdersStreamController.stream.listen((_) {
        emitCurrent();
      });

      StreamSubscription? firestoreSub;
      if (FirebaseService.isFirebaseReady) {
        try {
          firestoreSub = _firestore
              .collection(AppConstants.collectionOrders)
              .snapshots()
              .listen((snapshot) {
            latestFirestore = [];
            for (final doc in snapshot.docs) {
              try {
                final o = OrderModel.fromFirestore(doc);
                if (o.isActive) latestFirestore.add(o);
                final idx = _mockOrders.indexWhere((m) => m.orderId == o.orderId);
                if (idx != -1) {
                  if (o.updatedAt.isAfter(_mockOrders[idx].updatedAt)) {
                    _mockOrders[idx] = o;
                  }
                } else {
                  _mockOrders.insert(0, o);
                }
              } catch (e) {
                debugPrint('Error parsing doc in getKitchenQueueStream: $e');
              }
            }
            _persistOrders();
            emitCurrent();
          }, onError: (e) {
            debugPrint('Firestore getKitchenQueueStream error: $e');
          });
        } catch (e) {
          debugPrint('Firestore getKitchenQueueStream setup error: $e');
        }
      }

      controller.onCancel = () {
        localSub.cancel();
        firestoreSub?.cancel();
      };
    });
  }

  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? cancellationReason,
    String? cancelledBy,
  }) async {
    final canonicalStatus = OrderStatusConstants.normalize(newStatus);
    if (canonicalStatus == OrderStatusConstants.cancelled) {
      await cancelOrder(
        orderId,
        reason: cancellationReason ?? 'Out of stock ingredients',
        cancelledBy: cancelledBy ?? 'Kitchen',
      );
      return;
    }

    final index = _mockOrders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      final updated = _mockOrders[index].copyWith(
        orderStatus: canonicalStatus,
        updatedAt: DateTime.now(),
      );
      _mockOrders[index] = updated;
      _persistOrders();
      _mockOrdersStreamController.add(List.from(_mockOrders));
    }

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionOrders)
            .doc(orderId)
            .update({
          'orderStatus': canonicalStatus,
          'updatedAt': Timestamp.now(),
        });
        debugPrint('Updated Firestore order $orderId to canonical status "$canonicalStatus"');
      } catch (e) {
        debugPrint('Firestore updateOrderStatus error: $e');
      }
    }
  }

  Future<void> cancelOrder(
    String orderId, {
    required String reason,
    String cancelledBy = 'Kitchen',
    bool autoRefund = true,
  }) async {
    final index = _mockOrders.indexWhere((o) => o.orderId == orderId);
    OrderModel? order;
    if (index != -1) {
      order = _mockOrders[index];
    } else if (FirebaseService.isFirebaseReady) {
      try {
        final doc = await _firestore.collection(AppConstants.collectionOrders).doc(orderId).get();
        if (doc.exists) {
          order = OrderModel.fromFirestore(doc);
        }
      } catch (e) {
        debugPrint('Firestore fetch before cancel error: $e');
      }
    }

    if (order == null) return;

    bool isRefunded = order.isRefunded;
    double refundAmount = order.refundAmount;

    // Auto refund wallet if order was paid or payment is Wallet
    if (autoRefund && !isRefunded && (order.paymentMethod.toLowerCase().contains('wallet') || order.paymentStatus == 'Paid')) {
      try {
        await addWalletMoney(
          order.userId,
          order.totalAmount,
          description: 'Refund for Cancelled Order #${order.tokenNumber} ($reason)',
        );
        isRefunded = true;
        refundAmount = order.totalAmount;
      } catch (e) {
        debugPrint('Auto refund error for order $orderId: $e');
      }
    }

    final updated = order.copyWith(
      orderStatus: OrderStatusConstants.cancelled,
      cancellationReason: reason,
      cancelledBy: cancelledBy,
      isRefunded: isRefunded,
      refundAmount: refundAmount,
      updatedAt: DateTime.now(),
    );

    if (index != -1) {
      _mockOrders[index] = updated;
    } else {
      _mockOrders.insert(0, updated);
    }
    _persistOrders();
    _mockOrdersStreamController.add(List.from(_mockOrders));

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore.collection(AppConstants.collectionOrders).doc(orderId).update({
          'orderStatus': OrderStatusConstants.cancelled,
          'cancellationReason': reason,
          'cancelledBy': cancelledBy,
          'isRefunded': isRefunded,
          'refundAmount': refundAmount,
          'updatedAt': Timestamp.now(),
        });
        debugPrint('Cancelled Firestore order $orderId with reason: "$reason"');
      } catch (e) {
        debugPrint('Firestore cancelOrder error: $e');
      }
    }
  }

  Future<void> updateOrderPaymentStatus(
    String orderId,
    String paymentStatus, {
    String? orderStatus,
  }) async {
    final index = _mockOrders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      final updated = _mockOrders[index].copyWith(
        paymentStatus: paymentStatus,
        orderStatus: orderStatus ?? _mockOrders[index].orderStatus,
        updatedAt: DateTime.now(),
      );
      _mockOrders[index] = updated;
      _persistOrders();
      _mockOrdersStreamController.add(List.from(_mockOrders));
    }

    if (FirebaseService.isFirebaseReady) {
      try {
        final data = <String, dynamic>{
          'paymentStatus': paymentStatus,
          'updatedAt': Timestamp.now(),
        };
        if (orderStatus != null) {
          data['orderStatus'] = orderStatus;
        }
        await _firestore
            .collection(AppConstants.collectionOrders)
            .doc(orderId)
            .update(data);
      } catch (e) {
        debugPrint('Firestore updateOrderPaymentStatus error: $e');
      }
    }
  }

  Future<void> toggleFoodAvailability(String foodId, bool available) async {
    final index = _mockFoods.indexWhere((f) => f.foodId == foodId);
    if (index != -1) {
      _mockFoods[index] = _mockFoods[index].copyWith(available: available);
      _persistFoods();
      _mockFoodsStreamController.add(List.from(_mockFoods));
    }

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionFoods)
            .doc(foodId)
            .update({'available': available});
      } catch (e) {
        debugPrint('Firestore toggleFoodAvailability error: $e');
      }
    }
  }

  Future<void> addFood(FoodModel food) async {
    _mockFoods.insert(0, food);
    _persistFoods();
    _mockFoodsStreamController.add(List.from(_mockFoods));

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionFoods)
            .doc(food.foodId)
            .set(food.toMap());
      } catch (e) {
        debugPrint('Firestore addFood error: $e');
        throw 'Failed to add food: $e';
      }
    }
  }

  Future<void> updateFood(FoodModel food) async {
    final index = _mockFoods.indexWhere((f) => f.foodId == food.foodId);
    if (index != -1) {
      _mockFoods[index] = food;
      _persistFoods();
      _mockFoodsStreamController.add(List.from(_mockFoods));
    }

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionFoods)
            .doc(food.foodId)
            .update(food.toMap());
      } catch (e) {
        debugPrint('Firestore updateFood error: $e');
        throw 'Failed to update food: $e';
      }
    }
  }

  Future<void> deleteFood(String foodId) async {
    _mockFoods.removeWhere((f) => f.foodId == foodId);
    _persistFoods();
    _mockFoodsStreamController.add(List.from(_mockFoods));

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionFoods)
            .doc(foodId)
            .delete();
      } catch (e) {
        debugPrint('Firestore deleteFood error: $e');
        throw 'Failed to delete food: $e';
      }
    }
  }

  // ================= USERS (ADMIN) =================

  Stream<List<UserModel>> getAllUsersStream() {
    return Stream<List<UserModel>>.multi((controller) {
      List<UserModel> latestFirestoreUsers = [];

      void emitCombinedUsers() {
        final Map<String, UserModel> map = {};
        for (final u in _mockUsers.values) {
          map[u.userId] = u;
        }
        for (final u in latestFirestoreUsers) {
          map[u.userId] = u;
        }
        final list = map.values.toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (!controller.isClosed) {
          controller.add(list);
        }
      }

      // 1. Instant zero-latency emission
      emitCombinedUsers();

      // 2. Listen to local reactive updates (registrations, profile changes, role changes)
      final localSub = _mockUsersStreamController.stream.listen((_) {
        emitCombinedUsers();
      });

      // 3. Listen to Cloud Firestore updates
      StreamSubscription? firestoreSub;
      if (FirebaseService.isFirebaseReady) {
        try {
          firestoreSub = _firestore
              .collection(AppConstants.collectionUsers)
              .snapshots()
              .listen((snapshot) {
            latestFirestoreUsers = snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList();
            for (final u in latestFirestoreUsers) {
              _mockUsers[u.userId] = u;
            }
            _persistUsers();
            emitCombinedUsers();
          }, onError: (e) {
            debugPrint('Firestore getAllUsersStream error: $e');
          });
        } catch (e) {
          debugPrint('Firestore getAllUsersStream setup error: $e');
        }
      }

      controller.onCancel = () {
        localSub.cancel();
        firestoreSub?.cancel();
      };
    });
  }

  Future<void> updateUserRole(String userId, String role) async {
    if (_mockUsers.containsKey(userId)) {
      final existing = _mockUsers[userId]!;
      _mockUsers[userId] = UserModel(
        userId: existing.userId,
        studentId: existing.studentId,
        name: existing.name,
        email: existing.email,
        phone: existing.phone,
        role: role,
        walletBalance: existing.walletBalance,
        profilePhoto: existing.profilePhoto,
        createdAt: existing.createdAt,
      );
      _persistUsers();
      _mockUserUpdatesController.add(_mockUsers[userId]);
      _mockUsersStreamController.add(_getSortedUsersList());
    }

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(userId)
            .update({'role': role});
      } catch (e) {
        debugPrint('Firestore updateUserRole error: $e');
      }
    }
  }

  // ================= FEEDBACK (DAY 4) =================

  Future<void> submitFeedback(FeedbackModel feedback) async {
    _mockFeedbacks.insert(0, feedback);
    _persistFeedbacks();
    _mockFeedbackStreamController.add(List.from(_mockFeedbacks));

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection(AppConstants.collectionFeedback)
            .doc(feedback.feedbackId)
            .set(feedback.toMap());
      } catch (e) {
        debugPrint('Firestore submitFeedback error: $e');
        throw 'Failed to submit feedback: $e';
      }
    }
  }

  Stream<List<FeedbackModel>> getFeedbackStream({String? typeFilter}) {
    if (FirebaseService.isFirebaseReady) {
      try {
        Query query = _firestore
            .collection(AppConstants.collectionFeedback)
            .orderBy('createdAt', descending: true);

        if (typeFilter != null && typeFilter.isNotEmpty && typeFilter != 'All') {
          query = query.where('type', isEqualTo: typeFilter);
        }

        return query.snapshots().map((snapshot) {
          return snapshot.docs
              .map((doc) => FeedbackModel.fromFirestore(doc))
              .toList();
        });
      } catch (e) {
        debugPrint('Firestore getFeedbackStream error: $e');
      }
    }

    return Stream<List<FeedbackModel>>.multi((controller) {
      List<FeedbackModel> filter(List<FeedbackModel> list) {
        if (typeFilter != null && typeFilter.isNotEmpty && typeFilter != 'All') {
          return list.where((f) => f.type == typeFilter).toList();
        }
        return list;
      }

      controller.add(filter(_mockFeedbacks));
      final sub = _mockFeedbackStreamController.stream.listen((feedbacks) {
        controller.add(filter(feedbacks));
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  // ================= CANTEEN SCHEDULE =================

  Stream<CanteenScheduleModel> getCanteenScheduleStream() {
    if (FirebaseService.isFirebaseReady) {
      try {
        return _firestore
            .collection('settings')
            .doc('canteen_schedule')
            .snapshots()
            .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final schedule = CanteenScheduleModel.fromMap(snapshot.data()!);
            _mockCanteenSchedule = schedule;
            _persistCanteenSchedule();
            return schedule;
          } else {
            // Initialize default on Firestore if not exists
            _firestore
                .collection('settings')
                .doc('canteen_schedule')
                .set(_mockCanteenSchedule.toMap(), SetOptions(merge: true));
            return _mockCanteenSchedule;
          }
        });
      } catch (e) {
        debugPrint('Firestore getCanteenScheduleStream error: $e');
      }
    }

    return Stream<CanteenScheduleModel>.multi((controller) {
      controller.add(_mockCanteenSchedule);
      final sub = _mockCanteenScheduleController.stream.listen((schedule) {
        controller.add(schedule);
      });
      controller.onCancel = () => sub.cancel();
    });
  }

  Future<CanteenScheduleModel> getCanteenSchedule() async {
    if (FirebaseService.isFirebaseReady) {
      try {
        final doc = await _firestore.collection('settings').doc('canteen_schedule').get();
        if (doc.exists && doc.data() != null) {
          final schedule = CanteenScheduleModel.fromMap(doc.data()!);
          _mockCanteenSchedule = schedule;
          _persistCanteenSchedule();
          return schedule;
        }
      } catch (e) {
        debugPrint('Firestore getCanteenSchedule error: $e');
      }
    }
    return _mockCanteenSchedule;
  }

  Future<bool> updateCanteenSchedule(CanteenScheduleModel schedule) async {
    _mockCanteenSchedule = schedule;
    _persistCanteenSchedule();
    _mockCanteenScheduleController.add(schedule);

    if (FirebaseService.isFirebaseReady) {
      try {
        await _firestore
            .collection('settings')
            .doc('canteen_schedule')
            .set(schedule.toMap(), SetOptions(merge: true));
        return true;
      } catch (e) {
        debugPrint('Firestore updateCanteenSchedule error: $e');
      }
    }
    return true;
  }
}
