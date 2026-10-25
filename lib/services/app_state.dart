import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/recurring_rule.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'insights_service.dart';

enum TransactionSortOrder {
  newest,
  oldest,
  highestAmount,
  lowestAmount,
}

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService _storageService;
  final Uuid _uuid = const Uuid();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Data Collections
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Wallet> _wallets = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _goals = [];
  List<RecurringRule> _recurringRules = [];

  // Settings
  String _currencySymbol = '₹';
  String _currencyCode = 'INR';
  ThemeMode _themeMode = ThemeMode.system;
  int _accentColorIndex = 0;
  String? _pin;
  bool _hasOnboarded = false;
  bool _isLocked = false;

  // Transaction Filters & Search
  String _searchQuery = '';
  TransactionType? _filterType;
  final Set<String> _filterCategoryIds = {};
  String? _filterWalletId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  double? _filterMinAmount;
  double? _filterMaxAmount;
  TransactionSortOrder _sortOrder = TransactionSortOrder.newest;

  // Month selector for dashboard (defaults to current month)
  DateTime _selectedDashboardMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  // Undo support
  Transaction? _lastDeletedTransaction;

  AppState(this._storageService) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- Getters ---
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Wallet> get wallets => List.unmodifiable(_wallets);
  List<Budget> get budgets => List.unmodifiable(_budgets);
  List<SavingsGoal> get goals => List.unmodifiable(_goals);
  List<RecurringRule> get recurringRules => List.unmodifiable(_recurringRules);

  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;
  ThemeMode get themeMode => _themeMode;
  int get accentColorIndex => _accentColorIndex;
  Color get accentSeedColor =>
      (AppConstants.accentColors[_accentColorIndex.clamp(0, AppConstants.accentColors.length - 1)]['color'] as Color);
  String? get pin => _pin;
  bool get hasPin => _pin != null && _pin!.isNotEmpty;
  bool get hasOnboarded => _hasOnboarded;
  bool get isLocked => _isLocked;

  DateTime get selectedDashboardMonth => _selectedDashboardMonth;
  Transaction? get lastDeletedTransaction => _lastDeletedTransaction;

  // Filter Getters
  String get searchQuery => _searchQuery;
  TransactionType? get filterType => _filterType;
  Set<String> get filterCategoryIds => Set.unmodifiable(_filterCategoryIds);
  String? get filterWalletId => _filterWalletId;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  double? get filterMinAmount => _filterMinAmount;
  double? get filterMaxAmount => _filterMaxAmount;
  TransactionSortOrder get sortOrder => _sortOrder;

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _filterType != null ||
      _filterCategoryIds.isNotEmpty ||
      _filterWalletId != null ||
      _filterStartDate != null ||
      _filterEndDate != null ||
      _filterMinAmount != null ||
      _filterMaxAmount != null;

  // --- Initialization ---
  Future<void> initialize() async {
    _transactions = _storageService.loadTransactions();
    _categories = _storageService.loadCategories();
    _wallets = _storageService.loadWallets();
    _budgets = _storageService.loadBudgets();
    _goals = _storageService.loadGoals();
    _recurringRules = _storageService.loadRecurringRules();

    final settings = _storageService.loadSettings();
    _currencySymbol = settings['currencySymbol'] as String? ?? '₹';
    _currencyCode = settings['currencyCode'] as String? ?? 'INR';
    final themeStr = settings['themeMode'] as String? ?? 'system';
    _themeMode = themeStr == 'dark'
        ? ThemeMode.dark
        : themeStr == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
    _accentColorIndex = (settings['accentColorIndex'] as num?)?.toInt() ?? 0;
    _pin = settings['pin'] as String?;
    _hasOnboarded = settings['hasOnboarded'] as bool? ?? false;

    // Lock if PIN is set
    if (hasPin) {
      _isLocked = true;
    }

    // Auto-generate due recurring transactions
    processRecurringRules();

    _isInitialized = true;
    notifyListeners();
  }

  // --- Lifecycle Hook for PIN Lock & Recurring on Resume ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (hasPin) {
        _isLocked = true;
      }
      processRecurringRules();
      notifyListeners();
    }
  }

  // --- Lock / Unlock ---
  void unlockApp() {
    _isLocked = false;
    notifyListeners();
  }

  void lockApp() {
    if (hasPin) {
      _isLocked = true;
      notifyListeners();
    }
  }

  // --- Month Navigation ---
  void setDashboardMonth(DateTime month) {
    _selectedDashboardMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  void nextDashboardMonth() {
    _selectedDashboardMonth = DateTime(
      _selectedDashboardMonth.year,
      _selectedDashboardMonth.month + 1,
      1,
    );
    notifyListeners();
  }

  void prevDashboardMonth() {
    _selectedDashboardMonth = DateTime(
      _selectedDashboardMonth.year,
      _selectedDashboardMonth.month - 1,
      1,
    );
    notifyListeners();
  }

  // --- Balance Calculations ---
  double getWalletBalance(String walletId) {
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => Wallet(
        id: walletId,
        name: 'Account',
        type: 'Cash',
        iconCodePoint: Icons.account_balance_wallet.codePoint,
        colorValue: 0xFF2196F3,
      ),
    );

    double balance = wallet.initialBalance;

    for (final t in _transactions) {
      if (t.type == TransactionType.income && t.walletId == walletId) {
        balance += t.amount;
      } else if (t.type == TransactionType.expense && t.walletId == walletId) {
        balance -= t.amount;
      } else if (t.type == TransactionType.transfer) {
        if (t.walletId == walletId) {
          balance -= t.amount; // Outgoing transfer
        }
        if (t.toWalletId == walletId) {
          balance += t.amount; // Incoming transfer
        }
      }
    }

    return balance;
  }

  double get totalBalance {
    double total = 0.0;
    for (final w in _wallets) {
      total += getWalletBalance(w.id);
    }
    return total;
  }

  // Monthly stats for selected dashboard month
  double get selectedMonthIncome {
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == _selectedDashboardMonth.year &&
            t.date.month == _selectedDashboardMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get selectedMonthExpense {
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == _selectedDashboardMonth.year &&
            t.date.month == _selectedDashboardMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Percentage vs last month
  double get expenseChangeVsLastMonth {
    final prevMonth = DateTime(
      _selectedDashboardMonth.year,
      _selectedDashboardMonth.month - 1,
      1,
    );
    final lastMonthExpense = _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == prevMonth.year &&
            t.date.month == prevMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (lastMonthExpense == 0) return 0.0;
    return ((selectedMonthExpense - lastMonthExpense) / lastMonthExpense) * 100;
  }

  // Quick stats: today's spend, this week's spend, daily average
  double get todaySpend {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get thisWeekSpend {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.date.isBefore(startDate) &&
            t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get dailyAverageSpendThisMonth {
    final now = DateTime.now();
    if (_selectedDashboardMonth.year == now.year &&
        _selectedDashboardMonth.month == now.month) {
      final daysPassed = now.day;
      return daysPassed > 0 ? selectedMonthExpense / daysPassed : 0.0;
    } else {
      final totalDays = DateTime(
        _selectedDashboardMonth.year,
        _selectedDashboardMonth.month + 1,
        0,
      ).day;
      return totalDays > 0 ? selectedMonthExpense / totalDays : 0.0;
    }
  }

  // Budget for current/selected month
  Budget? get currentOverallBudget {
    try {
      return _budgets.firstWhere(
        (b) =>
            b.isOverall &&
            b.month == _selectedDashboardMonth.month &&
            b.year == _selectedDashboardMonth.year,
      );
    } catch (_) {
      return null;
    }
  }

  // Top spending category for selected month
  MapEntry<Category, double>? get topSpendingCategoryThisMonth {
    final expenses = _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == _selectedDashboardMonth.year &&
            t.date.month == _selectedDashboardMonth.month)
        .toList();

    if (expenses.isEmpty) return null;

    final Map<String, double> catTotals = {};
    for (final t in expenses) {
      catTotals[t.categoryId] = (catTotals[t.categoryId] ?? 0.0) + t.amount;
    }

    if (catTotals.isEmpty) return null;

    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topEntry = sorted.first;

    final cat = _categories.firstWhere(
      (c) => c.id == topEntry.key,
      orElse: () => Category(
        id: topEntry.key,
        name: 'Other',
        iconCodePoint: Icons.more_horiz.codePoint,
        colorValue: 0xFF9E9E9E,
      ),
    );

    return MapEntry(cat, topEntry.value);
  }

  // Recent transactions (most recent 5 or 10)
  List<Transaction> get recentTransactions {
    final list = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return list.take(10).toList();
  }

  // Filtered transactions for the Transactions Screen
  List<Transaction> get filteredTransactions {
    final query = _searchQuery.toLowerCase().trim();

    final result = _transactions.where((t) {
      // 1. Search query
      if (query.isNotEmpty) {
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesNote = t.note?.toLowerCase().contains(query) ?? false;
        final matchesAmount = t.amount.toString().contains(query);
        if (!matchesTitle && !matchesNote && !matchesAmount) return false;
      }

      // 2. Type filter
      if (_filterType != null && t.type != _filterType) return false;

      // 3. Category filter (multi-select)
      if (_filterCategoryIds.isNotEmpty && !_filterCategoryIds.contains(t.categoryId)) {
        return false;
      }

      // 4. Wallet filter
      if (_filterWalletId != null &&
          t.walletId != _filterWalletId &&
          t.toWalletId != _filterWalletId) {
        return false;
      }

      // 5. Date Range
      if (_filterStartDate != null && t.date.isBefore(_filterStartDate!)) return false;
      if (_filterEndDate != null && t.date.isAfter(_filterEndDate!)) return false;

      // 6. Amount Range
      if (_filterMinAmount != null && t.amount < _filterMinAmount!) return false;
      if (_filterMaxAmount != null && t.amount > _filterMaxAmount!) return false;

      return true;
    }).toList();

    // Sorting
    switch (_sortOrder) {
      case TransactionSortOrder.newest:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TransactionSortOrder.oldest:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortOrder.highestAmount:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortOrder.lowestAmount:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return result;
  }

  // Smart Insights List
  List<InsightItem> get smartInsights {
    return InsightsService.generateInsights(
      transactions: _transactions,
      categories: _categories,
      overallBudget: currentOverallBudget,
      currencySymbol: _currencySymbol,
    );
  }

  // --- Transaction CRUD ---
  void addTransaction({
    required TransactionType type,
    required double amount,
    required String title,
    required String categoryId,
    required String walletId,
    String? toWalletId,
    required DateTime date,
    String? note,
  }) {
    final txn = Transaction(
      id: _uuid.v4(),
      type: type,
      amount: double.parse(amount.toStringAsFixed(2)),
      title: title.trim(),
      categoryId: categoryId,
      walletId: walletId,
      toWalletId: toWalletId,
      date: date,
      note: note?.trim(),
    );

    _transactions.add(txn);
    _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  void updateTransaction(Transaction updated) {
    final index = _transactions.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _transactions[index] = updated.copyWith(
        amount: double.parse(updated.amount.toStringAsFixed(2)),
        title: updated.title.trim(),
        note: updated.note?.trim(),
      );
      _storageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      _lastDeletedTransaction = _transactions[index];
      _transactions.removeAt(index);
      _storageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  void undoDeleteTransaction() {
    if (_lastDeletedTransaction != null) {
      _transactions.add(_lastDeletedTransaction!);
      _lastDeletedTransaction = null;
      _storageService.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  void duplicateTransaction(Transaction original) {
    final copy = original.copyWith(
      id: _uuid.v4(),
      date: DateTime.now(),
    );
    _transactions.add(copy);
    _storageService.saveTransactions(_transactions);
    notifyListeners();
  }

  // --- Category CRUD ---
  void addCategory({
    required String name,
    required int iconCodePoint,
    required int colorValue,
    bool isIncome = false,
  }) {
    final cat = Category(
      id: 'custom_cat_${_uuid.v4().substring(0, 8)}',
      name: name.trim(),
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      isCustom: true,
      isIncome: isIncome,
    );
    _categories.add(cat);
    _storageService.saveCategories(_categories);
    notifyListeners();
  }

  void updateCategory(Category updated) {
    final index = _categories.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      _categories[index] = updated;
      _storageService.saveCategories(_categories);
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    if (id == AppConstants.otherCategoryId) return; // Cannot delete fallback

    // Move associated transactions to "Other" category
    for (int i = 0; i < _transactions.length; i++) {
      if (_transactions[i].categoryId == id) {
        _transactions[i] = _transactions[i].copyWith(categoryId: AppConstants.otherCategoryId);
      }
    }
    _storageService.saveTransactions(_transactions);

    _categories.removeWhere((c) => c.id == id);
    _storageService.saveCategories(_categories);
    notifyListeners();
  }

  // --- Wallet CRUD ---
  void addWallet({
    required String name,
    required String type,
    required int iconCodePoint,
    required int colorValue,
    double initialBalance = 0.0,
  }) {
    final wallet = Wallet(
      id: 'wallet_${_uuid.v4().substring(0, 8)}',
      name: name.trim(),
      type: type,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      initialBalance: double.parse(initialBalance.toStringAsFixed(2)),
    );
    _wallets.add(wallet);
    _storageService.saveWallets(_wallets);
    notifyListeners();
  }

  void updateWallet(Wallet updated) {
    final index = _wallets.indexWhere((w) => w.id == updated.id);
    if (index != -1) {
      _wallets[index] = updated;
      _storageService.saveWallets(_wallets);
      notifyListeners();
    }
  }

  int countTransactionsForWallet(String walletId) {
    return _transactions
        .where((t) => t.walletId == walletId || t.toWalletId == walletId)
        .length;
  }

  void deleteWallet(String id, {String? reassignToWalletId}) {
    if (reassignToWalletId != null) {
      // Reassign transactions
      for (int i = 0; i < _transactions.length; i++) {
        var t = _transactions[i];
        if (t.walletId == id) {
          t = t.copyWith(walletId: reassignToWalletId);
        }
        if (t.toWalletId == id) {
          t = t.copyWith(toWalletId: reassignToWalletId);
        }
        _transactions[i] = t;
      }
      _storageService.saveTransactions(_transactions);
    }

    _wallets.removeWhere((w) => w.id == id);
    _storageService.saveWallets(_wallets);
    notifyListeners();
  }

  // --- Budget CRUD ---
  void setOverallBudget({
    required double amount,
    required int month,
    required int year,
  }) {
    final index = _budgets.indexWhere((b) => b.isOverall && b.month == month && b.year == year);
    if (index != -1) {
      _budgets[index] = _budgets[index].copyWith(amount: amount);
    } else {
      _budgets.add(Budget(
        id: _uuid.v4(),
        amount: amount,
        categoryId: null,
        month: month,
        year: year,
      ));
    }
    _storageService.saveBudgets(_budgets);
    notifyListeners();
  }

  void setCategoryBudget({
    required String categoryId,
    required double amount,
    required int month,
    required int year,
  }) {
    final index = _budgets.indexWhere(
        (b) => b.categoryId == categoryId && b.month == month && b.year == year);
    if (index != -1) {
      _budgets[index] = _budgets[index].copyWith(amount: amount);
    } else {
      _budgets.add(Budget(
        id: _uuid.v4(),
        amount: amount,
        categoryId: categoryId,
        month: month,
        year: year,
      ));
    }
    _storageService.saveBudgets(_budgets);
    notifyListeners();
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((b) => b.id == id);
    _storageService.saveBudgets(_budgets);
    notifyListeners();
  }

  // --- Goals CRUD ---
  void addGoal({
    required String name,
    required double targetAmount,
    double savedAmount = 0.0,
    DateTime? targetDate,
    required int iconCodePoint,
    required int colorValue,
  }) {
    final goal = SavingsGoal(
      id: _uuid.v4(),
      name: name.trim(),
      targetAmount: double.parse(targetAmount.toStringAsFixed(2)),
      savedAmount: double.parse(savedAmount.toStringAsFixed(2)),
      targetDate: targetDate,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
    );
    _goals.add(goal);
    _storageService.saveGoals(_goals);
    notifyListeners();
  }

  void updateGoal(SavingsGoal updated) {
    final index = _goals.indexWhere((g) => g.id == updated.id);
    if (index != -1) {
      _goals[index] = updated;
      _storageService.saveGoals(_goals);
      notifyListeners();
    }
  }

  void contributeToGoal(String goalId, double amount) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final current = _goals[index];
      _goals[index] = current.copyWith(
        savedAmount: double.parse((current.savedAmount + amount).toStringAsFixed(2)),
      );
      _storageService.saveGoals(_goals);
      notifyListeners();
    }
  }

  void withdrawFromGoal(String goalId, double amount) {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final current = _goals[index];
      final newSaved = (current.savedAmount - amount).clamp(0.0, double.infinity);
      _goals[index] = current.copyWith(
        savedAmount: double.parse(newSaved.toStringAsFixed(2)),
      );
      _storageService.saveGoals(_goals);
      notifyListeners();
    }
  }

  void deleteGoal(String id) {
    _goals.removeWhere((g) => g.id == id);
    _storageService.saveGoals(_goals);
    notifyListeners();
  }

  // --- Recurring Rules CRUD & Engine ---
  void addRecurringRule({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String walletId,
    String? toWalletId,
    required RecurringFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    String? note,
  }) {
    final rule = RecurringRule(
      id: _uuid.v4(),
      title: title.trim(),
      amount: double.parse(amount.toStringAsFixed(2)),
      type: type,
      categoryId: categoryId,
      walletId: walletId,
      toWalletId: toWalletId,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      // Default last generated date is right before startDate so first execution runs
      lastGeneratedDate: startDate.subtract(const Duration(days: 1)),
      isPaused: false,
      note: note?.trim(),
    );

    _recurringRules.add(rule);
    _storageService.saveRecurringRules(_recurringRules);
    processRecurringRules();
    notifyListeners();
  }

  void updateRecurringRule(RecurringRule updated) {
    final index = _recurringRules.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _recurringRules[index] = updated;
      _storageService.saveRecurringRules(_recurringRules);
      notifyListeners();
    }
  }

  void toggleRecurringRulePause(String id) {
    final index = _recurringRules.indexWhere((r) => r.id == id);
    if (index != -1) {
      final rule = _recurringRules[index];
      _recurringRules[index] = rule.copyWith(isPaused: !rule.isPaused);
      _storageService.saveRecurringRules(_recurringRules);
      notifyListeners();
    }
  }

  void deleteRecurringRule(String id) {
    _recurringRules.removeWhere((r) => r.id == id);
    _storageService.saveRecurringRules(_recurringRules);
    notifyListeners();
  }

  /// Automatically generates all due recurring transactions without duplicates
  void processRecurringRules() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    bool modified = false;

    for (int i = 0; i < _recurringRules.length; i++) {
      final rule = _recurringRules[i];
      if (rule.isPaused) continue;

      DateTime cursor = rule.lastGeneratedDate;

      while (true) {
        DateTime nextDue;
        switch (rule.frequency) {
          case RecurringFrequency.daily:
            nextDue = cursor.add(const Duration(days: 1));
            break;
          case RecurringFrequency.weekly:
            nextDue = cursor.add(const Duration(days: 7));
            break;
          case RecurringFrequency.monthly:
            nextDue = DateTime(cursor.year, cursor.month + 1, cursor.day);
            break;
          case RecurringFrequency.yearly:
            nextDue = DateTime(cursor.year + 1, cursor.month, cursor.day);
            break;
        }

        // Must be at or after startDate
        if (nextDue.isBefore(rule.startDate)) {
          nextDue = rule.startDate;
        }

        // If beyond today or after optional endDate, stop
        if (nextDue.isAfter(today)) break;
        if (rule.endDate != null && nextDue.isAfter(rule.endDate!)) break;

        // Create transaction
        final txn = Transaction(
          id: _uuid.v4(),
          type: rule.type,
          amount: rule.amount,
          title: rule.title,
          categoryId: rule.categoryId,
          walletId: rule.walletId,
          toWalletId: rule.toWalletId,
          date: nextDue,
          note: rule.note ?? 'Recurring (${rule.frequency.name})',
        );

        _transactions.add(txn);
        cursor = nextDue;
        modified = true;
      }

      if (cursor != rule.lastGeneratedDate) {
        _recurringRules[i] = rule.copyWith(lastGeneratedDate: cursor);
      }
    }

    if (modified) {
      _storageService.saveTransactions(_transactions);
      _storageService.saveRecurringRules(_recurringRules);
    }
  }

  // --- Filter and Sort Modifiers ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    notifyListeners();
  }

  void toggleCategoryFilter(String categoryId) {
    if (_filterCategoryIds.contains(categoryId)) {
      _filterCategoryIds.remove(categoryId);
    } else {
      _filterCategoryIds.add(categoryId);
    }
    notifyListeners();
  }

  void setFilterWallet(String? walletId) {
    _filterWalletId = walletId;
    notifyListeners();
  }

  void setDateRangeFilter(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    notifyListeners();
  }

  void setAmountRangeFilter(double? min, double? max) {
    _filterMinAmount = min;
    _filterMaxAmount = max;
    notifyListeners();
  }

  void setSortOrder(TransactionSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterType = null;
    _filterCategoryIds.clear();
    _filterWalletId = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _filterMinAmount = null;
    _filterMaxAmount = null;
    notifyListeners();
  }

  // --- Settings Modifiers ---
  void setCurrency(String symbol, String code) {
    _currencySymbol = symbol;
    _currencyCode = code;
    _persistSettings();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _persistSettings();
    notifyListeners();
  }

  void setAccentColorIndex(int index) {
    _accentColorIndex = index.clamp(0, AppConstants.accentColors.length - 1);
    _persistSettings();
    notifyListeners();
  }

  void setPin(String newPin) {
    _pin = newPin;
    _persistSettings();
    notifyListeners();
  }

  void disablePin() {
    _pin = null;
    _isLocked = false;
    _persistSettings();
    notifyListeners();
  }

  void completeOnboarding() {
    _hasOnboarded = true;
    _persistSettings();
    notifyListeners();
  }

  void _persistSettings() {
    final themeStr = _themeMode == ThemeMode.dark
        ? 'dark'
        : _themeMode == ThemeMode.light
            ? 'light'
            : 'system';

    _storageService.saveSettings({
      'currencySymbol': _currencySymbol,
      'currencyCode': _currencyCode,
      'themeMode': themeStr,
      'accentColorIndex': _accentColorIndex,
      'pin': _pin,
      'hasOnboarded': _hasOnboarded,
    }, immediate: true);
  }

  // --- Restore and Clear All ---
  Future<void> restoreFromJson(Map<String, dynamic> data) async {
    if (data.containsKey('transactions')) {
      final List list = data['transactions'] as List;
      _transactions = list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
      _storageService.saveTransactions(_transactions, immediate: true);
    }
    if (data.containsKey('categories')) {
      final List list = data['categories'] as List;
      _categories = list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
      _storageService.saveCategories(_categories, immediate: true);
    }
    if (data.containsKey('wallets')) {
      final List list = data['wallets'] as List;
      _wallets = list.map((e) => Wallet.fromJson(e as Map<String, dynamic>)).toList();
      _storageService.saveWallets(_wallets, immediate: true);
    }
    if (data.containsKey('budgets')) {
      final List list = data['budgets'] as List;
      _budgets = list.map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
      _storageService.saveBudgets(_budgets, immediate: true);
    }
    if (data.containsKey('goals')) {
      final List list = data['goals'] as List;
      _goals = list.map((e) => SavingsGoal.fromJson(e as Map<String, dynamic>)).toList();
      _storageService.saveGoals(_goals, immediate: true);
    }
    if (data.containsKey('recurringRules')) {
      final List list = data['recurringRules'] as List;
      _recurringRules = list.map((e) => RecurringRule.fromJson(e as Map<String, dynamic>)).toList();
      _storageService.saveRecurringRules(_recurringRules, immediate: true);
    }
    if (data.containsKey('settings')) {
      final settings = data['settings'] as Map<String, dynamic>;
      _currencySymbol = settings['currencySymbol'] as String? ?? '₹';
      _currencyCode = settings['currencyCode'] as String? ?? 'INR';
      final themeStr = settings['themeMode'] as String? ?? 'system';
      _themeMode = themeStr == 'dark'
          ? ThemeMode.dark
          : themeStr == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
      _accentColorIndex = (settings['accentColorIndex'] as num?)?.toInt() ?? 0;
      _pin = settings['pin'] as String?;
      _hasOnboarded = settings['hasOnboarded'] as bool? ?? true;
      _persistSettings();
    }

    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _storageService.clearAll();
    _transactions = [];
    _categories = AppConstants.defaultCategories;
    _wallets = AppConstants.defaultWallets;
    _budgets = [];
    _goals = [];
    _recurringRules = [];
    _pin = null;
    _isLocked = false;
    _hasOnboarded = false;
    _currencySymbol = '₹';
    _currencyCode = 'INR';
    _themeMode = ThemeMode.system;
    _accentColorIndex = 0;
    _searchQuery = '';
    _filterType = null;
    _filterCategoryIds.clear();
    _filterWalletId = null;
    notifyListeners();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}

