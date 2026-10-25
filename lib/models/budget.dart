class Budget {
  final String id;
  final double amount;
  final String? categoryId; // null represents overall monthly budget
  final int month;
  final int year;

  const Budget({
    required this.id,
    required this.amount,
    this.categoryId,
    required this.month,
    required this.year,
  });

  bool get isOverall => categoryId == null;

  Budget copyWith({
    String? id,
    double? amount,
    String? categoryId,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String?,
      month: json['month'] as int,
      year: json['year'] as int,
    );
  }
}
