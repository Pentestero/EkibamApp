class PurchaseItem {
  final int? id;
  final int purchaseId;
  final int productId;
  final int? supplierId; // Made nullable
  final double quantity;
  final double unitPrice;
  final double paymentFee; // New field for payment fee
  final String? comment;

  // For display purposes, not stored in DB
  final String? productName;
  final String? supplierName;

  PurchaseItem({
    this.id,
    required this.purchaseId,
    required this.productId,
    this.supplierId, // No longer required
    required this.quantity,
    required this.unitPrice,
    this.paymentFee = 0.0, // Default to 0.0
    this.productName, // Not required for DB
    this.supplierName, // Not required for DB
    this.comment,
  });

  double get total => (quantity * unitPrice) + paymentFee; // Include paymentFee in total

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      'supplierId': supplierId, // Can be null
      'quantity': quantity,
      'unitPrice': unitPrice,
      'paymentFee': paymentFee, // Include paymentFee
      'comment': comment,
    };
  }

  static PurchaseItem fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchaseId'] as int,
      productId: map['productId'] as int,
      supplierId: map['supplierId'] as int?, // Can be null
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      paymentFee: (map['paymentFee'] as num?)?.toDouble() ?? 0.0, // Read paymentFee, default to 0.0
      comment: map['comment'] as String?,
      // The join will provide these fields
      productName: map['productName'] as String?, 
      supplierName: map['supplierName'] as String?,
    );
  }

  PurchaseItem copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    int? supplierId,
    double? quantity,
    double? unitPrice,
    double? paymentFee, // Include paymentFee
    String? productName,
    String? supplierName,
    String? comment,
  }) {
    return PurchaseItem(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      supplierId: supplierId ?? this.supplierId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      paymentFee: paymentFee ?? this.paymentFee, // Copy paymentFee
      productName: productName ?? this.productName,
      supplierName: supplierName ?? this.supplierName,
      comment: comment ?? this.comment,
    );
  }
}