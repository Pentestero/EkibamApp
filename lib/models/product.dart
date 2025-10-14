
class Product {
  final int? id;
  final String name;
  final String unit;
  final double defaultPrice;

  Product({
    this.id,
    required this.name,
    this.unit = 'unité',
    this.defaultPrice = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'default_price': defaultPrice,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      unit: map['unit'],
      defaultPrice: (map['default_price'] ?? 0.0).toDouble(),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? unit,
    double? defaultPrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      defaultPrice: defaultPrice ?? this.defaultPrice,
    );
  }
}
