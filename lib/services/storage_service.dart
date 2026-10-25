import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/recurring_rule.dart';
import '../utils/constants.dart';

class StorageService {
  final SharedPreferences _prefs;
  final Map<String, Timer> _debounceTimers = {};

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Transactions ---
  List<Transaction> loadTransactions() {
    final raw = _prefs.getString(AppConstants.keyTransactions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveTransactions(List<Transaction> transactions, {bool immediate = false}) {
    _debounceSave(AppConstants.keyTransactions, () {
      final jsonList = transactions.map((e) => e.toJson()).toList();
      _prefs.setString(AppConstants.keyTransactions, jsonEncode(jsonList));
    }, immediate: immediate);
  }

  // --- Categories ---
  List<Category> loadCategories() {
    final raw = _prefs.getString(AppConstants.keyCategories);
    if (raw == null || raw.isEmpty) {
      return AppConstants.defaultCategories;
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return AppConstants.defaultCategories;
    }
  }

  void saveCategories(List<Category> categories, {bool immediate = false}) {
    _debounceSave(AppConstants.keyCategories, () {
      final jsonList = categories.map((e) => e.toJson()).toList();
      _prefs.setString(AppConstants.keyCategories, jsonEncode(jsonList));
    }, immediate: immediate);
  }

  // --- Wallets ---
  List<Wallet> loadWallets() {
    final raw = _prefs.getString(AppConstants.keyWallets);
    if (raw == null || raw.isEmpty) {
      return AppConstants.defaultWallets;
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Wallet.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return AppConstants.defaultWallets;
    }
  }

  void saveWallets(List<Wallet> wallets, {bool immediate = false}) {
    _debounceSave(AppConstants.keyWallets, () {
      final jsonList = wallets.map((e) => e.toJson()).toList();
      _prefs.setString(AppConstants.keyWallets, jsonEncode(jsonList));
    }, immediate: immediate);
  }

  // --- Budgets ---
  List<Budget> loadBudgets() {
    final raw = _prefs.getString(AppConstants.keyBudgets);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveBudgets(List<Budget> budgets, {bool immediate = false}) {
    _debounceSave(AppConstants.keyBudgets, () {
      final jsonList = budgets.map((e) => e.toJson()).toList();
      _prefs.setString(AppConstants.keyBudgets, jsonEncode(jsonList));
    }, immediate: immediate);
  }

  // --- Goals ---
  List<SavingsGoal> loadGoals() {
    final raw = _prefs.getString(AppConstants.keyGoals);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveGoals(List<SavingsGoal> goals, {bool immediate = false}) {
    _debounceSave(AppConstants.keyGoals, () {
      final jsonList = goals.map((e) => e.toJson()).toList();
      _prefs.setString(AppConstants.keyGoals, jsonEncode(jsonList));
    }, immediate: immediate);
  }

  // --- Recurring Rules ---
  List<RecurringRule> loadRecurringRules() {
    final raw = _prefs.getString(AppConstants.keyRecurringRules);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => RecurringRule.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  void saveRecurringRules(List<RecurringRule> rules, {bool immediate = false}) {
    _debounceSave(AppConstants.keyRecurringRules, () {
      final jsonList = rules.map((e) => e.toJson()).toList();
      _prefs.setString(AppConstants.keyRecurringRules, jsonEncode(jsonList));
    }, immediate: immediate);
  }

  // --- App Settings ---
  Map<String, dynamic> loadSettings() {
    final raw = _prefs.getString(AppConstants.keySettings);
    if (raw == null || raw.isEmpty) {
      return {
        'currencySymbol': '₹',
        'currencyCode': 'INR',
        'themeMode': 'system',
        'accentColorIndex': 0,
        'pin': null,
        'hasOnboarded': false,
      };
    }
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {
        'currencySymbol': '₹',
        'currencyCode': 'INR',
        'themeMode': 'system',
        'accentColorIndex': 0,
        'pin': null,
        'hasOnboarded': false,
      };
    }
  }

  void saveSettings(Map<String, dynamic> settings, {bool immediate = true}) {
    _debounceSave(AppConstants.keySettings, () {
      _prefs.setString(AppConstants.keySettings, jsonEncode(settings));
    }, immediate: immediate);
  }

  // --- Clear All Data ---
  Future<void> clearAll() async {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    await _prefs.clear();
  }

  // --- Debouncer Engine ---
  void _debounceSave(String key, VoidCallback action, {bool immediate = false}) {
    if (immediate) {
      _debounceTimers[key]?.cancel();
      _debounceTimers.remove(key);
      action();
      return;
    }

    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 400), () {
      action();
      _debounceTimers.remove(key);
    });
  }

  void flushAllPending() {
    for (final timer in _debounceTimers.values) {
      if (timer.isActive) {
        // Debounce timer cancelled, changes will be written directly
        timer.cancel();
      }
    }
    _debounceTimers.clear();
  }
}
