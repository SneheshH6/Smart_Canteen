import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/food_model.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import '../kitchen/kitchen_dashboard_screen.dart';
import 'admin_canteen_schedule_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_menu_management_screen.dart';
import 'admin_order_management_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_user_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B4B), // Deep Indigo
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Canteen Admin Console',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Administrator: ${user?.name ?? "Admin"}',
                  style: const TextStyle(
                    color: Color(0xFFC7D2FE),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: firestoreService.getAllOrdersStream(),
        builder: (context, orderSnapshot) {
          return StreamBuilder<List<FoodModel>>(
            stream: firestoreService.getFoodItemsStream(),
            builder: (context, foodSnapshot) {
              return StreamBuilder<List<UserModel>>(
                stream: firestoreService.getAllUsersStream(),
                builder: (context, userSnapshot) {
                  final orders = orderSnapshot.data ?? [];
                  final foods = foodSnapshot.data ?? [];
                  final users = userSnapshot.data ?? [];

                  final totalSales = orders.fold<double>(
                    0.0,
                    (sum, item) => sum + item.totalAmount,
                  );
                  final pendingCount = orders.where((o) => o.isPending).length;
                  final completedCount = orders.where((o) => o.isCompleted).length;
                  final availableFoods = foods.where((f) => f.available).length;
                  final unavailableFoods = foods.where((f) => !f.available).length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Revenue Banner
                        _buildRevenueCard(context, totalSales, orders.length),
                        const SizedBox(height: 16),

                        // Stats Grid (Total Users, Total Orders, Pending, Completed, Available, Out of Stock)
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Total Users',
                                value: users.length.toString(),
                                icon: Icons.people_alt_rounded,
                                color: const Color(0xFF6366F1),
                                bg: const Color(0xFFEEF2FF),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Total Orders',
                                value: orders.length.toString(),
                                icon: Icons.receipt_long_rounded,
                                color: const Color(0xFF0284C7),
                                bg: const Color(0xFFE0F2FE),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Pending Orders',
                                value: pendingCount.toString(),
                                icon: Icons.hourglass_top_rounded,
                                color: const Color(0xFFD97706),
                                bg: const Color(0xFFFEF3C7),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Completed',
                                value: completedCount.toString(),
                                icon: Icons.check_circle_rounded,
                                color: AppColors.primary,
                                bg: AppColors.primarySoft,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'In-Stock Menu',
                                value: availableFoods.toString(),
                                icon: Icons.restaurant_rounded,
                                color: AppColors.vegGreen,
                                bg: const Color(0xFFECFDF5),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Sold Out Dishes',
                                value: unavailableFoods.toString(),
                                icon: Icons.cancel_outlined,
                                color: AppColors.error,
                                bg: Colors.red.shade50,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Management Modules
                        const Text(
                          'Canteen Administration Modules',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 1. Menu Management
                        _buildModuleTile(
                          context,
                          title: 'Food Menu Management',
                          subtitle: 'Add, edit, delete dishes, set prices & stock',
                          icon: Icons.fastfood_rounded,
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminMenuManagementScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // 2. User Management
                        _buildModuleTile(
                          context,
                          title: 'User & Role Management',
                          subtitle: 'Manage user, kitchen, and admin accounts',
                          icon: Icons.manage_accounts_rounded,
                          color: const Color(0xFF6366F1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminUserManagementScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // 3. Order Management
                        _buildModuleTile(
                          context,
                          title: 'All Orders & Transactions',
                          subtitle: 'Search tokens, filter status, inspect details',
                          icon: Icons.receipt_rounded,
                          color: const Color(0xFF0284C7),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminOrderManagementScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // 4. Reports & Analytics
                        _buildModuleTile(
                          context,
                          title: 'Reports & Revenue Analytics',
                          subtitle: 'Sales charts, order distribution & popular items',
                          icon: Icons.insert_chart_rounded,
                          color: const Color(0xFF059669),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // 5. User Feedback & Reviews
                        _buildModuleTile(
                          context,
                          title: 'User Feedback & Reviews',
                          subtitle: 'Read user ratings, suggestions, and feedback',
                          icon: Icons.rate_review_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // 6. Canteen Operating Hours & Schedule
                        _buildModuleTile(
                          context,
                          title: 'Operating Hours & Schedule',
                          subtitle: 'Set daily opening (8:00 AM) & closing (5:30 PM) timings in IST',
                          icon: Icons.schedule_rounded,
                          color: const Color(0xFF7C3AED),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminCanteenScheduleScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // 7. Kitchen Terminal View
                        _buildModuleTile(
                          context,
                          title: 'Kitchen Staff Terminal',
                          subtitle: 'Switch to live cooking and preparation terminal',
                          icon: Icons.soup_kitchen_rounded,
                          color: AppColors.accent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KitchenDashboardScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context, double totalSales, int totalOrders) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL CANTEEN REVENUE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC7D2FE),
                  letterSpacing: 1,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.insights_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Monthly Revenue',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(totalSales),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Total Lifetime Orders: $totalOrders',
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
