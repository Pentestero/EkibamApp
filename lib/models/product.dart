
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
      'defaultPrice': defaultPrice,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      unit: map['unit'],
      defaultPrice: map['defaultPrice'],
    );
  }
}
