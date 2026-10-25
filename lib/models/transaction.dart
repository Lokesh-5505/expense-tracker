enum TransactionType {
  expense,
  income,
  transfer,
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String title;
  final String categoryId;
  final String walletId;
  final String? toWalletId;
  final DateTime date;
  final String? note;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.title,
    required this.categoryId,
    required this.walletId,
    this.toWalletId,
    required this.date,
    this.note,
  });

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? title,
    String? categoryId,
    String? walletId,
    String? toWalletId,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      toWalletId: toWalletId ?? this.toWalletId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'title': title,
      'categoryId': categoryId,
      'walletId': walletId,
      'toWalletId': toWalletId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (json['amount'] as num).toDouble(),
      title: json['title'] as String,
      categoryId: json['categoryId'] as String,
      walletId: json['walletId'] as String,
      toWalletId: json['toWalletId'] as String?,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}
