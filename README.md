# 🍽️ Smart Canteen Ordering App

A modern, full-featured **Smart Canteen Food Ordering & Kitchen Management System** built with **Flutter**, **Dart (Material 3)**, and **Firebase Cloud Firestore**.

Designed specifically for college campuses to eliminate long lunch-hour queues, streamline kitchen preparation, and provide real-time token-based pickup tracking for students, staff chefs, and canteen administrators.

---

## 📱 Application Modules & Features

```
                         ┌─────────────────────────────┐
                         │   Smart Canteen Platform    │
                         └──────────────┬──────────────┘
                                        │
         ┌──────────────────────────────┼──────────────────────────────┐
         │                              │                              │
         ▼                              ▼                              ▼
┌───────────────────┐        ┌───────────────────┐          ┌─────────────────────┐
│  Student Module   │        │   Kitchen Staff   │          │    Admin Console    │
├───────────────────┤        ├───────────────────┤          ├─────────────────────┤
│ • Browse & Search │        │ • Live Order Queue│          │ • Revenue Analytics │
│ • Category Filter │        │ • 1-Tap Statuses  │          │ • Food Menu CRUD    │
│ • Tray & Cart     │        │ • Token Callout   │          │ • User Roles (All)  │
│ • Safe Checkout   │        │ • Item Checklist  │          │ • All Transactions │
│ • Sandbox Payment │        │ • Instant Out-of- │          │ • Feedback Reviewer │
│ • Live 4-Stage    │        │   Stock Switcher  │          │ • Popular Items Top │
│   Tracking Sync   │        └───────────────────┘          └─────────────────────┘
│ • Ratings & Review│
└───────────────────┘
```

### 1. 🎓 Student Ordering Module
- **Menu Exploration**: High-resolution food images, search bar, and category filters (*Breakfast, South Indian, Meals, Snacks, Chinese, Beverages, Desserts*).
- **Veg / Non-Veg Badges**: Standard FSSAI-style green/red dot indicators.
- **Interactive Tray & Cart**: Real-time subtotal calculation, quantity stepper, packaging fee, and session persistence.
- **Secure Checkout & Sandbox Payment**:
  - Payment options: **UPI** (Google Pay, PhonePe, Paytm, BHIM), **Student Meal Pass / ID Wallet**, **Counter Cash**, and **Sandbox Card**.
  - Animated processing states, success receipts with Transaction IDs, and failure recovery toggles.
- **Real-Time Order Tracking**:
  - Live 4-stage stepper timeline:
    $$\text{Order Placed (Pending)} \longrightarrow \text{Kitchen Cooking (Preparing)} \longrightarrow \text{Ready at Counter (Ready)} \longrightarrow \text{Picked Up (Completed)}$$
  - Large **Token Number** badge (e.g., `#104`) for counter pickup.
- **Order History & Feedback**:
  - Tabbed active tokens vs. past fulfilled orders.
  - 5-Star rating system for food quality and canteen speed with comments.

### 2. 👨‍🍳 Kitchen Staff Terminal
- **Live Orders Stream**: Automatically receives new student orders via Cloud Firestore snapshots.
- **Live Status Statistics Bar**: Counter for *Pending, Cooking, Ready, and Done*.
- **One-Tap Status Actions**:
  - `Pending` $\rightarrow$ `[🔥 Start Cooking]`
  - `Preparing` $\rightarrow$ `[🔔 Mark as Ready for Pickup]`
  - `Ready` $\rightarrow$ `[✅ Hand Over & Complete]`
- **Chef Checklist**: Itemized portion counts (e.g., `2x Masala Dosa`) and student cooking requests/notes.
- **Instant Out-of-Stock Switcher**: Kitchen chefs can toggle any dish between *Available* and *Sold Out* in 1 tap.

### 3. 👔 Admin & Canteen Management Console
- **Executive Dashboard**: Lifetime revenue, total orders, in-stock vs. out-of-stock dish count, and active orders.
- **Menu Management (Full CRUD)**:
  - Add new dishes with price, prep time, category, image URL, and veg/non-veg flag.
  - Edit pricing, description, and details.
  - Delete dishes with confirmation dialogs.
- **User & Role Management**: Search all registered users and promote accounts between `student`, `staff`, and `admin`.
- **Order Management & Audit Log**: Search orders by token, order ID, or customer name with status filters.
- **Reports & Analytics**: Status distribution progress bars and ranked popular foods leaderboard with sales revenue.
- **Student Reviews & Complaints**: Filter feedback by type (*Feedback, Complaint, Suggestion*) and view average star ratings.

---

## 🛠️ Technology Stack

| Component | Technology | Description |
|---|---|---|
| **Frontend** | Flutter 3.x (Dart 3.x) | Cross-platform mobile & desktop UI |
| **Design System** | Material 3 & Google Fonts | Poppins typography, Emerald Green (`#059669`), Orange (`#F97316`) |
| **State Management** | Provider | Maintainable, reactive state architecture |
| **Authentication** | Firebase Auth | Email/Password with full error handling and fallback |
| **Database** | Cloud Firestore | Real-time streams and persistent collections |
| **Payment** | PaymentService Abstraction | Safe sandbox simulation without storing card/CVV data |

---

## 🔑 Pre-Configured Demo Accounts (1-Tap Login)

The login screen includes **1-Tap Demo Fill Buttons** to quickly evaluate all 3 user roles:

| Role | Email | Password | Direct Destination |
|---|---|---|---|
| **Student** | `student@canteen.com` | `password123` | Student Home & Menu Screen |
| **Kitchen Staff** | `staff@canteen.com` | `password123` | Kitchen Live Order Terminal |
| **Admin** | `admin@canteen.com` | `password123` | Canteen Admin Console |

> **Role Switcher in Profile**: Students can also switch between the Student, Kitchen, and Admin interfaces directly from the Profile screen in demo mode.

---

## 🗄️ Firestore Database Schema

### 1. `users` Collection
```json
{
  "userId": "string (UID)",
  "name": "Alex Sharma",
  "email": "student@canteen.com",
  "phone": "9876543210",
  "role": "student | staff | admin",
  "createdAt": "Timestamp"
}
```

### 2. `foods` Collection
```json
{
  "foodId": "food_01",
  "name": "Masala Dosa",
  "description": "Crispy golden crepe with spiced potato filling...",
  "price": 60.0,
  "category": "South Indian",
  "imageUrl": "https://images.unsplash.com/...",
  "available": true,
  "isVeg": true,
  "prepTimeMinutes": 10,
  "rating": 4.8,
  "ratingCount": 42,
  "createdAt": "Timestamp"
}
```

### 3. `orders` Collection
```json
{
  "orderId": "ORD-910482",
  "tokenNumber": "#104",
  "userId": "student_demo_01",
  "userName": "Alex Sharma",
  "items": [
    {
      "foodId": "food_01",
      "name": "Masala Dosa",
      "price": 60.0,
      "quantity": 2,
      "imageUrl": "https://..."
    }
  ],
  "totalAmount": 125.0,
  "paymentMethod": "UPI",
  "paymentStatus": "Paid",
  "orderStatus": "Pending | Preparing | Ready | Completed | Cancelled",
  "pickupNotes": "Less spicy please",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

### 4. `feedback` Collection
```json
{
  "feedbackId": "fb_01",
  "userId": "student_demo_01",
  "userName": "Alex Sharma",
  "orderId": "ORD-910482",
  "foodRating": 5.0,
  "serviceRating": 4.5,
  "type": "Feedback | Complaint | Suggestion",
  "comment": "Super fast delivery and delicious dosa!",
  "createdAt": "Timestamp"
}
```

---

## 🚀 How to Run the Project

### Prerequisites
- Flutter SDK $\ge$ 3.19.0
- Dart SDK $\ge$ 3.3.0
- Android Studio / Android Emulator / Chrome browser

### 1. Get Dependencies
```bash
flutter pub get
```

### 2. Run Quality Checks & Unit Tests
```bash
flutter analyze
flutter test
```

### 3. Run on Target Device
```bash
# Run on Android Emulator:
flutter run

# Run on Chrome (Web Preview):
flutter run -d chrome

# Run on Windows Desktop:
flutter run -d windows
```

### 4. Build Android Debug APK
```bash
flutter build apk --debug
```
The generated APK will be available at:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 🔒 Firebase Configuration (Optional)

The application is built with a **Firebase-ready Architecture** and includes an automatic **In-Memory Mock Fallback Engine**. It runs out-of-the-box without requiring an active Firebase project for offline project demonstrations.

To link your live Cloud Firebase project:
1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (Email/Password provider).
3. Enable **Cloud Firestore Database** in test/production mode.
4. Add an Android app with package name `com.example.smart_canteen`.
5. Download `google-services.json` and place it in `android/app/google-services.json`.

---

## 📁 Clean Architecture Structure

```
lib/
├── main.dart                          # App entry point & MultiProvider setup
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Emerald primary, Orange accent, Status colors
│   │   └── app_constants.dart         # Category lists, roles, collections
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 light theme & typography
│   └── utils/
│       ├── currency_formatter.dart    # Indian Rupee (₹) formatting
│       ├── snackbar_utils.dart        # Unified success/error/info alerts
│       └── validators.dart            # Email, phone, and password validators
├── models/
│   ├── user_model.dart                # User schema & role helpers
│   ├── food_model.dart                # Dish catalog model with veg/rating tags
│   ├── cart_item_model.dart           # Cart item with subtotal calculation
│   ├── order_item_model.dart          # Order line item serialization
│   ├── order_model.dart               # Order schema with 4-stage tracking index
│   └── feedback_model.dart            # Multi-criterion feedback & rating model
├── services/
│   ├── firebase_service.dart          # Safe initialization & readiness detector
│   ├── auth_service.dart              # Firebase Auth & Mock fallback accounts
│   ├── firestore_service.dart         # Full Firestore CRUD & live reactive streams
│   └── payment_service.dart           # Safe sandbox payment gateway abstraction
├── providers/
│   ├── auth_provider.dart             # Authentication & user profile state
│   ├── food_provider.dart             # Menu categories, search & filters
│   ├── cart_provider.dart             # Tray management, item count & totals
│   └── order_provider.dart            # Order creation, tokens & live tracking
├── screens/
│   ├── splash_screen.dart             # Animated splash with role-based routing
│   ├── auth/
│   │   ├── login_screen.dart          # Multi-role demo login chips
│   │   └── register_screen.dart       # Student registration & Firestore setup
│   ├── payment/
│   │   └── payment_screen.dart        # Sandbox gateway, success & failure flows
│   ├── kitchen/
│   │   ├── kitchen_dashboard_screen.dart     # Real-time cooking queue & stats
│   │   ├── kitchen_order_detail_screen.dart  # Chef checklist & status advancement
│   │   └── kitchen_menu_toggle_sheet.dart    # Instant food stock availability toggle
│   ├── admin/
│   │   ├── admin_dashboard_screen.dart       # Canteen admin metrics & modules
│   │   ├── admin_menu_management_screen.dart # Food catalog CRUD & search
│   │   ├── add_edit_food_screen.dart         # Add / edit food dish form
│   │   ├── admin_user_management_screen.dart # User directory & role promotion
│   │   ├── admin_order_management_screen.dart# Transaction audit & status filters
│   │   ├── admin_reports_screen.dart         # Revenue & popularity analytics
│   │   └── admin_feedback_screen.dart        # Student reviews & complaints
│   └── student/
│       ├── student_main_screen.dart          # Navigation bar (Home, Menu, Tray, Profile)
│       ├── home_screen.dart                  # Categories, popular & available dishes
│       ├── menu_screen.dart                  # Full food catalog with search
│       ├── food_details_screen.dart          # Hero animation, prep time, quantity
│       ├── cart_screen.dart                  # Itemized breakdown & checkout
│       ├── checkout_screen.dart              # Order summary & cooking notes
│       ├── order_success_screen.dart         # Token celebration & confirmation
│       ├── order_tracking_screen.dart        # 4-stage live stepper & token hero
│       ├── order_history_screen.dart         # Active vs past orders & review trigger
│       ├── profile_screen.dart               # Student info & demo role switcher
│       └── submit_feedback_screen.dart       # 5-star rating & review submission
└── widgets/
    ├── app_button.dart                # Styled button with loading indicator
    ├── app_text_field.dart            # Custom input with prefix/suffix icons
    ├── cached_food_image.dart         # Network image cache with error fallback
    ├── food_card.dart                 # Responsive dish card with Hero tag
    ├── loading_widget.dart            # Shimmer loading container
    └── empty_state.dart               # Custom empty state placeholder
```

---

## 🎓 Academic Project Details
- **Project Title**: Smart Canteen Ordering App
- **Degree**: Master of Computer Applications (MCA)
- **Primary Objective**: Queue reduction, automated token assignment, real-time kitchen tracking, and centralized canteen inventory control.
