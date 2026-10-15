import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/food_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/cached_food_image.dart';

class AddEditFoodScreen extends StatefulWidget {
  final FoodModel? foodToEdit;

  const AddEditFoodScreen({super.key, this.foodToEdit});

  @override
  State<AddEditFoodScreen> createState() => _AddEditFoodScreenState();
}

class _AddEditFoodScreenState extends State<AddEditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  late TextEditingController _prepTimeController;

  late String _selectedCategory;
  late bool _isAvailable;
  late bool _isVeg;
  bool _isSaving = false;

  final List<String> _categoryOptions = AppConstants.specificCategories;

  @override
  void initState() {
    super.initState();
    final food = widget.foodToEdit;
    _nameController = TextEditingController(text: food?.name ?? '');
    _descController = TextEditingController(text: food?.description ?? '');
    _priceController = TextEditingController(
      text: food != null ? food.price.toStringAsFixed(0) : '',
    );
    _imageUrlController = TextEditingController(
      text: food?.imageUrl ??
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
    );
    _prepTimeController = TextEditingController(
      text: food?.prepTimeMinutes.toString() ?? '10',
    );

    _selectedCategory = food != null && _categoryOptions.contains(food.category)
        ? food.category
        : _categoryOptions.first;
    _isAvailable = food?.available ?? true;
    _isVeg = food?.isVeg ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      SnackbarUtils.showError(context, 'Please enter a valid price greater than 0');
      return;
    }

    final prepTime = int.tryParse(_prepTimeController.text.trim()) ?? 10;

    setState(() => _isSaving = true);

    try {
      final isEditing = widget.foodToEdit != null;
      final foodId = isEditing
          ? widget.foodToEdit!.foodId
          : 'food_${DateTime.now().millisecondsSinceEpoch}';

      final food = FoodModel(
        foodId: foodId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        category: _selectedCategory,
        imageUrl: _imageUrlController.text.trim(),
        available: _isAvailable,
        isVeg: _isVeg,
        preparationTime: prepTime,
        rating: widget.foodToEdit?.rating ?? 4.8,
        createdAt: widget.foodToEdit?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await _firestoreService.updateFood(food);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Dish "${food.name}" updated successfully!');
        }
      } else {
        await _firestoreService.addFood(food);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'New dish "${food.name}" added to menu!');
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to save food: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.foodToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Food Item' : 'Add New Food Item'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview Card
              _buildImagePreview(),
              const SizedBox(height: 20),

              // Dish Name
              AppTextField(
                controller: _nameController,
                label: 'Food Dish Name',
                hint: 'e.g., Paneer Butter Masala',
                prefixIcon: Icons.restaurant_menu_rounded,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Food name is required' : null,
              ),
              const SizedBox(height: 16),

              // Category Selector
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _categoryOptions.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(AppConstants.getCategoryIcon(cat),
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price & Prep Time Row
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _priceController,
                      label: 'Price (₹)',
                      hint: '60',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Price required';
                        if (double.tryParse(val.trim()) == null) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppTextField(
                      controller: _prepTimeController,
                      label: 'Prep Time (Mins)',
                      hint: '10',
                      prefixIcon: Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description Field
              AppTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Describe ingredients, preparation, taste, and sides...',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Image URL Field
              AppTextField(
                controller: _imageUrlController,
                label: 'Food Image URL',
                hint: 'https://images.unsplash.com/...',
                prefixIcon: Icons.image_outlined,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Image URL is required'
                    : null,
              ),
              const SizedBox(height: 20),

              // Switches: Veg & Available
              Container(
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 10,
                                color: _isVeg ? AppColors.vegGreen : AppColors.nonVegRed,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isVeg ? 'Vegetarian Dish' : 'Non-Vegetarian Dish',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isVeg,
                          activeTrackColor: AppColors.vegGreen,
                          onChanged: (val) => setState(() => _isVeg = val),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.borderSubtle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isAvailable
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: _isAvailable ? AppColors.primary : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isAvailable ? 'In Stock (Available)' : 'Sold Out (Unavailable)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isAvailable,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isAvailable = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              AppButton(
                text: isEditing ? 'Save Changes' : 'Add Food Item',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final url = _imageUrlController.text.trim();
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isNotEmpty)
              CachedFoodImage(imageUrl: url, fit: BoxFit.cover)
            else
              const Center(
                child: Icon(Icons.fastfood_rounded, size: 48, color: AppColors.textMuted),
              ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Live Preview',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
