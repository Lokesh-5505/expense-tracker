import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/services/storage_service.dart';
import 'package:expense_tracker/services/app_state.dart';
import 'package:expense_tracker/services/insights_service.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/recurring_rule.dart';
import 'package:expense_tracker/utils/formatters.dart';
import 'package:expense_tracker/utils/validators.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    appState = AppState(storage);
    await appState.initialize();
  });

  group('1. Transactions Feature', () {
    test('Add expense, income, and transfer', () {
      final w1 = appState.wallets[0].id;
      final w2 = appState.wallets[1].id;
      final cat = appState.categories[0].id;

      // Add expense
      appState.addTransaction(
        type: TransactionType.expense,
        amount: 250.0,
        title: 'Coffee and snacks',
        categoryId: cat,
        walletId: w1,
        date: DateTime.now(),
      );

      // Add income
      appState.addTransaction(
        type: TransactionType.income,
        amount: 5000.0,
        title: 'Freelance payment',
        categoryId: cat,
        walletId: w1,
        date: DateTime.now(),
      );

      // Add transfer
      appState.addTransaction(
        type: TransactionType.transfer,
        amount: 1000.0,
        title: 'Move to Bank',
        categoryId: cat,
        walletId: w1,
        toWalletId: w2,
        date: DateTime.now(),
      );

      expect(appState.transactions.length, 3);
      expect(appState.getWalletBalance(w1), 5000.0 - 250.0 - 1000.0); // 3750.0
      expect(appState.getWalletBalance(w2), 1000.0);
      expect(appState.totalBalance, 4750.0);
    });

    test('Edit, duplicate, delete and undo transaction', () {
      final w1 = appState.wallets[0].id;
      final cat = appState.categories[0].id;

      appState.addTransaction(
        type: TransactionType.expense,
        amount: 100.0,
        title: 'Lunch',
        categoryId: cat,
        walletId: w1,
        date: DateTime.now(),
      );

      final txn = appState.transactions.first;

      // Update
      appState.updateTransaction(txn.copyWith(amount: 150.0, title: 'Dinner'));
      expect(appState.transactions.first.amount, 150.0);
      expect(appState.transactions.first.title, 'Dinner');

      // Duplicate
      appState.duplicateTransaction(appState.transactions.first);
      expect(appState.transactions.length, 2);

      // Delete
      final deleteId = appState.transactions.first.id;
      appState.deleteTransaction(deleteId);
      expect(appState.transactions.length, 1);

      // Undo delete
      appState.undoDeleteTransaction();
      expect(appState.transactions.length, 2);
    });
  });

  group('2. Wallets & Reassign Feature', () {
    test('Add wallet, track balance, and reassign transactions on delete', () {
      appState.addWallet(
        name: 'Investment Account',
        type: 'Bank',
        iconCodePoint: 0xe040,
        colorValue: 0xFF1E88E5,
        initialBalance: 10000.0,
      );

      expect(appState.wallets.any((w) => w.name == 'Investment Account'), true);
      final newWallet = appState.wallets.firstWhere((w) => w.name == 'Investment Account');
      expect(appState.getWalletBalance(newWallet.id), 10000.0);

      // Add transaction to this wallet
      appState.addTransaction(
        type: TransactionType.expense,
        amount: 200.0,
        title: 'Brokerage Fee',
        categoryId: appState.categories.first.id,
        walletId: newWallet.id,
        date: DateTime.now(),
      );

      expect(appState.countTransactionsForWallet(newWallet.id), 1);

      // Delete wallet and reassign transactions to first wallet
      final targetWalletId = appState.wallets[0].id;
      appState.deleteWallet(newWallet.id, reassignToWalletId: targetWalletId);

      expect(appState.wallets.any((w) => w.id == newWallet.id), false);
      expect(appState.transactions.first.walletId, targetWalletId);
    });
  });

  group('3. Categories Feature', () {
    test('Add custom category and verify transactions move to Other on delete', () {
      appState.addCategory(
        name: 'Streaming',
        iconCodePoint: 0xe3e3,
        colorValue: 0xFFAB47BC,
      );

      final customCat = appState.categories.firstWhere((c) => c.name == 'Streaming');
      expect(customCat.isCustom, true);

      // Add transaction with this category
      appState.addTransaction(
        type: TransactionType.expense,
        amount: 15.0,
        title: 'Spotify',
        categoryId: customCat.id,
        walletId: appState.wallets.first.id,
        date: DateTime.now(),
      );

      // Delete custom category
      appState.deleteCategory(customCat.id);
      expect(appState.categories.any((c) => c.id == customCat.id), false);
      expect(appState.transactions.first.categoryId, 'cat_other');
    });
  });

  group('4. Budgets Feature', () {
    test('Set overall budget and category budgets', () {
      final now = DateTime.now();
      appState.setOverallBudget(amount: 50000.0, month: now.month, year: now.year);
      expect(appState.currentOverallBudget?.amount, 50000.0);

      final catId = appState.categories.first.id;
      appState.setCategoryBudget(categoryId: catId, amount: 8000.0, month: now.month, year: now.year);
      expect(appState.budgets.any((b) => b.categoryId == catId && b.amount == 8000.0), true);
    });
  });

  group('5. Savings Goals Feature', () {
    test('Create goal, contribute, withdraw, and check completion', () {
      appState.addGoal(
        name: 'Emergency Fund',
        targetAmount: 10000.0,
        savedAmount: 0.0,
        iconCodePoint: 0xe57a,
        colorValue: 0xFF00C853,
      );

      final goal = appState.goals.firstWhere((g) => g.name == 'Emergency Fund');
      expect(goal.isCompleted, false);
      expect(goal.progress, 0.0);

      // Contribute
      appState.contributeToGoal(goal.id, 6000.0);
      var updated = appState.goals.firstWhere((g) => g.id == goal.id);
      expect(updated.savedAmount, 6000.0);
      expect(updated.progress, 0.6);
      expect(updated.remainingAmount, 4000.0);

      // Complete
      appState.contributeToGoal(goal.id, 4000.0);
      updated = appState.goals.firstWhere((g) => g.id == goal.id);
      expect(updated.isCompleted, true);

      // Withdraw
      appState.withdrawFromGoal(goal.id, 2000.0);
      updated = appState.goals.firstWhere((g) => g.id == goal.id);
      expect(updated.savedAmount, 8000.0);
      expect(updated.isCompleted, false);
    });
  });

  group('6. Recurring Transactions Feature', () {
    test('Process recurring rule backfills due transactions without duplicates', () {
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      appState.addRecurringRule(
        title: 'Daily Transit Pass',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: appState.categories.first.id,
        walletId: appState.wallets.first.id,
        frequency: RecurringFrequency.daily,
        startDate: fiveDaysAgo,
      );

      // Rule created, processRecurringRules automatically runs
      expect(appState.transactions.length >= 5, true);

      final countBefore = appState.transactions.length;
      // Processing again on the same day should NOT add duplicates
      appState.processRecurringRules();
      expect(appState.transactions.length, countBefore);
    });
  });

  group('7. Formatters & Validators', () {
    test('Indian number formatting with commas and decimals', () {
      final formatted = AppFormatters.formatCurrency(125000.50, currencySymbol: '₹');
      expect(formatted, '₹1,25,000.50');
    });

    test('Compact number formatting', () {
      expect(AppFormatters.formatCompactNumber(150000.0, currencySymbol: '₹'), '₹1.5L');
      expect(AppFormatters.formatCompactNumber(35000000.0, currencySymbol: '₹'), '₹3.5Cr');
      expect(AppFormatters.formatCompactNumber(2500.0, currencySymbol: '₹'), '₹2.5K');
    });

    test('Validators', () {
      expect(AppValidators.validateAmount('0'), 'Amount must be greater than 0');
      expect(AppValidators.validateAmount('-50'), 'Amount must be greater than 0');
      expect(AppValidators.validateAmount('abc'), 'Enter a valid number');
      expect(AppValidators.validateAmount('1250.75'), null);

      expect(AppValidators.validatePin('123'), 'PIN must be exactly 4 digits');
      expect(AppValidators.validatePin('1234'), null);
    });
  });

  group('8. Backup and Restore Validation', () {
    test('Valid backup payload passes validation', () {
      const validJson = '''
      {
        "version": "1.0.0",
        "data": {
          "transactions": [],
          "categories": []
        }
      }
      ''';
      expect(AppValidators.validateBackupJson(validJson) != null, true);

      const invalidJson = '{"foo": "bar"}';
      expect(AppValidators.validateBackupJson(invalidJson), null);
    });
  });

  group('9. Smart Insights Service', () {
    test('Generates local insights without errors', () {
      final insights = InsightsService.generateInsights(
        transactions: appState.transactions,
        categories: appState.categories,
        overallBudget: appState.currentOverallBudget,
        currencySymbol: appState.currencySymbol,
      );
      expect(insights.isNotEmpty, true);
    });
  });
}
