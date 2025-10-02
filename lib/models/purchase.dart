import 'package:provisions/models/purchase_item.dart';

class Purchase {
  final int? id;
  final String? requestNumber; // Added this field
  final DateTime date;
  final String owner;
  final String projectType;
  final String paymentMethod;
  final String comments;
  final DateTime createdAt;
  
  List<PurchaseItem> items;

  Purchase({
    this.id,
    this.requestNumber,
    required this.date,
    required this.owner,
    required this.projectType,
    required this.paymentMethod,
    this.comments = '',
    required this.createdAt,
    this.items = const [],
  });

  double get totalPaymentFees => items.fold(0.0, (sum, item) => sum + item.paymentFee);

  double get grandTotal => items.fold(0.0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestNumber': requestNumber,
      'date': date.millisecondsSinceEpoch,
      'owner': owner,
      'projectType': projectType,
      'paymentMethod': paymentMethod,
      'comments': comments,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toMapWithItems() {
    final map = toMap();
    map['items'] = items.map((item) => item.toMap()).toList();
    return map;
  }

  static Purchase fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as int?,
      requestNumber: map['requestNumber'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      owner: map['owner'] as String? ?? '',
      projectType: map['projectType'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? '',
      comments: map['comments'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  // Added copyWith for easier updates
  Purchase copyWith({
    int? id,
    String? requestNumber,
    DateTime? date,
    String? owner,
    String? projectType,
    String? paymentMethod,
    String? comments,
    DateTime? createdAt,
    List<PurchaseItem>? items,
  }) {
    return Purchase(
      id: id ?? this.id,
      requestNumber: requestNumber ?? this.requestNumber,
      date: date ?? this.date,
      owner: owner ?? this.owner,
      projectType: projectType ?? this.projectType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}