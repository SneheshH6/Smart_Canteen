import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/loading_widget.dart';
import 'student_main_screen.dart';
import 'submit_feedback_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Order Tracking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const StudentMainScreen()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Kitchen Help',
            icon: const Icon(Icons.headset_mic_outlined, color: AppColors.primary),
            onPressed: () => _showKitchenHelpDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<OrderModel?>(
        stream: orderProvider.getSingleOrderStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const LoadingWidget(message: 'Loading live order status...');
          }

          final order = snapshot.data;
          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const StudentMainScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            );
          }

          final timeFormat = DateFormat('hh:mm a');
          final orderTime = timeFormat.format(order.createdAt);
          final estimatedTime = timeFormat.format(order.createdAt.add(const Duration(minutes: 15)));

          final isCancelled = order.isCancelled;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order ID',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.tokenNumber.startsWith('#') ? order.tokenNumber : '#${order.tokenNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: order.statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: order.statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: order.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isCancelled
                      ? (order.cancellationReason != null && order.cancellationReason!.isNotEmpty
                          ? 'Cancelled by Kitchen: ${order.cancellationReason}'
                          : 'Order was cancelled by the kitchen due to out of stock ingredients.')
                      : order.isPreparing
                          ? 'We are preparing your delicious food.'
                          : order.isReady
                              ? 'Your food is hot & ready for pickup at Counter 1!'
                              : order.isCompleted
                                  ? 'Your order has been completed. Enjoy!'
                                  : 'Order has been placed and received by canteen.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isCancelled ? Colors.red.shade700 : AppColors.textSecondary,
                    fontWeight: isCancelled ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 24),

                if (isCancelled) ...[
                  // Dedicated Cancellation Notice Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.soup_kitchen_rounded, color: Colors.red, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Message from Kitchen',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                  Text(
                                    'Notice sent to you for Token #${order.tokenNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reason:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.cancellationReason ?? 'Out of stock ingredients',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'The kitchen ran out of essential fresh ingredients for your requested items and cannot fulfill this order at this time.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Refund Confirmation
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '₹${order.totalAmount.toStringAsFixed(0)} automatically credited back to your Wallet balance.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentMainScreen(initialIndex: 0)),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                    label: const Text(
                      'Browse Menu & Reorder',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentMainScreen(initialIndex: 2)),
                      );
                    },
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    label: const Text(
                      'View Wallet Balance',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else ...[
                  // Normal 5-Step Vertical Timeline matching Screen 7
                  _buildTimelineStep(
                    stepNumber: 1,
                    title: 'Order Placed',
                    time: orderTime,
                    isCompleted: order.statusStepIndex >= 0,
                    isActive: order.statusStepIndex == 0,
                  ),
                  _buildTimelineLine(isPassed: order.statusStepIndex >= 1),

                  _buildTimelineStep(
                    stepNumber: 2,
                    title: 'Confirmed / Accepted',
                    time: order.statusStepIndex >= 1 ? orderTime : '--',
                    isCompleted: order.statusStepIndex >= 1,
                    isActive: order.statusStepIndex == 1,
                  ),
                  _buildTimelineLine(isPassed: order.statusStepIndex >= 2),

                  _buildTimelineStep(
                    stepNumber: 3,
                    title: 'Preparing',
                    time: order.statusStepIndex >= 2 ? orderTime : '--',
                    isCompleted: order.statusStepIndex >= 2,
                    isActive: order.statusStepIndex == 2,
                    isCooking: order.statusStepIndex == 2,
                  ),
                  _buildTimelineLine(isPassed: order.statusStepIndex >= 3),

                  _buildTimelineStep(
                    stepNumber: 4,
                    title: 'Ready to Pickup',
                    time: order.statusStepIndex >= 3 ? orderTime : estimatedTime,
                    isCompleted: order.statusStepIndex >= 3,
                    isActive: order.statusStepIndex == 3,
                  ),
                  _buildTimelineLine(isPassed: order.statusStepIndex >= 4),

                  _buildTimelineStep(
                    stepNumber: 5,
                    title: 'Completed',
                    time: order.statusStepIndex >= 4 ? orderTime : '--',
                    isCompleted: order.statusStepIndex >= 4,
                    isActive: order.statusStepIndex == 4,
                    isLast: true,
                  ),

                  const SizedBox(height: 32),

                  // Estimated Pickup Time Card matching Screen 7
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Pickup Time',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          estimatedTime,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Need Help? Outline Button with Kitchen Contact
                  OutlinedButton.icon(
                    onPressed: () => _showKitchenHelpDialog(context),
                    icon: const Icon(Icons.headset_mic_outlined, size: 18),
                    label: const Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  if (order.isCompleted) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SubmitFeedbackScreen(order: order)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Rate Your Food & Service', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String time,
    required bool isCompleted,
    required bool isActive,
    bool isCooking = false,
    bool isLast = false,
  }) {
    Color iconBg;
    Widget iconChild;

    if (isActive) {
      iconBg = AppColors.primary;
      iconChild = const Icon(Icons.circle, size: 10, color: Colors.white);
    } else if (isCompleted) {
      iconBg = AppColors.primary;
      iconChild = const Icon(Icons.check, size: 14, color: Colors.white);
    } else {
      iconBg = Colors.white;
      iconChild = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(child: iconChild),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive || isCompleted ? FontWeight.w700 : FontWeight.w500,
              color: isActive || isCompleted ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive || isCompleted ? AppColors.textSecondary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isPassed}) {
    return Container(
      margin: const EdgeInsets.only(left: 13),
      width: 2,
      height: 24,
      color: isPassed ? AppColors.primary : AppColors.border,
    );
  }

  void _showKitchenHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.soup_kitchen_rounded,
                color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text(
              'Kitchen Support',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need assistance with your order or food preparation? Contact the canteen kitchen directly:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_in_talk_rounded,
                      color: AppColors.primaryDark, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '+918590626036',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
