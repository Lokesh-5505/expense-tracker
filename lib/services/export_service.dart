import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/budget.dart';
import '../models/goal.dart';
import '../models/recurring_rule.dart';
import '../utils/formatters.dart';

class ExportService {
  /// Export transactions to CSV and share using SharePlus
  static Future<void> exportTransactionsToCsv({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<Wallet> wallets,
    required String currencySymbol,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final filtered = transactions.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final Map<String, String> catMap = {for (var c in categories) c.id: c.name};
    final Map<String, String> walletMap = {for (var w in wallets) w.id: w.name};

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
        'ID,Date,Time,Type,Title,Category,Wallet,To Wallet,Amount,Currency,Note');

    for (final t in filtered) {
      final id = _escapeCsv(t.id);
      final date = AppFormatters.formatDate(t.date);
      final time = AppFormatters.formatTime(t.date);
      final type = t.type.name.toUpperCase();
      final title = _escapeCsv(t.title);
      final category = _escapeCsv(catMap[t.categoryId] ?? 'Other');
      final wallet = _escapeCsv(walletMap[t.walletId] ?? 'Account');
      final toWallet = t.toWalletId != null
          ? _escapeCsv(walletMap[t.toWalletId] ?? '')
          : '';
      final amount = t.amount.toStringAsFixed(2);
      final note = _escapeCsv(t.note ?? '');

      buffer.writeln(
          '$id,"$date","$time","$type","$title","$category","$wallet","$toWallet",$amount,"$currencySymbol","$note"');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/expense_tracker_export_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Expense Tracker CSV Export',
      text: 'Exported ${filtered.length} transactions from Expense Tracker.',
    );
  }

  /// Create JSON Backup file and share
  static Future<void> exportJsonBackup({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<Wallet> wallets,
    required List<Budget> budgets,
    required List<SavingsGoal> goals,
    required List<RecurringRule> rules,
    required Map<String, dynamic> settings,
  }) async {
    final payload = {
      'app': 'Expense Tracker',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'categories': categories.map((e) => e.toJson()).toList(),
        'wallets': wallets.map((e) => e.toJson()).toList(),
        'budgets': budgets.map((e) => e.toJson()).toList(),
        'goals': goals.map((e) => e.toJson()).toList(),
        'recurringRules': rules.map((e) => e.toJson()).toList(),
        'settings': settings,
      }
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/expense_tracker_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Expense Tracker Data Backup',
      text: 'Complete offline backup file for Expense Tracker.',
    );
  }

  /// Parse and validate JSON backup string for restore
  static Map<String, dynamic>? parseBackupString(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return null;
      if (!decoded.containsKey('data')) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  static String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }
}
