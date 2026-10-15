import 'food_model.dart';

class CartItemModel {
  final FoodModel food;
  int quantity;
  String? specialInstructions;

  CartItemModel({
    required this.food,
    this.quantity = 1,
    this.specialInstructions,
  });

  double get totalPrice => food.price * quantity;

  CartItemModel copyWith({
    FoodModel? food,
    int? quantity,
    String? specialInstructions,
  }) {
    return CartItemModel(
      food: food ?? this.food,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}
