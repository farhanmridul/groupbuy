import 'category.dart';
import 'product_batch.dart';
import 'review.dart';
import 'user.dart';

class Product {
  final int id;
  final String title;
  final String slug;
  final Category category;
  final String description;
  final double marketPrice;
  final double wholesalePrice;
  final int moq;
  final int stock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;
  final List<Review> reviews;
  final ProductBatch? activeBatch;
  final double discountPercentage;
  
  Product({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.description,
    required this.marketPrice,
    required this.wholesalePrice,
    required this.moq,
    required this.stock,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    required this.reviews,
    this.activeBatch,
    required this.discountPercentage,
  });
  
  String get featuredImage {
    if (images.isEmpty) {
      return '';
    }
    
    // Try to find a featured image first
    final featuredImage = images.firstWhere(
      (img) => img.contains('featured') || img.contains('main') || img.contains('cover'),
      orElse: () => images.first,
    );
    
    return featuredImage;
  }
  
  double get averageRating {
    if (reviews.isEmpty) {
      return 0;
    }
    
    final totalRating = reviews.fold(0, (sum, review) => sum + review.rating);
    return totalRating / reviews.length;
  }
  
  int get reviewCount {
    return reviews.length;
  }
  
  bool get hasActiveBatch {
    return activeBatch != null;
  }
  
  bool get isMoqReached {
    if (activeBatch == null) {
      return false;
    }
    
    return activeBatch!.currentQuantity >= activeBatch!.targetQuantity;
  }
  
  double get batchProgress {
    if (activeBatch == null) {
      return 0;
    }
    
    return (activeBatch!.currentQuantity / activeBatch!.targetQuantity) * 100;
  }
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      category: Category.fromJson(json['category']),
      description: json['description'],
      marketPrice: json['market_price'].toDouble(),
      wholesalePrice: json['wholesale_price'].toDouble(),
      moq: json['moq'],
      stock: json['stock'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      images: List<String>.from(json['images'].map((x) => x['image'])),
      reviews: List<Review>.from(json['reviews'].map((x) => Review.fromJson(x))),
      activeBatch: json['active_batch'] != null 
          ? ProductBatch.fromJson(json['active_batch']) 
          : null,
      discountPercentage: json['discount_percentage'].toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'category': category.toJson(),
      'description': description,
      'market_price': marketPrice,
      'wholesale_price': wholesalePrice,
      'moq': moq,
      'stock': stock,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'images': images.map((x) => {'image': x}).toList(),
      'reviews': reviews.map((x) => x.toJson()).toList(),
      'active_batch': activeBatch?.toJson(),
      'discount_percentage': discountPercentage,
    };
  }
}

class CartItem {
  final Product product;
  final int quantity;
  
  CartItem({
    required this.product,
    required this.quantity,
  });
  
  double get totalPrice {
    return product.wholesalePrice * quantity;
  }
  
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }
}