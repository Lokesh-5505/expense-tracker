import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/wallet.dart';

class AppConstants {
  // Shared Preferences Keys
  static const String keyTransactions = 'expense_tracker_txns_v1';
  static const String keyCategories = 'expense_tracker_cats_v1';
  static const String keyWallets = 'expense_tracker_wallets_v1';
  static const String keyBudgets = 'expense_tracker_budgets_v1';
  static const String keyGoals = 'expense_tracker_goals_v1';
  static const String keyRecurringRules = 'expense_tracker_rules_v1';
  static const String keySettings = 'expense_tracker_settings_v1';

  // "Other" fallback category ID
  static const String otherCategoryId = 'cat_other';

  // Built-in categories
  static List<Category> get defaultCategories => [
        const Category(
          id: 'cat_food',
          name: 'Food',
          iconCodePoint: 0xe532, // Icons.restaurant
          colorValue: 0xFFFF7043, // Coral Orange
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_transport',
          name: 'Transport',
          iconCodePoint: 0xe1d7, // Icons.directions_car
          colorValue: 0xFF42A5F5, // Blue
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_shopping',
          name: 'Shopping',
          iconCodePoint: 0xe59c, // Icons.shopping_bag
          colorValue: 0xFFAB47BC, // Purple
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_bills',
          name: 'Bills',
          iconCodePoint: 0xf2eb, // Icons.receipt_long
          colorValue: 0xFFEF5350, // Red
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_health',
          name: 'Health',
          iconCodePoint: 0xf1d7, // Icons.medical_services
          colorValue: 0xFF26A69A, // Teal
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_entertainment',
          name: 'Entertainment',
          iconCodePoint: 0xe3e3, // Icons.movie
          colorValue: 0xFFFFA726, // Amber
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_education',
          name: 'Education',
          iconCodePoint: 0xe559, // Icons.school
          colorValue: 0xFF5C6BC0, // Indigo
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_groceries',
          name: 'Groceries',
          iconCodePoint: 0xe3a8, // Icons.local_grocery_store
          colorValue: 0xFF66BB6A, // Green
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_rent',
          name: 'Rent',
          iconCodePoint: 0xe318, // Icons.home
          colorValue: 0xFF8D6E63, // Brown
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_travel',
          name: 'Travel',
          iconCodePoint: 0xe293, // Icons.flight
          colorValue: 0xFF29B6F6, // Light Blue
          isCustom: false,
          isIncome: false,
        ),
        const Category(
          id: 'cat_salary',
          name: 'Salary',
          iconCodePoint: 0xe3f7, // Icons.payments
          colorValue: 0xFF2E7D32, // Forest Green
          isCustom: false,
          isIncome: true,
        ),
        const Category(
          id: 'cat_freelance',
          name: 'Freelance',
          iconCodePoint: 0xe3b7, // Icons.laptop_mac
          colorValue: 0xFF00897B, // Teal dark
          isCustom: false,
          isIncome: true,
        ),
        const Category(
          id: 'cat_gift',
          name: 'Gift',
          iconCodePoint: 0xe13f, // Icons.card_giftcard
          colorValue: 0xFFEC407A, // Pink
          isCustom: false,
          isIncome: true,
        ),
        const Category(
          id: otherCategoryId,
          name: 'Other',
          iconCodePoint: 0xe406, // Icons.more_horiz
          colorValue: 0xFF78909C, // Blue Grey
          isCustom: false,
          isIncome: false,
        ),
      ];

  // Default wallets
  static List<Wallet> get defaultWallets => [
        const Wallet(
          id: 'wallet_cash',
          name: 'Cash',
          type: 'Cash',
          iconCodePoint: 0xe481, // Icons.payments_outlined
          colorValue: 0xFF43A047,
          initialBalance: 0.0,
        ),
        const Wallet(
          id: 'wallet_bank',
          name: 'Bank',
          type: 'Bank',
          iconCodePoint: 0xe040, // Icons.account_balance
          colorValue: 0xFF1E88E5,
          initialBalance: 0.0,
        ),
        const Wallet(
          id: 'wallet_card_upi',
          name: 'UPI / Card',
          type: 'UPI/Card',
          iconCodePoint: 0xe19f, // Icons.credit_card
          colorValue: 0xFF8E24AA,
          initialBalance: 0.0,
        ),
      ];

  // Currencies
  static const List<Map<String, String>> currencies = [
    {'symbol': '₹', 'code': 'INR', 'name': 'Indian Rupee (₹)'},
    {'symbol': '\$', 'code': 'USD', 'name': 'US Dollar (\$)'},
    {'symbol': '€', 'code': 'EUR', 'name': 'Euro (€)'},
    {'symbol': '£', 'code': 'GBP', 'name': 'British Pound (£)'},
    {'symbol': '¥', 'code': 'JPY', 'name': 'Japanese Yen (¥)'},
    {'symbol': 'C\$', 'code': 'CAD', 'name': 'Canadian Dollar (C\$)'},
    {'symbol': 'A\$', 'code': 'AUD', 'name': 'Australian Dollar (A\$)'},
    {'symbol': 'AED', 'code': 'AED', 'name': 'UAE Dirham (AED)'},
  ];

  // Seed Accent Colors
  static const List<Map<String, dynamic>> accentColors = [
    {'name': 'Deep Indigo', 'color': Color(0xFF1A237E)},
    {'name': 'Teal Wave', 'color': Color(0xFF00796B)},
    {'name': 'Emerald Green', 'color': Color(0xFF2E7D32)},
    {'name': 'Sunset Coral', 'color': Color(0xFFD84315)},
    {'name': 'Electric Violet', 'color': Color(0xFF6A1B9A)},
    {'name': 'Ocean Sapphire', 'color': Color(0xFF0277BD)},
    {'name': 'Crimson Rose', 'color': Color(0xFFC2185B)},
    {'name': 'Charcoal Slate', 'color': Color(0xFF37474F)},
  ];

  // Curated Icon Selection for Custom Categories and Goals
  static const List<int> selectableIcons = [
    0xe532, // restaurant
    0xe1d7, // directions_car
    0xe59c, // shopping_bag
    0xf2eb, // receipt_long
    0xf1d7, // medical_services
    0xe3e3, // movie
    0xe559, // school
    0xe3a8, // local_grocery_store
    0xe318, // home
    0xe293, // flight
    0xe3f7, // payments
    0xe3b7, // laptop_mac
    0xe13f, // card_giftcard
    0xe406, // more_horiz
    0xe28d, // fitness_center
    0xe4a1, // pets
    0xe5f8, // sports_esports
    0xe395, // local_cafe
    0xe6f2, // work
    0xe0be, // beach_access
    0xe1d5, // directions_bus
    0xe3ab, // local_gas_station
    0xe113, // build
    0xe19f, // credit_card
    0xe040, // account_balance
    0xe481, // payments_outlined
    0xe57a, // savings
    0xe328, // hotel
    0xe6c4, // phone_android
    0xe6a8, // wifi
    0xe475, // fastfood
    0xe533, // directions_bike
  ];

  // Curated Colors for Category / Goal Picker
  static const List<Color> selectableColors = [
    Color(0xFFEF5350), // Red
    Color(0xFFEC407A), // Pink
    Color(0xFFAB47BC), // Purple
    Color(0xFF7E57C2), // Deep Purple
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF42A5F5), // Blue
    Color(0xFF29B6F6), // Light Blue
    Color(0xFF26C6DA), // Cyan
    Color(0xFF26A69A), // Teal
    Color(0xFF66BB6A), // Green
    Color(0xFF9CCC65), // Light Green
    Color(0xFFFFEE58), // Yellow
    Color(0xFFFFA726), // Orange
    Color(0xFFFF7043), // Deep Orange
    Color(0xFF8D6E63), // Brown
    Color(0xFF78909C), // Blue Grey
  ];
}
