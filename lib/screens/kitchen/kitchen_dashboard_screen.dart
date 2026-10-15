import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/food_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/cached_food_image.dart';
import '../auth/login_screen.dart';
import 'kitchen_order_detail_screen.dart';

class KitchenDashboardScreen extends StatefulWidget {
  const KitchenDashboardScreen({super.key});

  @override
  State<KitchenDashboardScreen> createState() => _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState extends State<KitchenDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedFilter = 'Pending';
  late TabController _tabController;

  // Kitchen Main View Mode (0: Live Orders, 1: Food Stock Control)
  int _currentKitchenTab = 0;
  String _stockSelectedCategory = 'All';
  String _stockSearchQuery = '';

  static const List<String> _tabLabels = [
    'All',
    'Pending',
    'Accepted',
    'Preparing',
    'Ready',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabLabels.length,
      initialIndex: _tabLabels.indexOf(_selectedFilter),
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = _tabLabels[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAcceptOrder(OrderModel order) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.advanceOrderStatus(order.orderId, OrderStatusConstants.accepted);
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          '✓ Accepted order Token #${order.tokenNumber} for ${order.studentName}!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to accept order: $e');
      }
    }
  }

  Future<void> _handleStartProcessing(OrderModel order) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.advanceOrderStatus(order.orderId, OrderStatusConstants.processing);
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          '🍳 Kitchen started preparing order #${order.tokenNumber} for ${order.studentName}!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to update order: $e');
      }
    }
  }

  Future<void> _handleMarkReady(OrderModel order) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.advanceOrderStatus(order.orderId, OrderStatusConstants.ready);
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          '🔔 Order Token #${order.tokenNumber} is READY for pickup! ${order.studentName} notified.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to mark ready: $e');
      }
    }
  }

  Future<void> _handleCompleteOrder(OrderModel order) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.advanceOrderStatus(order.orderId, OrderStatusConstants.completed);
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          '🎉 Order Token #${order.tokenNumber} completed & handed over to ${order.studentName}!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to complete order: $e');
      }
    }
  }

  Future<void> _handleCancelOrder(OrderModel order, String reason) async {
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.cancelOrder(
        order.orderId,
        reason: reason,
        cancelledBy: 'Kitchen',
      );
      if (mounted) {
        SnackbarUtils.showWarning(
          context,
          '⚠️ Order #${order.tokenNumber} cancelled ("$reason"). ₹${order.totalAmount.toStringAsFixed(0)} refunded to ${order.studentName}.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to cancel order: $e');
      }
    }
  }

  void _showCancelDialog(OrderModel order) {
    String selectedReason = 'Out of stock ingredients';
    final customReasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cancel Token #${order.tokenNumber}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Student: ${order.studentName} • ${CurrencyFormatter.format(order.totalAmount)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Cancellation Reason:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...[
                    'Out of stock ingredients',
                    'Specific ingredient finished during cooking',
                    'Kitchen overloaded / counter closed',
                    'Other custom reason',
                  ].map((reason) {
                    final isSelected = selectedReason == reason;
                    return InkWell(
                      onTap: () => setModalState(() => selectedReason = reason),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red.shade50 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.red.shade300 : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: isSelected ? Colors.red : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.red.shade900 : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (selectedReason == 'Other custom reason') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        hintText: 'Enter reason to explain to student...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '₹${order.totalAmount.toStringAsFixed(0)} will be immediately refunded to ${order.studentName}\'s wallet and a cancellation alert message will be sent to their app.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final finalReason = selectedReason == 'Other custom reason'
                                ? (customReasonController.text.trim().isNotEmpty
                                    ? customReasonController.text.trim()
                                    : 'Out of stock ingredients')
                                : selectedReason;

                            Navigator.pop(ctx);
                            _handleCancelOrder(order, finalReason);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Cancel & Refund Student',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleFoodStock(FoodModel food, bool newStatus) async {
    try {
      await _firestoreService.toggleFoodAvailability(food.foodId, newStatus);
      if (mounted) {
        if (newStatus) {
          SnackbarUtils.showSuccess(
            context,
            '✓ "${food.name}" is now IN STOCK.',
          );
        } else {
          SnackbarUtils.showWarning(
            context,
            '⚠️ "${food.name}" marked as OUT OF STOCK.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to update stock: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate clean background
      appBar: _buildKitchenAppBar(user?.name ?? 'Chef Biju'),
      body: StreamBuilder<List<OrderModel>>(
        stream: _firestoreService.getAllOrdersStream(),
        builder: (context, snapshot) {
          final allOrders = snapshot.data ?? [];

          final pendingOrders = allOrders.where((o) => o.isPending).toList();
          final acceptedOrders = allOrders.where((o) => o.isAccepted).toList();
          final processingOrders = allOrders.where((o) => o.isProcessing).toList();
          final readyOrders = allOrders.where((o) => o.isReady).toList();
          final completedOrders = allOrders.where((o) => o.isCompleted).toList();

          final activeOrdersCount = pendingOrders.length + acceptedOrders.length + processingOrders.length + readyOrders.length;

          return Column(
            children: [
              // Top Primary Mode Switcher (Orders Queue vs Food Stock Control)
              _buildTopModeSwitcher(activeOrdersCount),

              // Content based on selected mode
              Expanded(
                child: _currentKitchenTab == 0
                    ? _buildOrdersQueueView(
                        allOrders: allOrders,
                        pendingOrders: pendingOrders,
                        acceptedOrders: acceptedOrders,
                        processingOrders: processingOrders,
                        readyOrders: readyOrders,
                        completedOrders: completedOrders,
                      )
                    : _buildStockControlView(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopModeSwitcher(int activeOrdersCount) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            // Mode 1: Live Orders Queue
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _currentKitchenTab = 0),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _currentKitchenTab == 0 ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _currentKitchenTab == 0
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: _currentKitchenTab == 0 ? Colors.white : const Color(0xFF94A3B8),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Orders Queue',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _currentKitchenTab == 0 ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (activeOrdersCount > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _currentKitchenTab == 0 ? Colors.white : AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$activeOrdersCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _currentKitchenTab == 0 ? AppColors.accent : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Mode 2: Food Stock Control
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _currentKitchenTab = 1),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _currentKitchenTab == 1 ? const Color(0xFF059669) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _currentKitchenTab == 1
                        ? [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        color: _currentKitchenTab == 1 ? Colors.white : const Color(0xFF94A3B8),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Stock Control',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _currentKitchenTab == 1 ? Colors.white : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersQueueView({
    required List<OrderModel> allOrders,
    required List<OrderModel> pendingOrders,
    required List<OrderModel> acceptedOrders,
    required List<OrderModel> processingOrders,
    required List<OrderModel> readyOrders,
    required List<OrderModel> completedOrders,
  }) {
    List<OrderModel> displayedOrders;
    switch (_selectedFilter) {
      case 'All':
        displayedOrders = allOrders;
        break;
      case 'Accepted':
        displayedOrders = acceptedOrders;
        break;
      case 'Preparing':
        displayedOrders = processingOrders;
        break;
      case 'Ready':
        displayedOrders = readyOrders;
        break;
      case 'Completed':
        displayedOrders = completedOrders;
        break;
      case 'Pending':
      default:
        displayedOrders = pendingOrders;
        break;
    }

    return Column(
      children: [
        // Top Stats Counter Bar with live counters
        _buildStatsBar(
          pendingCount: pendingOrders.length,
          acceptedCount: acceptedOrders.length,
          processingCount: processingOrders.length,
          readyCount: readyOrders.length,
          completedCount: completedOrders.length,
        ),

        // Filter Tabs (All, Pending, Accepted, Preparing, Ready, Completed)
        _buildFilterTabs(
          allCount: allOrders.length,
          pendingCount: pendingOrders.length,
          acceptedCount: acceptedOrders.length,
          processingCount: processingOrders.length,
          readyCount: readyOrders.length,
          completedCount: completedOrders.length,
        ),

        // Orders List View
        Expanded(
          child: displayedOrders.isEmpty
              ? _buildEmptyState(_selectedFilter)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: displayedOrders.length,
                  itemBuilder: (context, index) {
                    return _buildKitchenOrderCard(displayedOrders[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStockControlView() {
    return Column(
      children: [
        // Live Stock Metrics Bar
        StreamBuilder<List<FoodModel>>(
          stream: _firestoreService.getFoodItemsStream(),
          builder: (context, snapshot) {
            final allFoods = snapshot.data ?? [];
            final totalCount = allFoods.length;
            final inStockCount = allFoods.where((f) => f.available).length;
            final soldOutCount = totalCount - inStockCount;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  _buildStockStatusPill('Total Menu', totalCount, const Color(0xFF1E293B), const Color(0xFFF1F5F9)),
                  const SizedBox(width: 8),
                  _buildStockStatusPill('In Stock', inStockCount, const Color(0xFF059669), const Color(0xFFECFDF5)),
                  const SizedBox(width: 8),
                  _buildStockStatusPill('Sold Out', soldOutCount, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
                ],
              ),
            );
          },
        ),

        // Search & Category Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _stockSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search food dishes to toggle stock...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AppConstants.categories.map((cat) {
                    final isSelected = _stockSelectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF059669),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _stockSelectedCategory = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Food Items List with Direct 1-Tap Stock Buttons
        Expanded(
          child: StreamBuilder<List<FoodModel>>(
            stream: _firestoreService.getFoodItemsStream(
              category: _stockSelectedCategory,
              searchQuery: _stockSearchQuery,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final foods = snapshot.data ?? [];

              if (foods.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No food items match the search query.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                itemCount: foods.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final food = foods[index];
                  return _buildKitchenStockFoodTile(food);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStockStatusPill(String label, int count, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKitchenStockFoodTile(FoodModel food) {
    final bool isInStock = food.available;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInStock ? AppColors.border : Colors.red.shade200,
          width: isInStock ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Food Image with SOLD OUT Overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                CachedFoodImage(
                  imageUrl: food.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
                if (!isInStock)
                  Container(
                    width: 64,
                    height: 64,
                    color: Colors.black.withValues(alpha: 0.65),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SOLD OUT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Food Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: food.isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: food.isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        food.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isInStock ? AppColors.textPrimary : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${food.category} • ${CurrencyFormatter.format(food.price)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isInStock ? AppColors.primaryDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Admin-style In Stock / Out Switch Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isInStock ? 'In Stock' : 'Out',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isInStock ? const Color(0xFF059669) : Colors.red,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch.adaptive(
                  value: isInStock,
                  activeTrackColor: const Color(0xFF059669),
                  onChanged: (val) => _toggleFoodStock(food, val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildKitchenAppBar(String staffName) {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A), // Dark slate
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.soup_kitchen_rounded,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kitchen Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Chef: $staffName • Live Sync',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Instant Sync / Refresh Button
        IconButton(
          tooltip: 'Sync & Refresh Orders',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sync_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () {
            setState(() {});
            SnackbarUtils.showSuccess(context, '✓ Live orders queue synchronized!');
          },
        ),
        // Logout
        IconButton(
          tooltip: 'Logout',
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 18,
            ),
          ),
          onPressed: () async {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            await auth.signOut();
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsBar({
    required int pendingCount,
    required int acceptedCount,
    required int processingCount,
    required int readyCount,
    required int completedCount,
  }) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Row(
        children: [
          _buildStatPill(
            label: 'Pending',
            count: pendingCount,
            color: const Color(0xFFF59E0B), // Amber
            icon: Icons.hourglass_top_rounded,
          ),
          const SizedBox(width: 4),
          _buildStatPill(
            label: 'Accepted',
            count: acceptedCount,
            color: const Color(0xFF7C3AED), // Purple
            icon: Icons.thumb_up_alt_rounded,
          ),
          const SizedBox(width: 4),
          _buildStatPill(
            label: 'Preparing',
            count: processingCount,
            color: const Color(0xFF3B82F6), // Blue
            icon: Icons.soup_kitchen_rounded,
          ),
          const SizedBox(width: 4),
          _buildStatPill(
            label: 'Ready',
            count: readyCount,
            color: const Color(0xFF059669), // Emerald
            icon: Icons.notifications_active_rounded,
          ),
          const SizedBox(width: 4),
          _buildStatPill(
            label: 'Done',
            count: completedCount,
            color: const Color(0xFF10B981), // Green
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          final targetFilter = label == 'Done' ? 'Completed' : label;
          final tabIndex = _tabLabels.indexOf(targetFilter);
          if (tabIndex != -1) {
            _tabController.animateTo(tabIndex);
          }
          setState(() {
            _selectedFilter = targetFilter;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _selectedFilter == (label == 'Done' ? 'Completed' : label)
                  ? color
                  : color.withValues(alpha: 0.35),
              width: _selectedFilter == (label == 'Done' ? 'Completed' : label) ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 3),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs({
    required int allCount,
    required int pendingCount,
    required int acceptedCount,
    required int processingCount,
    required int readyCount,
    required int completedCount,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: _tabLabels.map((filter) {
          final isSelected = _selectedFilter == filter;
          int badgeCount = 0;
          Color chipColor = AppColors.primary;
          if (filter == 'All') {
            badgeCount = allCount;
            chipColor = const Color(0xFF0F172A);
          } else if (filter == 'Pending') {
            badgeCount = pendingCount;
            chipColor = const Color(0xFFF59E0B);
          } else if (filter == 'Accepted') {
            badgeCount = acceptedCount;
            chipColor = const Color(0xFF7C3AED);
          } else if (filter == 'Preparing') {
            badgeCount = processingCount;
            chipColor = const Color(0xFF3B82F6);
          } else if (filter == 'Ready') {
            badgeCount = readyCount;
            chipColor = const Color(0xFF059669);
          } else if (filter == 'Completed') {
            badgeCount = completedCount;
            chipColor = const Color(0xFF10B981);
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () {
                  final idx = _tabLabels.indexOf(filter);
                  if (idx != -1) {
                    _tabController.animateTo(idx);
                  }
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? chipColor : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? chipColor : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (badgeCount > 0) ...[
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : chipColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeCount.toString(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? chipColor : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKitchenOrderCard(OrderModel order) {
    final dateFormat = DateFormat('hh:mm a');
    final timeStr = dateFormat.format(order.createdAt);
    final minutesElapsed = DateTime.now().difference(order.createdAt).inMinutes;

    final isPending = order.isPending;
    final isAccepted = order.isAccepted;
    final isProcessing = order.isProcessing || order.isReady;
    final isCompleted = order.isCompleted;

    Color statusBorderColor = const Color(0xFFE2E8F0);
    if (isCompleted) {
      statusBorderColor = const Color(0xFF10B981);
    } else if (isProcessing) {
      statusBorderColor = const Color(0xFF3B82F6);
    } else if (isAccepted) {
      statusBorderColor = const Color(0xFF7C3AED);
    } else if (isPending) {
      statusBorderColor = const Color(0xFFF59E0B);
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => KitchenOrderDetailScreen(order: order),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusBorderColor.withValues(alpha: 0.7),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header with Token & Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Token Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : isProcessing
                              ? const Color(0xFF3B82F6)
                              : isAccepted
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'TOKEN ${order.tokenNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  // Order ID & Time
                  Row(
                    children: [
                      Text(
                        '#${order.orderId}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '$timeStr (${minutesElapsed}m ago)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Customer Name Info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      order.studentName.isNotEmpty ? order.studentName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Student: ${order.studentName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Items List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.subtotal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(
                    'Total: ${CurrencyFormatter.format(order.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _buildActionButton(order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(OrderModel order) {
    Widget? primaryButton;

    if (order.isPending) {
      primaryButton = ElevatedButton.icon(
        onPressed: () => _handleAcceptOrder(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED), // Purple
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
        label: const Text(
          'Accept',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      );
    } else if (order.isAccepted) {
      primaryButton = ElevatedButton.icon(
        onPressed: () => _handleStartProcessing(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6), // Blue
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        icon: const Icon(Icons.soup_kitchen_rounded, size: 16),
        label: const Text(
          'Prepare',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      );
    } else if (order.isProcessing) {
      primaryButton = ElevatedButton.icon(
        onPressed: () => _handleMarkReady(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669), // Emerald
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        icon: const Icon(Icons.notifications_active_rounded, size: 16),
        label: const Text(
          'Mark Ready',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      );
    } else if (order.isReady) {
      primaryButton = ElevatedButton.icon(
        onPressed: () => _handleCompleteOrder(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981), // Green
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        icon: const Icon(Icons.check_circle_rounded, size: 16),
        label: const Text(
          'Complete',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (order.isActive) ...[
          IconButton(
            tooltip: 'Cancel (Out of ingredients)',
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
            onPressed: () => _showCancelDialog(order),
          ),
          const SizedBox(width: 4),
        ],
        ?primaryButton,
      ],
    );
  }

  Widget _buildEmptyState(String filterName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              filterName == 'All'
                  ? Icons.receipt_long_rounded
                  : filterName == 'Completed'
                      ? Icons.check_circle_outline_rounded
                      : filterName == 'Ready'
                          ? Icons.notifications_active_rounded
                          : filterName == 'Preparing'
                              ? Icons.soup_kitchen_rounded
                              : filterName == 'Accepted'
                                  ? Icons.thumb_up_alt_rounded
                                  : Icons.hourglass_top_rounded,
              size: 48,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            filterName == 'All' ? 'No Orders in Queue' : 'No $filterName Orders',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filterName == 'All'
                ? 'Incoming student orders will appear here in real time.'
                : 'Orders in the "$filterName" stage will appear here.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
