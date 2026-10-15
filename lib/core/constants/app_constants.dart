import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Smart Canteen';
  static const String appTagline = 'Fresh & Fast College Dining';
  static const String appVersion = 'v1.0.0';

  // User Roles: User | Kitchen | Admin
  static const String roleUser = 'user';
  static const String roleKitchen = 'staff';
  static const String roleStaff = 'staff';
  static const String roleAdmin = 'admin';
  static const String roleStudent = 'user'; // backward compatibility alias

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionFoods = 'foods';
  static const String collectionOrders = 'orders';
  static const String collectionCategories = 'categories';
  static const String collectionFeedback = 'feedback';
  static const String collectionFoodReviews = 'food_reviews';
  static const String collectionWalletTransactions = 'wallet_transactions';

  // Food Categories (All + 4 Canteen Categories)
  static const List<String> categories = [
    'All',
    'Breakfast',
    'Meals',
    'Snacks',
    'Cool Drinks',
  ];

  // Specific Food Categories (excluding 'All' for dish creation/editing)
  static const List<String> specificCategories = [
    'Breakfast',
    'Meals',
    'Snacks',
    'Cool Drinks',
  ];

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.restaurant_menu_rounded;
      case 'breakfast':
        return Icons.breakfast_dining_rounded;
      case 'meals':
        return Icons.dinner_dining_rounded;
      case 'snacks':
        return Icons.fastfood_rounded;
      case 'cool drinks':
        return Icons.local_drink_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  // Official Canteen Food Items with Accurate Matching High-Res Food Photography
  static const List<Map<String, dynamic>> initialFoodItems = [
    // ----------------- BREAKFAST (11 Items) -----------------
    {
      'foodId': 'bf_01',
      'name': 'Masala Dosa',
      'description':
          'Crispy golden fermented crepe filled with spiced mashed potatoes, served with coconut chutney and piping hot sambar.',
      'price': 90.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 10,
      'isVeg': true,
      'calories': 320,
    },
    {
      'foodId': 'bf_02',
      'name': 'Puttu + Kadala Curry',
      'description':
          'Steamed cylindrical rice cake layered with grated coconut, served with traditional spicy black chickpea curry.',
      'price': 80.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 12,
      'isVeg': true,
      'calories': 340,
    },
    {
      'foodId': 'bf_03',
      'name': 'Appam + Egg Curry',
      'description':
          'Soft, pillowy fermented rice pancake with a crispy lace edge, served with rich coconut milk egg gravy.',
      'price': 70.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 12,
      'isVeg': false,
      'calories': 380,
    },
    {
      'foodId': 'bf_04',
      'name': 'Idli + Sambar (4 pcs)',
      'description':
          'Steamed fluffy rice and lentil cakes served with homestyle vegetable sambar and freshly ground coconut chutney.',
      'price': 60.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.7,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 240,
    },
    {
      'foodId': 'bf_05',
      'name': 'Ghee Roast Dosa',
      'description':
          'Ultra-thin and extra crispy dosa roasted generously with pure desi ghee, accompanied by fresh chutneys and sambar.',
      'price': 85.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1630383249896-424e482df921?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 8,
      'isVeg': true,
      'calories': 310,
    },
    {
      'foodId': 'bf_06',
      'name': 'Egg Omelette (Double Egg)',
      'description':
          'Double egg fluffy omelette spiced with chopped green chillies, onions, curry leaves, and black pepper.',
      'price': 30.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.6,
      'preparationTime': 6,
      'isVeg': false,
      'calories': 190,
    },
    {
      'foodId': 'bf_07',
      'name': 'Bread Omelette Special',
      'description':
          'Toasted buttered bread slices encased inside a spicy herb-infused masala omelette, cut and served hot.',
      'price': 45.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 7,
      'isVeg': false,
      'calories': 280,
    },
    {
      'foodId': 'bf_08',
      'name': 'Idiyappam + Veg Kurma',
      'description':
          'Delicate steamed string hoppers served alongside a fragrant, mildly spiced mixed vegetable kurma.',
      'price': 50.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.7,
      'preparationTime': 8,
      'isVeg': true,
      'calories': 220,
    },
    {
      'foodId': 'bf_09',
      'name': 'Porotta + Chicken Curry',
      'description':
          'Layered, flaky Kerala Malabar porotta served with spicy, slow-cooked chicken roast curry.',
      'price': 70.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1606471191009-63994c53433b?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 12,
      'isVeg': false,
      'calories': 520,
    },
    {
      'foodId': 'bf_10',
      'name': 'Chapathi + Chicken Curry',
      'description':
          'Two whole wheat soft chapathis accompanied by aromatic chicken gravy cooked in roasted whole spices.',
      'price': 70.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 10,
      'isVeg': false,
      'calories': 460,
    },
    {
      'foodId': 'bf_11',
      'name': 'Poori Masala (3 pcs)',
      'description':
          'Golden deep-fried puffed wheat breads served with delicious spiced potato and onion bhaji.',
      'price': 65.0,
      'category': 'Breakfast',
      'imageUrl':
          'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 8,
      'isVeg': true,
      'calories': 390,
    },

    // ----------------- MEALS (8 Items) -----------------
    {
      'foodId': 'ml_01',
      'name': 'Chicken Biriyani',
      'description':
          'Fragrant Jeerakasala/Basmati rice cooked dum style with succulent chicken pieces, caramelized onions, boiled egg, and raita.',
      'price': 110.0,
      'category': 'Meals',
      'imageUrl':
          'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 15,
      'isVeg': false,
      'calories': 650,
    },
    {
      'foodId': 'ml_02',
      'name': 'Egg Biriyani',
      'description':
          'Flavorful spiced aromatic biriyani rice served with two roasted eggs, fresh pickle, and refreshing onion raita.',
      'price': 90.0,
      'category': 'Meals',
      'imageUrl':
          'https://images.unsplash.com/photo-1589302168068-964664d93dc0?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.7,
      'preparationTime': 12,
      'isVeg': false,
      'calories': 540,
    },
    {
      'foodId': 'ml_03',
      'name': 'Kappa Biriyani',
      'description':
          'Classic Kerala specialty with mashed boiled tapioca cooked in a flavorful beef/chicken masala and roasted coconut.',
      'price': 80.0,
      'category': 'Meals',
      'imageUrl':
          'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 15,
      'isVeg': false,
      'calories': 580,
    },
    {
      'foodId': 'ml_04',
      'name': 'Chicken Fried Rice',
      'description':
          'Wok-tossed long-grain rice with diced chicken, scrambled eggs, crisp spring onions, and oriental sauces.',
      'price': 120.0,
      'category': 'Meals',
      'imageUrl':
          'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 12,
      'isVeg': false,
      'calories': 610,
    },
    {
      'foodId': 'ml_05',
      'name': 'Veg Fried Rice + Manchurian',
      'description':
          'Stir-fried vegetables and seasoned rice paired with crispy fried vegetable dumplings in savory soya garlic gravy.',
      'price': 85.0,
      'category': 'Meals',
      'imageUrl':
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.7,
      'preparationTime': 10,
      'isVeg': true,
      'calories': 480,
    },
    {
      'foodId': 'ml_06',
      'name': 'South Indian Meals (Thali)',
      'description':
          'Steamed rice served with Sambar, Rasam, Moru curry, Thoran, Kootu, Pickle, Pappadam, and Payasam.',
      'price': 75.0,
      'category': 'Meals',
      'imageUrl':
          'https://images.unsplash.com/photo-1610192244261-3f33de3f55e4?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 520,
    },
    {
      'foodId': 'ml_07',
      'name': 'Chicken Hakka Noodles',
      'description':
          'Chinese-style noodles tossed with seasoned chicken shreds, crunchy capsicum, cabbage, and hot garlic sauce.',
      'price': 110.0,
      'category': 'Meals',
      'imageUrl':
          'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 12,
      'isVeg': false,
      'calories': 590,
    },
    {
      'foodId': 'ml_08',
      'name': 'Paneer Butter Masala Combo',
      'description':
          'Rich and creamy tomato-butter paneer curry served with 2 warm butter rotis and salad.',
      'price': 95.0,
      'category': 'Meals',
      'imageUrl':
          'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 10,
      'isVeg': true,
      'calories': 560,
    },

    // ----------------- SNACKS (9 Items) -----------------
    {
      'foodId': 'sn_01',
      'name': 'Crispy Samosa (2 pcs)',
      'description':
          'Golden-fried crispy pastry cones stuffed with a spicy potato and green pea filling, served with mint dip.',
      'price': 15.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 210,
    },
    {
      'foodId': 'sn_02',
      'name': 'Egg Puffs',
      'description':
          'Flaky oven-baked puff pastry stuffed with hard-boiled seasoned egg and sautéed spiced onion masala.',
      'price': 25.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.7,
      'preparationTime': 5,
      'isVeg': false,
      'calories': 280,
    },
    {
      'foodId': 'sn_03',
      'name': 'Chicken Puffs',
      'description':
          'Crispy golden layered puff filled with minced chicken, black pepper, and herbs.',
      'price': 35.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 5,
      'isVeg': false,
      'calories': 320,
    },
    {
      'foodId': 'sn_04',
      'name': 'Pazham Pori (Banana Fritters)',
      'description':
          'Sweet ripe Nendran bananas dipped in golden batter and deep-fried till crispy on the outside and tender inside.',
      'price': 15.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1599488615731-7e5c2823ff28?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 6,
      'isVeg': true,
      'calories': 230,
    },
    {
      'foodId': 'sn_05',
      'name': 'Uzhunnu Vada (Medhu Vada)',
      'description':
          'Crispy golden donut-shaped lentil fritters made with black gram, ginger, curry leaves, and green chillies.',
      'price': 15.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 180,
    },
    {
      'foodId': 'sn_06',
      'name': 'Potato Bonda (2 pcs)',
      'description':
          'Spiced mashed potato balls dipped in chickpea flour batter and fried until delightfully crunchy.',
      'price': 15.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1541544741938-0af808871cc0?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.6,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 200,
    },
    {
      'foodId': 'sn_07',
      'name': 'Onion Bajji (3 pcs)',
      'description':
          'Sliced red onions coated with spicy carom-seeded besan batter and fried golden crisp.',
      'price': 15.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1606491956689-2ea866880c84?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.7,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 190,
    },
    {
      'foodId': 'sn_08',
      'name': 'Crispy French Fries',
      'description':
          'Golden crispy salted potato fries sprinkled with signature peri-peri seasoning and tomato ketchup.',
      'price': 50.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 8,
      'isVeg': true,
      'calories': 310,
    },
    {
      'foodId': 'sn_09',
      'name': 'Chicken Cutlet (2 pcs)',
      'description':
          'Crumb-fried minced chicken patties blended with mashed potatoes, black pepper, and herbs.',
      'price': 30.0,
      'category': 'Snacks',
      'imageUrl':
          'https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 5,
      'isVeg': false,
      'calories': 240,
    },

    // ----------------- COOL DRINKS & BEVERAGES (10 Items) -----------------
    {
      'foodId': 'cd_01',
      'name': 'Fresh Lime Juice',
      'description':
          'Refreshing freshly squeezed lemon juice with chilled water, a hint of mint, and sugar.',
      'price': 25.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 4,
      'isVeg': true,
      'calories': 80,
    },
    {
      'foodId': 'cd_02',
      'name': 'Fresh Lime Soda (Sweet & Salt)',
      'description':
          'Fizzy chilled soda blended with fresh lime juice, rock salt, and sugar syrup for instant refreshment.',
      'price': 25.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 4,
      'isVeg': true,
      'calories': 90,
    },
    {
      'foodId': 'cd_03',
      'name': 'Mango Shake Special',
      'description':
          'Thick and luscious mango shake prepared with sweet ripe Alphonso mangoes and chilled dairy milk.',
      'price': 60.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1546173159-315724a31696?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 160,
    },
    {
      'foodId': 'cd_04',
      'name': 'Cold Coffee with Ice Cream',
      'description':
          'Chilled brewed espresso blended with rich milk, topped with a scoop of vanilla ice cream and chocolate drizzle.',
      'price': 55.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 210,
    },
    {
      'foodId': 'cd_05',
      'name': 'Oreo Chocolate Shake',
      'description':
          'Creamy milkshake blended with crushed Oreo cookies, rich chocolate syrup, and cream topping.',
      'price': 65.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 280,
    },
    {
      'foodId': 'cd_06',
      'name': 'Fresh Orange Juice',
      'description':
          'Pure freshly pressed citrus Valencia oranges packed with Vitamin C and natural sweetness.',
      'price': 60.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1613478223719-2ab802602423?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 120,
    },
    {
      'foodId': 'cd_07',
      'name': 'Chilled Watermelon Juice',
      'description':
          '100% natural, freshly blended crisp watermelon juice served cold with crushed ice and mint.',
      'price': 60.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1589733955941-5eeaf752f6dd?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 5,
      'isVeg': true,
      'calories': 110,
    },
    {
      'foodId': 'cd_08',
      'name': 'Virgin Mint Mojito',
      'description':
          'Sparkling club soda infused with muddled fresh garden mint leaves, lime wedges, and cane syrup.',
      'price': 45.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.8,
      'preparationTime': 4,
      'isVeg': true,
      'calories': 95,
    },
    {
      'foodId': 'cd_09',
      'name': 'Special Masala Chai',
      'description':
          'Freshly brewed hot milk tea infused with cardamom, crushed ginger, cloves, and cinnamon.',
      'price': 15.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 3,
      'isVeg': true,
      'calories': 70,
    },
    {
      'foodId': 'cd_10',
      'name': 'South Indian Filter Coffee',
      'description':
          'Traditional hot froth filter coffee prepared with chicory blend decoction and boiling hot milk.',
      'price': 20.0,
      'category': 'Cool Drinks',
      'imageUrl':
          'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80',
      'available': true,
      'rating': 4.9,
      'preparationTime': 3,
      'isVeg': true,
      'calories': 85,
    },
  ];
}
