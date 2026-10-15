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
import '../../widgets/loading_widget.dart';
import 'cart_screen.dart';
import 'food_details_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Snacks',
    'Beverages',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => Provider.of<FoodProvider>(context, listen: false).setSearchQuery(val),
                decoration: const InputDecoration(
                  hintText: 'Search food menu...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              )
            : const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: AppColors.textPrimary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  Provider.of<FoodProvider>(context, listen: false).clearSearch();
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer2<FoodProvider, CanteenProvider>(
        builder: (context, foodProvider, canteen, _) {
          final foods = foodProvider.filteredFoods;
          final isCanteenOpen = canteen.isCanteenOpen;

          return Column(
            children: [
              // Canteen Closed Notice Banner
              if (!isCanteenOpen)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_clock_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Canteen is Currently Closed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${canteen.closedNoticeMessage} You can still browse menu items, photos, and prices.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF7F1D1D),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Category Filter Pills
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = (cat == 'All' && foodProvider.selectedCategory == 'All') ||
                          (cat == 'Beverages' && foodProvider.selectedCategory == 'Cool Drinks') ||
                          (foodProvider.selectedCategory == cat);

                      return GestureDetector(
                        onTap: () {
                          if (cat == 'Beverages') {
                            foodProvider.selectCategory('Cool Drinks');
                          } else {
                            foodProvider.selectCategory(cat);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Sort Filters Bar: Most Rated & Price Wise
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Most Rated Chip
                      _buildSortFilterChip(
                        label: 'Top Rated',
                        icon: Icons.star_rounded,
                        isSelected: foodProvider.sortOption == FoodSortOption.mostRated,
                        onTap: () => foodProvider.setSortOption(FoodSortOption.mostRated),
                      ),
                      const SizedBox(width: 8),
                      // Price: Low to High Chip
                      _buildSortFilterChip(
                        label: 'Price: Low → High',
                        icon: Icons.arrow_upward_rounded,
                        isSelected: foodProvider.sortOption == FoodSortOption.priceLowToHigh,
                        onTap: () => foodProvider.setSortOption(FoodSortOption.priceLowToHigh),
                      ),
                      const SizedBox(width: 8),
                      // Price: High to Low Chip
                      _buildSortFilterChip(
                        label: 'Price: High → Low',
                        icon: Icons.arrow_downward_rounded,
                        isSelected: foodProvider.sortOption == FoodSortOption.priceHighToLow,
                        onTap: () => foodProvider.setSortOption(FoodSortOption.priceHighToLow),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Dish List
              Expanded(
                child: foodProvider.isLoading
                    ? const ShimmerFoodGrid(itemCount: 6)
                    : foods.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No Dishes Found',
                            message: 'Try adjusting your search query or pick a different category.',
                            buttonText: 'Reset Filters',
                            onButtonPressed: () {
                              _searchController.clear();
                              foodProvider.clearSearch();
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: foods.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final food = foods[index];
                              return _buildMenuItemTile(
                                context,
                                food,
                                cart,
                                isCanteenOpen: isCanteenOpen,
                                openTimeFormatted: canteen.openTimeFormatted,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),

      // Bottom Floating View Cart Banner
      bottomNavigationBar: Consumer2<CartProvider, CanteenProvider>(
        builder: (context, cart, canteen, _) {
          if (cart.totalCount == 0) return const SizedBox.shrink();

          final isCanteenOpen = canteen.isCanteenOpen;

          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCanteenOpen ? AppColors.primary : const Color(0xFF64748B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCanteenOpen ? Icons.shopping_bag_rounded : Icons.lock_outline_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCanteenOpen
                            ? 'View Cart (${cart.totalCount})'
                            : 'View Cart (Ordering Closed)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(cart.grandTotal),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemTile(
    BuildContext context,
    dynamic food,
    CartProvider cart, {
    required bool isCanteenOpen,
    required String openTimeFormatted,
  }) {
    final bool isAvailable = food.available == true;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodDetailsScreen(food: food)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? AppColors.border : const Color(0xFFFECACA),
          ),
        ),
        child: Row(
          children: [
            // Square Thumbnail Image with Sold Out overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  CachedFoodImage(
                    imageUrl: food.imageUrl,
                    width: 72,
                    height: 72,
                  ),
                  if (!isAvailable)
                    Container(
                      width: 72,
                      height: 72,
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
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Title & Price & Rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isAvailable ? AppColors.textPrimary : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(food.price),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isAvailable ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        '${food.rating} • ${food.preparationTime} mins',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add or Sold Out Button
            ElevatedButton(
              onPressed: () {
                if (!isAvailable) {
                  SnackbarUtils.showWarning(
                    context,
                    '${food.name} is currently sold out and unavailable to order.',
                  );
                  return;
                }

                if (!isCanteenOpen) {
                  SnackbarUtils.showError(
                    context,
                    'Canteen is currently closed. Ordering will reopen tomorrow at $openTimeFormatted.',
                  );
                  return;
                }

                cart.addItem(food);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${food.name} added to cart!'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: !isAvailable
                    ? const Color(0xFFF1F5F9)
                    : (isCanteenOpen ? AppColors.primary : const Color(0xFFE2E8F0)),
                foregroundColor: !isAvailable
                    ? const Color(0xFF94A3B8)
                    : (isCanteenOpen ? Colors.white : const Color(0xFF64748B)),
                minimumSize: const Size(68, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                !isAvailable
                    ? 'Sold Out'
                    : (isCanteenOpen ? 'Add' : 'Closed'),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: !isAvailable ? const Color(0xFFEF4444) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
