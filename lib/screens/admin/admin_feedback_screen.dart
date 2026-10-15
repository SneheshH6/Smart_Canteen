import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedType = 'All';

  final List<String> _typeFilters = [
    'All',
    FeedbackTypeConstants.feedback,
    FeedbackTypeConstants.complaint,
    FeedbackTypeConstants.suggestion,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Reviews & Feedback'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: _firestoreService.getFeedbackStream(
          typeFilter: _selectedType == 'All' ? null : _selectedType,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final feedbacks = snapshot.data ?? [];

          // Compute average ratings
          double avgFoodRating = 0.0;
          double avgServiceRating = 0.0;
          if (feedbacks.isNotEmpty) {
            avgFoodRating = feedbacks.fold<double>(0.0, (sum, f) => sum + f.foodRating) /
                feedbacks.length;
            avgServiceRating =
                feedbacks.fold<double>(0.0, (sum, f) => sum + f.serviceRating) /
                    feedbacks.length;
          }

          return Column(
            children: [
              // Rating Overview Header
              _buildRatingOverviewHeader(avgFoodRating, avgServiceRating, feedbacks.length),

              // Filter Chips
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _typeFilters.map((type) {
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedType = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Feedback List
              Expanded(
                child: feedbacks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.rate_review_outlined,
                                size: 48, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('No feedback submitted in this category.',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: feedbacks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildFeedbackCard(feedbacks[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingOverviewHeader(double avgFood, double avgService, int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildRatingSummaryBox(
              'Food Quality',
              avgFood,
              Icons.fastfood_rounded,
              const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildRatingSummaryBox(
              'Service & Hygiene',
              avgService,
              Icons.delivery_dining_rounded,
              AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryBox(String label, double rating, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.star_rounded, size: 16, color: color),
                ],
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(FeedbackModel fb) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(fb.createdAt);

    Color typeColor;
    Color typeBg;
    switch (fb.type) {
      case FeedbackTypeConstants.complaint:
        typeColor = AppColors.error;
        typeBg = Colors.red.shade50;
        break;
      case FeedbackTypeConstants.suggestion:
        typeColor = Colors.blueAccent;
        typeBg = Colors.blue.shade50;
        break;
      default:
        typeColor = AppColors.primary;
        typeBg = AppColors.primarySoft;
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      fb.userName.isNotEmpty ? fb.userName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fb.userName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  fb.type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniScore('Food', fb.foodRating),
              const SizedBox(width: 14),
              _buildMiniScore('Service', fb.serviceRating),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${fb.comment}"',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String title, double score) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
