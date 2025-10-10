import 'package:provisions/models/purchase_item.dart';

class Purchase {
  final int? id;
  final String? requestNumber; // This will be the new DEMANDEUR-date-ID
  final DateTime date;
  final String owner;
  final String creatorInitials; // New field
  final String demander; // New field
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
    required this.creatorInitials,
    required this.demander,
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
      'creatorInitials': creatorInitials,
      'demander': demander,
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
      creatorInitials: map['creatorInitials'] as String? ?? '', // New field
      demander: map['demander'] as String? ?? '', // New field
      projectType: map['projectType'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? '',
      comments: map['comments'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Purchase copyWith({
    int? id,
    String? requestNumber,
    DateTime? date,
    String? owner,
    String? creatorInitials,
    String? demander,
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
      creatorInitials: creatorInitials ?? this.creatorInitials,
      demander: demander ?? this.demander,
      projectType: projectType ?? this.projectType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}