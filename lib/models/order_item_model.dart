class OrderItemModel {
  final String foodId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;
  final String? specialInstructions;

  const OrderItemModel({
    required this.foodId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.specialInstructions,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'specialInstructions': specialInstructions,
      'subtotal': subtotal,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    int parseInt(dynamic value, int defaultValue) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return OrderItemModel(
      foodId: (map['foodId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      price: parseDouble(map['price'], 0.0),
      quantity: parseInt(map['quantity'], 1),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      specialInstructions: map['specialInstructions']?.toString(),
    );
  }

  OrderItemModel copyWith({
    String? foodId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    String? specialInstructions,
  }) {
    return OrderItemModel(
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}
