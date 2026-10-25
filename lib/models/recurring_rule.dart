import 'transaction.dart';

enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class RecurringRule {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String walletId;
  final String? toWalletId;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime lastGeneratedDate;
  final bool isPaused;
  final String? note;

  const RecurringRule({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.walletId,
    this.toWalletId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.lastGeneratedDate,
    this.isPaused = false,
    this.note,
  });

  RecurringRule copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    String? toWalletId,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastGeneratedDate,
    bool? isPaused,
    String? note,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      isPaused: isPaused ?? this.isPaused,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'walletId': walletId,
      'toWalletId': toWalletId,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'lastGeneratedDate': lastGeneratedDate.toIso8601String(),
      'isPaused': isPaused,
      'note': note,
    };
  }

  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    return RecurringRule(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'] as String,
      walletId: json['walletId'] as String,
      toWalletId: json['toWalletId'] as String?,
      frequency: RecurringFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      lastGeneratedDate: DateTime.parse(json['lastGeneratedDate'] as String),
      isPaused: json['isPaused'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}
