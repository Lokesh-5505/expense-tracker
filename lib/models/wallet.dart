class Wallet {
  final String id;
  final String name;
  final String type;
  final int iconCodePoint;
  final int colorValue;
  final double initialBalance;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCodePoint,
    required this.colorValue,
    this.initialBalance = 0.0,
  });

  Wallet copyWith({
    String? id,
    String? name,
    String? type,
    int? iconCodePoint,
    int? colorValue,
    double? initialBalance,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'initialBalance': initialBalance,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
