import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../models/feedback_model.dart';
import '../../models/food_review_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/cached_food_image.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  final OrderModel? order;

  const SubmitFeedbackScreen({super.key, this.order});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Map<String, double> _itemRatings = {};
  final Map<String, TextEditingController> _itemReviewControllers = {};

  double _foodRating = 5.0;
  double _serviceRating = 5.0;
  String _selectedType = FeedbackTypeConstants.feedback;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.order != null && widget.order!.items.isNotEmpty) {
      for (final item in widget.order!.items) {
        _itemRatings[item.foodId] = 5.0;
        _itemReviewControllers[item.foodId] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final controller in _itemReviewControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final userId = user?.userId ?? 'student_guest';
      final userName = user?.name ?? 'Student';

      // 1. Submit individual Food Reviews and dynamically recalculate live food ratings
      if (widget.order != null && widget.order!.items.isNotEmpty) {
        for (final item in widget.order!.items) {
          final rating = _itemRatings[item.foodId] ?? _foodRating;
          final comment = _itemReviewControllers[item.foodId]?.text.trim() ?? '';

          final foodReview = FoodReviewModel(
            reviewId: 'rev_${DateTime.now().millisecondsSinceEpoch}_${item.foodId}',
            foodId: item.foodId,
            foodName: item.name,
            orderId: widget.order!.orderId,
            userId: userId,
            userName: userName,
            rating: rating,
            comment: comment.isNotEmpty ? comment : _commentController.text.trim(),
            createdAt: DateTime.now(),
          );

          await _firestoreService.submitFoodReview(foodReview);
        }
      }

      // 2. Submit general feedback entry for admin & analytics
      final feedback = FeedbackModel(
        feedbackId: 'fb_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        userName: userName,
        orderId: widget.order?.orderId ?? 'ORD_DIRECT',
        foodId: widget.order?.items.isNotEmpty == true ? widget.order!.items.first.foodId : '',
        foodRating: _foodRating,
        serviceRating: _serviceRating,
        type: _selectedType,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _firestoreService.submitFeedback(feedback);

      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          'Thank you! Your ratings & review have been submitted and updated on the menu.',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to submit feedback: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasOrderItems = widget.order != null && widget.order!.items.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rate Food & Feedback'),
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
              if (widget.order != null) _buildOrderHeaderCard(),
              const SizedBox(height: 16),

              // Feedback Type Selector
              const Text(
                'Select Feedback Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: FeedbackTypeConstants.allTypes.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedType = type);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Rate Individual Ordered Food Items
              if (hasOrderItems) ...[
                const Row(
                  children: [
                    Icon(Icons.restaurant_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Rate Your Dishes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Give 1–5 stars and optional review. Ratings automatically update menu scores.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ...widget.order!.items.map((item) => _buildFoodItemRatingCard(item)),
                const SizedBox(height: 14),
              ] else ...[
                // General Food Quality Rating (1-5 stars)
                _buildStarRatingCard(
                  title: 'Food Taste & Quality',
                  subtitle: 'Freshness, taste, and temperature',
                  icon: Icons.fastfood_rounded,
                  rating: _foodRating,
                  onRatingChanged: (newRating) => setState(() => _foodRating = newRating),
                ),
                const SizedBox(height: 14),
              ],

              // Canteen Service Rating (1-5 stars)
              _buildStarRatingCard(
                title: 'Canteen Service & Speed',
                subtitle: 'Counter speed, token wait time, and hygiene',
                icon: Icons.delivery_dining_rounded,
                rating: _serviceRating,
                onRatingChanged: (newRating) => setState(() => _serviceRating = newRating),
              ),
              const SizedBox(height: 20),

              // Overall Comments & Suggestions Field
              const Text(
                'Overall Review & Suggestions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextFormField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share your dining experience, taste notes, or suggestions...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                  validator: (val) {
                    if (!hasOrderItems && (val == null || val.trim().length < 3)) {
                      return 'Please provide a short comment or review.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Submit Button
              AppButton(
                text: 'Submit Rating & Feedback',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodItemRatingCard(dynamic item) {
    final foodId = item.foodId as String;
    final currentRating = _itemRatings[foodId] ?? 5.0;
    final reviewController = _itemReviewControllers[foodId]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Dish Info Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CachedFoodImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quantity: ${item.quantity}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 4),
                    Text(
                      currentRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive 1-5 Star Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starVal = index + 1.0;
              final isFilled = currentRating >= starVal;
              return IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _itemRatings[foodId] = starVal;
                    // Also mirror to main food rating
                    _foodRating = starVal;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 8),

          // Optional item review field
          TextField(
            controller: reviewController,
            decoration: InputDecoration(
              hintText: 'Optional review for ${item.name} (e.g., taste, spice level)...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              fillColor: AppColors.background,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Token ${widget.order!.tokenNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  widget.order!.items.map((e) => '${e.quantity}x ${e.name}').join(', '),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRatingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required double rating,
    required ValueChanged<double> onRatingChanged,
  }) {
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
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              final isFilled = rating >= starValue;
              return IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                constraints: const BoxConstraints(),
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                  size: 36,
                ),
                onPressed: () => onRatingChanged(starValue),
              );
            }),
          ),
        ],
      ),
    );
  }
}
