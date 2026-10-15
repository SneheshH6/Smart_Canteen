import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/food_model.dart';
import '../services/firestore_service.dart';

enum FoodSortOption {
  none,
  mostRated,
  priceLowToHigh,
  priceHighToLow,
}

class FoodProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<FoodModel> _allFoods = AppConstants.initialFoodItems
      .map((item) => FoodModel.fromMap(item))
      .toList();
  List<FoodModel> _popularFoods = AppConstants.initialFoodItems
      .map((item) => FoodModel.fromMap(item))
      .where((f) => f.rating >= 4.7)
      .take(5)
      .toList();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  FoodSortOption _sortOption = FoodSortOption.none;
  bool _showAvailableOnly = false;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _foodsSubscription;
  StreamSubscription? _popularSubscription;

  List<FoodModel> get allFoods => _allFoods;
  List<FoodModel> get popularFoods => _popularFoods;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  FoodSortOption get sortOption => _sortOption;
  bool get showAvailableOnly => _showAvailableOnly;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<FoodModel> get filteredFoods {
    final result = _allFoods.where((food) {
      if (_showAvailableOnly && !food.available) return false;
      
      // When searching, search across all dishes or active category
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final match = food.name.toLowerCase().contains(query) ||
            food.description.toLowerCase().contains(query) ||
            food.category.toLowerCase().contains(query);
        if (!match) return false;
      } else {
        // Category filtering (when not searching)
        if (_selectedCategory.isNotEmpty &&
            _selectedCategory.toLowerCase() != 'all' &&
            food.category.toLowerCase() != _selectedCategory.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();

    // Apply Sorting: Most Rated or Price-wise
    switch (_sortOption) {
      case FoodSortOption.mostRated:
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case FoodSortOption.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case FoodSortOption.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case FoodSortOption.none:
        break;
    }

    return result;
  }

  FoodProvider() {
    _initStreams();
  }

  void _initStreams() {
    _foodsSubscription?.cancel();
    _popularSubscription?.cancel();

    _foodsSubscription = _firestoreService
        .getFoodItemsStream()
        .listen(
          (foods) {
            _allFoods = foods;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = error.toString();
            notifyListeners();
          },
        );

    _popularSubscription = _firestoreService
        .getPopularFoodItemsStream()
        .listen(
          (popular) {
            _popularFoods = popular;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Popular foods stream error: $error');
          },
        );
  }

  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void setSortOption(FoodSortOption option) {
    if (_sortOption == option) {
      // Toggle off if already selected
      _sortOption = FoodSortOption.none;
    } else {
      _sortOption = option;
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleAvailableOnly() {
    _showAvailableOnly = !_showAvailableOnly;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _sortOption = FoodSortOption.none;
    _showAvailableOnly = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _initStreams();
  }

  @override
  void dispose() {
    _foodsSubscription?.cancel();
    _popularSubscription?.cancel();
    super.dispose();
  }
}
