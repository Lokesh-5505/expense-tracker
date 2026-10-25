class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? targetDate;
  final int iconCodePoint;
  final int colorValue;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.targetDate,
    required this.iconCodePoint,
    required this.colorValue,
  });

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => savedAmount >= targetAmount;

  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate?.toIso8601String(),
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      savedAmount: (json['savedAmount'] as num).toDouble(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
    );
  }
}
