class ProductBatch {
  final int id;
  final int productId;
  final int batchNumber;
  final int targetQuantity;
  final int currentQuantity;
  final bool isActive;
  final bool isFulfilled;
  final DateTime createdAt;
  final DateTime? fulfilledAt;
  final DateTime? estimatedShippingDate;
  final double progressPercentage;
  final int remainingQuantity;

  ProductBatch({
    required this.id,
    required this.productId,
    required this.batchNumber,
    required this.targetQuantity,
    required this.currentQuantity,
    required this.isActive,
    required this.isFulfilled,
    required this.createdAt,
    this.fulfilledAt,
    this.estimatedShippingDate,
    required this.progressPercentage,
    required this.remainingQuantity,
  });

  factory ProductBatch.fromJson(Map<String, dynamic> json) {
    return ProductBatch(
      id: json['id'],
      productId: json['product'],
      batchNumber: json['batch_number'],
      targetQuantity: json['target_quantity'],
      currentQuantity: json['current_quantity'],
      isActive: json['is_active'],
      isFulfilled: json['is_fulfilled'],
      createdAt: DateTime.parse(json['created_at']),
      fulfilledAt: json['fulfilled_at'] != null 
          ? DateTime.parse(json['fulfilled_at']) 
          : null,
      estimatedShippingDate: json['estimated_shipping_date'] != null 
          ? DateTime.parse(json['estimated_shipping_date']) 
          : null,
      progressPercentage: json['progress_percentage'].toDouble(),
      remainingQuantity: json['remaining_quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': productId,
      'batch_number': batchNumber,
      'target_quantity': targetQuantity,
      'current_quantity': currentQuantity,
      'is_active': isActive,
      'is_fulfilled': isFulfilled,
      'created_at': createdAt.toIso8601String(),
      'fulfilled_at': fulfilledAt?.toIso8601String(),
      'estimated_shipping_date': estimatedShippingDate?.toIso8601String(),
      'progress_percentage': progressPercentage,
      'remaining_quantity': remainingQuantity,
    };
  }
}