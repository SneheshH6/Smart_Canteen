import 'order_model.dart';

/// Model representing aggregated payment stats for the monthly revenue report
class PaymentMethodStat {
  final String method;
  final int count;
  final double totalAmount;
  final double percentage;

  PaymentMethodStat({
    required this.method,
    required this.count,
    required this.totalAmount,
    required this.percentage,
  });
}

/// Model representing aggregated popular food stats for the monthly revenue report
class PopularFoodStat {
  final String name;
  final int quantity;
  final double revenue;

  PopularFoodStat({
    required this.name,
    required this.quantity,
    required this.revenue,
  });
}

/// Comprehensive Report Data Bundle for Monthly Revenue and Analytics
class MonthlyRevenueReportData {
  final int month;
  final int year;
  final String monthName;
  final DateTime generatedAt;
  final double totalRevenue;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int preparingOrders;
  final int readyOrders;
  final int cancelledOrders;
  final double completionRate;
  final List<PaymentMethodStat> paymentStats;
  final List<PopularFoodStat> topFoods;
  final List<OrderModel> orders;

  MonthlyRevenueReportData({
    required this.month,
    required this.year,
    required this.monthName,
    required this.generatedAt,
    required this.totalRevenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.cancelledOrders,
    required this.completionRate,
    required this.paymentStats,
    required this.topFoods,
    required this.orders,
  });

  factory MonthlyRevenueReportData.fromOrders({
    required List<OrderModel> allOrders,
    required int month,
    required int year,
  }) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = (month >= 1 && month <= 12) ? monthNames[month - 1] : 'Month $month';

    // 1. Deduplicate by orderId and filter by selected month & year
    final Map<String, OrderModel> uniqueMonthOrders = {};
    for (final order in allOrders) {
      if (order.createdAt.year == year && order.createdAt.month == month) {
        uniqueMonthOrders[order.orderId] = order;
      }
    }

    final List<OrderModel> filteredOrders = uniqueMonthOrders.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 2. Count statuses
    int completedCount = 0;
    int pendingCount = 0;
    int preparingCount = 0;
    int readyCount = 0;
    int cancelledCount = 0;

    for (final o in filteredOrders) {
      if (o.isCompleted) {
        completedCount++;
      } else if (o.isReady) {
        readyCount++;
      } else if (o.isProcessing) {
        preparingCount++;
      } else if (o.isCancelled) {
        cancelledCount++;
      } else {
        pendingCount++;
      }
    }

    // 3. Accurate Revenue: Sum completed or paid orders that are NOT cancelled
    final paidOrders = filteredOrders.where((o) =>
        (o.isCompleted || o.paymentStatus.trim().toLowerCase() == 'paid') &&
        !o.isCancelled).toList();

    final totalRevenue = paidOrders.fold<double>(0.0, (sum, o) => sum + o.totalAmount);

    // 4. Payment breakdown
    final Map<String, List<OrderModel>> methodGroups = {};
    for (final o in paidOrders) {
      String m = o.paymentMethod.trim();
      if (m.isEmpty) m = 'Meal Pass / Wallet';
      if (m.toLowerCase().contains('wallet') || m.toLowerCase().contains('pass')) {
        m = 'Campus Meal Pass / Wallet';
      } else if (m.toLowerCase().contains('upi') || m.toLowerCase().contains('gpay') || m.toLowerCase().contains('paytm')) {
        m = 'UPI / Net Banking';
      } else if (m.toLowerCase().contains('card')) {
        m = 'Debit / Credit Card';
      } else if (m.toLowerCase().contains('cash')) {
        m = 'Cash on Counter';
      }
      methodGroups.putIfAbsent(m, () => []).add(o);
    }

    // Default ensure all main channels are visible
    final List<String> standardChannels = [
      'Campus Meal Pass / Wallet',
      'UPI / Net Banking',
      'Debit / Credit Card',
      'Cash on Counter',
    ];
    for (final ch in standardChannels) {
      methodGroups.putIfAbsent(ch, () => []);
    }

    final List<PaymentMethodStat> paymentStats = [];
    methodGroups.forEach((method, list) {
      final subtotal = list.fold<double>(0.0, (sum, o) => sum + o.totalAmount);
      final pct = totalRevenue > 0 ? (subtotal / totalRevenue) * 100 : 0.0;
      paymentStats.add(PaymentMethodStat(
        method: method,
        count: list.length,
        totalAmount: subtotal,
        percentage: pct,
      ));
    });
    // Sort payment stats by revenue descending
    paymentStats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    // 5. Food popularity
    final Map<String, int> foodQty = {};
    final Map<String, double> foodRev = {};
    for (final o in paidOrders) {
      for (final item in o.items) {
        foodQty[item.name] = (foodQty[item.name] ?? 0) + item.quantity;
        foodRev[item.name] = (foodRev[item.name] ?? 0) + item.subtotal;
      }
    }

    final List<PopularFoodStat> topFoods = foodQty.entries.map((e) {
      return PopularFoodStat(
        name: e.key,
        quantity: e.value,
        revenue: foodRev[e.key] ?? 0.0,
      );
    }).toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final totalOrders = filteredOrders.length;
    final completionRate = totalOrders > 0 ? (completedCount / totalOrders) * 100 : 0.0;

    return MonthlyRevenueReportData(
      month: month,
      year: year,
      monthName: monthName,
      generatedAt: DateTime.now(),
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      completedOrders: completedCount,
      pendingOrders: pendingCount,
      preparingOrders: preparingCount,
      readyOrders: readyCount,
      cancelledOrders: cancelledCount,
      completionRate: completionRate,
      paymentStats: paymentStats,
      topFoods: topFoods,
      orders: filteredOrders,
    );
  }
}
