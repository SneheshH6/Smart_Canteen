import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../providers/canteen_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/food_provider.dart';
import '../../widgets/cached_food_image.dart';
import '../../widgets/empty_state.dart';
import '../payment/payment_screen.dart';

class CartScreen extends StatelessWidget {
  final bool isTab;

  const CartScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: !isTab,
        leading: !isTab
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                tooltip: 'Clear Cart',
                onPressed: () {
                  cart.clearCart();
                  SnackbarUtils.showInfo(context, 'Cart cleared');
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer3<CartProvider, CanteenProvider, FoodProvider>(
        builder: (context, cart, canteen, foodProvider, _) {
          final items = cart.itemsList;
          final isCanteenOpen = canteen.isCanteenOpen;

          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Your Cart is Empty',
              message: 'Looks like you haven\'t added any delicious food items from the canteen menu yet.',
              buttonText: 'Explore Menu',
              onButtonPressed: () {
                if (!isTab) {
                  Navigator.of(context).pop();
                }
              },
            );
          }

          // Check for sold-out items currently in cart
          final soldOutItems = items.where((item) {
            final currentFood = foodProvider.allFoods.firstWhere(
              (f) => f.foodId == item.food.foodId,
              orElse: () => item.food,
            );
            return !currentFood.available;
          }).toList();

          final hasSoldOutItems = soldOutItems.isNotEmpty;

          return Column(
            children: [
              // Closed Alert Banner
              if (!isCanteenOpen)
                Container(
                  color: const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          canteen.closedNoticeMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Sold Out Alert Banner (if cart contains items marked sold-out)
              if (hasSoldOutItems)
                Container(
                  color: const Color(0xFFFFF1F2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '⚠️ ${soldOutItems.map((e) => e.food.name).join(', ')} is currently SOLD OUT. Please remove it from your tray to proceed to checkout.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9F1239),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Items List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final currentFood = foodProvider.allFoods.firstWhere(
                      (f) => f.foodId == item.food.foodId,
                      orElse: () => item.food,
                    );
                    final isItemSoldOut = !currentFood.available;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isItemSoldOut ? const Color(0xFFFECACA) : AppColors.border,
                          width: isItemSoldOut ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Food Thumbnail with Sold-Out overlay
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                CachedFoodImage(
                                  imageUrl: currentFood.imageUrl,
                                  width: 64,
                                  height: 64,
                                ),
                                if (isItemSoldOut)
                                  Container(
                                    width: 64,
                                    height: 64,
                                    color: Colors.black.withValues(alpha: 0.65),
                                    alignment: Alignment.center,
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        currentFood.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isItemSoldOut ? const Color(0xFF64748B) : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isItemSoldOut)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Remove Sold Out Item',
                                        onPressed: () {
                                          cart.removeItem(currentFood.foodId);
                                          SnackbarUtils.showInfo(context, '${currentFood.name} removed from cart');
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(currentFood.price),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isItemSoldOut ? AppColors.textMuted : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (isItemSoldOut) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Text(
                                          'Out of Stock',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Stepper
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () => cart.updateQuantity(currentFood.foodId, item.quantity - 1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: const Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: isItemSoldOut
                                          ? null
                                          : () => cart.updateQuantity(currentFood.foodId, item.quantity + 1),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isItemSoldOut ? const Color(0xFFCBD5E1) : AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Total & Checkout Bar matching Screen 6
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(cart.grandTotal),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (!isCanteenOpen) {
                            SnackbarUtils.showError(
                              context,
                              'Canteen is currently closed. Ordering will reopen tomorrow at ${canteen.openTimeFormatted}.',
                            );
                            return;
                          }

                          if (hasSoldOutItems) {
                            SnackbarUtils.showError(
                              context,
                              'Please remove sold out items (${soldOutItems.map((e) => e.food.name).join(", ")}) before checking out.',
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PaymentScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (!isCanteenOpen || hasSoldOutItems)
                              ? const Color(0xFF94A3B8)
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              !isCanteenOpen
                                  ? 'Ordering Closed'
                                  : (hasSoldOutItems ? 'Remove Sold Out Items' : 'Proceed to Checkout'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              !isCanteenOpen
                                  ? Icons.lock_clock_rounded
                                  : (hasSoldOutItems ? Icons.warning_amber_rounded : Icons.arrow_forward_rounded),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

