
class Supplier {
  final int? id;
  final String name;

  Supplier({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  static Supplier fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
    );
  }

  Supplier copyWith({
    int? id,
    String? name,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
