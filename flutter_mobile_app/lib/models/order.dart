import 'product.dart';
import 'shipping_address.dart';
import 'user.dart';

class OrderItem {
  final int id;
  final Product product;
  final ProductBatch? batch;
  final double price;
  final int quantity;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.product,
    this.batch,
    required this.price,
    required this.quantity,
    required this.createdAt,
  });

  double get totalPrice {
    return price * quantity;
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      batch: json['batch'] != null ? ProductBatch.fromJson(json['batch']) : null,
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'batch': batch?.toJson(),
      'price': price,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Order {
  final int id;
  final User user;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final ShippingAddress shippingAddress;
  final String shippingMethod;
  final double shippingCost;
  final double subtotal;
  final double total;
  final double depositAmount;
  final bool depositPaid;
  final String? paymentId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedDelivery;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.user,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.shippingMethod,
    required this.shippingCost,
    required this.subtotal,
    required this.total,
    required this.depositAmount,
    required this.depositPaid,
    this.paymentId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDelivery,
    required this.items,
  });

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      user: User.fromJson(json['user']),
      orderNumber: json['order_number'],
      status: json['status'],
      paymentStatus: json['payment_status'],
      shippingAddress: ShippingAddress.fromJson(json['shipping_address']),
      shippingMethod: json['shipping_method'],
      shippingCost: json['shipping_cost'].toDouble(),
      subtotal: json['subtotal'].toDouble(),
      total: json['total'].toDouble(),
      depositAmount: json['deposit_amount'].toDouble(),
      depositPaid: json['deposit_paid'],
      paymentId: json['payment_id'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.parse(json['estimated_delivery'])
          : null,
      items: List<OrderItem>.from(json['items'].map((x) => OrderItem.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'order_number': orderNumber,
      'status': status,
      'payment_status': paymentStatus,
      'shipping_address': shippingAddress.toJson(),
      'shipping_method': shippingMethod,
      'shipping_cost': shippingCost,
      'subtotal': subtotal,
      'total': total,
      'deposit_amount': depositAmount,
      'deposit_paid': depositPaid,
      'payment_id': paymentId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
      'items': items.map((x) => x.toJson()).toList(),
    };
  }
}

class WaitlistItem {
  final int id;
  final User user;
  final ProductBatch batch;
  final Product product;
  final int quantity;
  final double depositAmount;
  final bool depositPaid;
  final String? paymentId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  WaitlistItem({
    required this.id,
    required this.user,
    required this.batch,
    required this.product,
    required this.quantity,
    required this.depositAmount,
    required this.depositPaid,
    this.paymentId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WaitlistItem.fromJson(Map<String, dynamic> json) {
    return WaitlistItem(
      id: json['id'],
      user: User.fromJson(json['user']),
      batch: ProductBatch.fromJson(json['batch']),
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
      depositAmount: json['deposit_amount'].toDouble(),
      depositPaid: json['deposit_paid'],
      paymentId: json['payment_id'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'batch': batch.toJson(),
      'product': product.toJson(),
      'quantity': quantity,
      'deposit_amount': depositAmount,
      'deposit_paid': depositPaid,
      'payment_id': paymentId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}