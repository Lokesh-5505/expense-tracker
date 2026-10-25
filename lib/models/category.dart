class Category {
  final String id;
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;
  final bool isCustom;
  final bool isIncome;

  const Category({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
    this.isCustom = false,
    this.isIncome = false,
  });

  Category copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    int? colorValue,
    bool? isCustom,
    bool? isIncome,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
      isIncome: isIncome ?? this.isIncome,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'colorValue': colorValue,
      'isCustom': isCustom,
      'isIncome': isIncome,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      iconFontFamily: json['iconFontFamily'] as String?,
      colorValue: json['colorValue'] as int,
      isCustom: json['isCustom'] as bool? ?? false,
      isIncome: json['isIncome'] as bool? ?? false,
    );
  }
}
