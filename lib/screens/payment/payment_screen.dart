import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/canteen_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';
import '../student/order_success_screen.dart';
import '../student/wallet_screen.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel? order;

  const PaymentScreen({
    super.key,
    this.order,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final FirestoreService _firestoreService = FirestoreService();
  PaymentMethodType _selectedMethod = PaymentMethodType.upi;
  String _selectedUpiApp = 'Google Pay';
  bool _isProcessing = false;
  PaymentResult? _paymentResult;
  bool _forceFailureToggle = false;
  OrderModel? _completedOrder;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _upiApps = [
    {'name': 'Google Pay', 'icon': Icons.account_balance_wallet_rounded, 'color': Color(0xFF1A73E8)},
    {'name': 'PhonePe', 'icon': Icons.payments_rounded, 'color': Color(0xFF5F259F)},
    {'name': 'Paytm', 'icon': Icons.qr_code_2_rounded, 'color': Color(0xFF00B9F5)},
    {'name': 'BHIM UPI', 'icon': Icons.send_to_mobile_rounded, 'color': Color(0xFF00833F)},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    final canteen = Provider.of<CanteenProvider>(context, listen: false);
    if (!canteen.isCanteenOpen) {
      SnackbarUtils.showError(
        context,
        'Canteen is currently closed. Ordering will reopen tomorrow at ${canteen.openTimeFormatted}.',
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      SnackbarUtils.showError(context, 'Please sign in to place your order.');
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (widget.order == null && cart.items.isEmpty) {
      SnackbarUtils.showError(context, 'Your tray is empty!');
      Navigator.pop(context);
      return;
    }

    final double amount = widget.order != null ? widget.order!.totalAmount : cart.grandTotal;

    // Check wallet balance when paying with Student Meal Pass / Wallet
    if (_selectedMethod == PaymentMethodType.mealPass) {
      final balance = user.walletBalance;
      if (balance < amount) {
        final shortfall = amount - balance;
        SnackbarUtils.showError(
          context,
          'Insufficient wallet balance. Please add ₹${shortfall.toStringAsFixed(0)}.',
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _paymentResult = null;
    });

    try {
      if (_selectedMethod == PaymentMethodType.mealPass) {
        // Direct Campus Meal Pass
        await Future.delayed(const Duration(milliseconds: 900));

        if (_forceFailureToggle) {
          setState(() {
            _isProcessing = false;
            _paymentResult = PaymentResult(
              isSuccess: false,
              transactionId: 'TXN_FAIL_${DateTime.now().millisecondsSinceEpoch}',
              message: 'Campus Wallet transaction was declined by bank gateway simulator.',
              status: PaymentStatus.failed,
              timestamp: DateTime.now(),
            );
          });
          return;
        }

        if (widget.order != null) {
          await _firestoreService.updateOrderPaymentStatus(
            widget.order!.orderId,
            'Paid',
            orderStatus: OrderStatusConstants.pending,
          );
          _completedOrder = widget.order;
        } else {
          final created = await orderProvider.placeOrder(
            user: user,
            cart: cart,
            paymentMethod: 'Campus Meal Pass',
            pickupNotes: null,
          );
          if (created == null) {
            throw Exception(orderProvider.errorMessage ?? 'Failed to place order in kitchen');
          }
          _completedOrder = created;
        }

        _paymentResult = PaymentResult(
          isSuccess: true,
          transactionId: 'WALLET_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
          message: 'Paid ₹${amount.toStringAsFixed(2)} via Student Campus Meal Pass.',
          status: PaymentStatus.successful,
          timestamp: DateTime.now(),
        );
        _animController.forward(from: 0.0);
      } else if (_selectedMethod == PaymentMethodType.counterCash) {
        // Cash at Counter
        await Future.delayed(const Duration(milliseconds: 700));

        if (widget.order != null) {
          _completedOrder = widget.order;
        } else {
          final created = await orderProvider.placeOrder(
            user: user,
            cart: cart,
            paymentMethod: 'Counter Cash',
            pickupNotes: null,
          );
          if (created == null) {
            throw Exception(orderProvider.errorMessage ?? 'Failed to place order in kitchen');
          }
          _completedOrder = created;
        }

        _paymentResult = PaymentResult(
          isSuccess: true,
          transactionId: 'CASH_COUNTER_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          message: 'Order confirmed! Please pay ₹${amount.toStringAsFixed(0)} at counter upon collection.',
          status: PaymentStatus.successful,
          timestamp: DateTime.now(),
        );
        _animController.forward(from: 0.0);
      } else {
        // UPI or Card via PaymentService
        final String orderIdForPayment = widget.order?.orderId ?? 'ORD_TEMP';
        final result = await _paymentService.processPayment(
          amount: amount,
          orderId: orderIdForPayment,
          methodType: _selectedMethod,
          forceFailure: _forceFailureToggle,
        );

        if (!mounted) return;

        if (result.isSuccess) {
          final methodLabel = _selectedMethod == PaymentMethodType.upi
              ? 'UPI ($_selectedUpiApp)'
              : 'Card';

          if (widget.order != null) {
            await _firestoreService.updateOrderPaymentStatus(
              widget.order!.orderId,
              'Paid',
              orderStatus: OrderStatusConstants.pending,
            );
            cart.clearCart();
            _completedOrder = widget.order;
          } else {
            final created = await orderProvider.placeOrder(
              user: user,
              cart: cart,
              paymentMethod: methodLabel,
              pickupNotes: null,
            );
            if (created == null) {
              throw Exception(orderProvider.errorMessage ?? 'Failed to place order in kitchen');
            }
            _completedOrder = created;
          }

          _paymentResult = result;
          _animController.forward(from: 0.0);
        } else {
          _paymentResult = result;
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Transaction error: $e');
        _paymentResult = PaymentResult(
          isSuccess: false,
          transactionId: 'ERR_${DateTime.now().millisecondsSinceEpoch}',
          message: 'An error occurred while completing checkout: $e',
          status: PaymentStatus.failed,
          timestamp: DateTime.now(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment & Checkout'),
        centerTitle: true,
        leading: _isProcessing
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildProcessingState();
    }

    if (_paymentResult != null) {
      if (_paymentResult!.isSuccess) {
        return _buildSuccessState();
      } else {
        return _buildFailureState();
      }
    }

    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final walletBalance = user?.walletBalance ?? 0.0;
    final double totalAmount = widget.order != null ? widget.order!.totalAmount : cart.grandTotal;
    final int totalCount = widget.order != null ? widget.order!.itemCount : cart.totalCount;
    final bool hasShortfall = _selectedMethod == PaymentMethodType.mealPass && walletBalance < totalAmount;
    final double shortfall = totalAmount - walletBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Due Banner
          _buildAmountBanner(totalAmount, totalCount),
          const SizedBox(height: 20),

          // Order Snapshot Card
          _buildOrderSummaryCard(cart),
          const SizedBox(height: 24),

          // Payment Methods Header
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Payment Method Options
          _buildPaymentMethodOption(
            type: PaymentMethodType.upi,
            title: 'UPI Payment',
            subtitle: 'Instant payment via GPay, PhonePe, Paytm, QR',
            icon: Icons.qr_code_scanner_rounded,
          ),
          if (_selectedMethod == PaymentMethodType.upi) _buildUpiAppSelector(),
          const SizedBox(height: 10),

          _buildPaymentMethodOption(
            type: PaymentMethodType.mealPass,
            title: 'Student Meal Pass / ID Wallet',
            subtitle: 'Available Balance: ${CurrencyFormatter.format(walletBalance)}',
            icon: Icons.badge_rounded,
          ),
          if (hasShortfall) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Shortfall: ₹${shortfall.toStringAsFixed(0)}. Your balance is ${CurrencyFormatter.format(walletBalance)}.',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Top-Up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          _buildPaymentMethodOption(
            type: PaymentMethodType.counterCash,
            title: 'Cash at Canteen Counter',
            subtitle: 'Pay at the counter when collecting token',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 10),

          _buildPaymentMethodOption(
            type: PaymentMethodType.card,
            title: 'Debit / Credit Card (Sandbox)',
            subtitle: 'Safe simulated academic card payment',
            icon: Icons.credit_card_rounded,
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.science_rounded, size: 20, color: Colors.amber.shade800),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simulate Payment Failure',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: _forceFailureToggle,
                  activeTrackColor: Colors.amber.shade800,
                  onChanged: (val) {
                    setState(() {
                      _forceFailureToggle = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Security Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                '100% Safe & Secure Campus Transaction',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 3,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Pay ${CurrencyFormatter.format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAmountBanner(double totalAmount, int totalCount) {
    final token = widget.order?.tokenNumber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Payable Amount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(totalAmount),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              token != null
                  ? 'Token $token • $totalCount Items'
                  : '$totalCount ${totalCount == 1 ? 'Item' : 'Items'} • Instant Campus Token',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartProvider cart) {
    if (widget.order != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order ID',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  widget.order!.orderId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.borderSubtle),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items Ordered',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  widget.order!.items.map((e) => '${e.quantity}x ${e.name}').join(', '),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tray Items Summary',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                '${cart.totalCount} items',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...cart.itemsList.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}× ${item.food.name}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(item.totalPrice),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                ),
              ],
            ),
          )),
          const Divider(height: 18, color: AppColors.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Items Subtotal', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(CurrencyFormatter.format(cart.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Canteen Convenience & Packaging', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(CurrencyFormatter.format(cart.canteenConvenienceFee), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(CurrencyFormatter.format(cart.grandTotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required PaymentMethodType type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = type;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySoft : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // ignore: deprecated_member_use
            Radio<PaymentMethodType>(
              value: type,
              // ignore: deprecated_member_use
              groupValue: _selectedMethod,
              activeColor: AppColors.primary,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedMethod = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiAppSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose UPI App:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _upiApps.map((app) {
              final isAppSelected = _selectedUpiApp == app['name'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedUpiApp = app['name'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAppSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAppSelected ? AppColors.primary : Colors.transparent,
                    ),
                    boxShadow: isAppSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        app['icon'] as IconData,
                        color: app['color'] as Color,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app['name'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isAppSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Processing Payment...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Please do not press back or close the app while contacting payment gateway.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Consumer<CartProvider>(
              builder: (context, cart, _) {
                final displayAmount = widget.order != null ? widget.order!.totalAmount : cart.grandTotal;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Amount: ${CurrencyFormatter.format(displayAmount)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final currentOrder = _completedOrder ?? widget.order;
    final token = currentOrder?.tokenNumber ?? '#--';
    final amountPaid = currentOrder?.totalAmount ?? 0.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedMethod == PaymentMethodType.counterCash
                  ? 'Order Placed at Counter! 🎉'
                  : 'Payment Successful! 🎉',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: ${_paymentResult?.transactionId ?? ""}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount Paid',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        CurrencyFormatter.format(amountPaid),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: AppColors.borderSubtle),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pickup Token',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          token,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (currentOrder != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => OrderSuccessScreen(
                          order: currentOrder.copyWith(
                            paymentStatus: _selectedMethod == PaymentMethodType.counterCash
                                ? 'Pending'
                                : 'Paid',
                            orderStatus: 'Pending',
                          ),
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'View Live Order Confirmation',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _paymentResult?.message ?? 'Payment transaction could not be processed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _forceFailureToggle = false;
                    _paymentResult = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Retry Payment',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _paymentResult = null;
                });
              },
              child: const Text(
                'Change Payment Method',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundedRectangle64 extends RoundedRectangleBorder {
  RoundedRectangle64(double radius) : super(borderRadius: BorderRadius.circular(radius));
}
