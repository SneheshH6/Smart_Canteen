import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/food_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItemModel> _items = {};

  Map<String, CartItemModel> get items => {..._items};

  List<CartItemModel> get itemsList => _items.values.toList();

  int get totalCount {
    var count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

  double get subtotal {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  double get canteenConvenienceFee => _items.isEmpty ? 0.0 : 5.0; // ₹5 platform / packaging fee

  double get grandTotal => subtotal + canteenConvenienceFee;

  bool isInCart(String foodId) {
    return _items.containsKey(foodId);
  }

  int getItemQuantity(String foodId) {
    return _items[foodId]?.quantity ?? 0;
  }

  void addItem(FoodModel food, {int quantity = 1, String? specialInstructions}) {
    if (!food.available) return;

    if (_items.containsKey(food.foodId)) {
      _items.update(
        food.foodId,
        (existing) => CartItemModel(
          food: existing.food,
          quantity: existing.quantity + quantity,
          specialInstructions: specialInstructions ?? existing.specialInstructions,
        ),
      );
    } else {
      _items.putIfAbsent(
        food.foodId,
        () => CartItemModel(
          food: food,
          quantity: quantity,
          specialInstructions: specialInstructions,
        ),
      );
    }
    notifyListeners();
  }

  void updateQuantity(String foodId, int newQuantity) {
    if (!_items.containsKey(foodId)) return;

    if (newQuantity <= 0) {
      _items.remove(foodId);
    } else {
      _items.update(
        foodId,
        (existing) => CartItemModel(
          food: existing.food,
          quantity: newQuantity,
          specialInstructions: existing.specialInstructions,
        ),
      );
    }
    notifyListeners();
  }

  void incrementQuantity(String foodId) {
    if (_items.containsKey(foodId)) {
      updateQuantity(foodId, _items[foodId]!.quantity + 1);
    }
  }

  void decrementQuantity(String foodId) {
    if (_items.containsKey(foodId)) {
      final current = _items[foodId]!.quantity;
      if (current <= 1) {
        removeItem(foodId);
      } else {
        updateQuantity(foodId, current - 1);
      }
    }
  }

  void removeItem(String foodId) {
    _items.remove(foodId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
