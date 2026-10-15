import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/food_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/cached_food_image.dart';

class KitchenMenuToggleSheet extends StatefulWidget {
  const KitchenMenuToggleSheet({super.key});

  @override
  State<KitchenMenuToggleSheet> createState() => _KitchenMenuToggleSheetState();
}

class _KitchenMenuToggleSheetState extends State<KitchenMenuToggleSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Live Menu Availability',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Toggle items out of stock in real-time',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _search = val),
              decoration: InputDecoration(
                hintText: 'Search food dishes...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 16),

          // Items Stream
          Expanded(
            child: StreamBuilder<List<FoodModel>>(
              stream: _firestoreService.getFoodItemsStream(
                searchQuery: _search,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final foods = snapshot.data ?? [];

                if (foods.isEmpty) {
                  return const Center(
                    child: Text('No food items found matching search.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: foods.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return Row(
                      children: [
                        CachedFoodImage(
                          imageUrl: food.imageUrl,
                          width: 48,
                          height: 48,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${food.category} • ${CurrencyFormatter.format(food.price)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: food.available,
                          activeTrackColor: AppColors.primary,
                          onChanged: (newVal) async {
                            await _firestoreService.toggleFoodAvailability(
                              food.foodId,
                              newVal,
                            );
                            if (context.mounted) {
                              SnackbarUtils.showSuccess(
                                context,
                                '${food.name} marked as ${newVal ? "Available" : "Sold Out"}',
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
