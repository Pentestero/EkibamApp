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
    print("PurchaseItem.fromMap received map: $map"); // Debug print
    final productName = map['productName'] as String?;
    final supplierName = map['supplierName'] as String?;
    print("  -> productName: $productName, supplierName: $supplierName"); // Debug print

    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int? ?? 0,
      productId: map['product_id'] as int? ?? 0,
      supplierId: map['supplier_id'] as int?, // Can be null
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      paymentFee: (map['payment_fee'] as num?)?.toDouble() ?? 0.0, // Read paymentFee, default to 0.0
      comment: map['comment'] as String?,
      productName: productName, 
      supplierName: supplierName,
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