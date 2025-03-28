import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/routes.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({Key? key}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  bool _isAddingToCart = false;
  bool _isJoiningWaitlist = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to add items to your cart'),
          action: SnackBarAction(
            label: 'LOGIN',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.login);
            },
          ),
        ),
      );
      return;
    }
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final product = productProvider.selectedProduct;
    
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isAddingToCart = true;
    });
    
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.addItem(product, _quantity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} added to cart'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.cart);
              },
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Future<void> _joinWaitlist() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to join the waitlist'),
          action: SnackBarAction(
            label: 'LOGIN',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.login);
            },
          ),
        ),
      );
      return;
    }
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final product = productProvider.selectedProduct;
    
    if (product == null || product.activeBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No active batch available for this product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isJoiningWaitlist = true;
    });
    
    try {
      await productProvider.joinWaitlist(
        product.id,
        product.activeBatch!.id,
        _quantity,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined the waitlist'),
            action: SnackBarAction(
              label: 'VIEW WAITLIST',
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.waitlist);
              },
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining waitlist: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningWaitlist = false;
        });
      }
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (ctx, productProvider, _) {
        final product = productProvider.selectedProduct;
        
        if (product == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Product Details'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(product.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Implement sharing functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sharing coming soon!'),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.cart);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image carousel
                Stack(
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 300,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
                        enableInfiniteScroll: product.images.length > 1,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                      ),
                      items: product.images.isEmpty
                          ? [
                              Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ]
                          : product.images.map((image) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                    ),
                                    child: Image.network(
                                      image,
                                      fit: BoxFit.contain,
                                      errorBuilder: (ctx, error, stackTrace) {
                                        return Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey[400],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                    ),
                    
                    // Image indicator
                    if (product.images.length > 1)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: product.images.asMap().entries.map((entry) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedImageIndex == entry.key
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    
                    // Discount badge
                    if (product.discountPercentage > 0)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${product.discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Product info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Text(
                        product.category.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Title
                      const SizedBox(height: 8),
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Ratings
                      const SizedBox(height: 8),
                      if (product.reviewCount > 0)
                        Row(
                          children: [
                            RatingBar.builder(
                              initialRating: product.averageRating,
                              minRating: 0,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 16,
                              ignoreGestures: true,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {},
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      
                      // Price
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            '\$${product.wholesalePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${product.marketPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (product.discountPercentage > 0)
                            Text(
                              'You save ${product.discountPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      
                      // MOQ info
                      if (product.hasActiveBatch)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.groups,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Group Buy in Progress',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'MOQ: ${product.moq}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  Text(
                                    'Current: ${product.activeBatch!.currentQuantity}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  Text(
                                    'Remaining: ${product.activeBatch!.targetQuantity - product.activeBatch!.currentQuantity}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: product.batchProgress / 100,
                                  minHeight: 8,
                                  backgroundColor: Colors.blue[100],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    product.isMoqReached ? Colors.green : Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.isMoqReached
                                    ? 'MOQ has been reached! Order now to secure this wholesale price.'
                                    : 'Join this group buy with only a 5% deposit to secure your spot. You\'ll pay the remaining balance once MOQ is reached.',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                              if (product.activeBatch?.estimatedShippingDate != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Estimated Shipping: ${product.activeBatch!.estimatedShippingDate.toString().substring(0, 10)}',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      
                      // Quantity selector
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quantity:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _decrementQuantity,
                                icon: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(Icons.remove),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                onPressed: _incrementQuantity,
                                icon: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(Icons.add),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Add to cart button
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isAddingToCart ? null : _addToCart,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isAddingToCart
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('ADD TO CART'),
                        ),
                      ),
                      
                      // Join waitlist button
                      if (product.hasActiveBatch && !product.isMoqReached)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isJoiningWaitlist ? null : _joinWaitlist,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isJoiningWaitlist
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('JOIN WAITLIST (5% DEPOSIT)'),
                            ),
                          ),
                        ),

                      // Tabs
                      const SizedBox(height: 32),
                      TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: 'DESCRIPTION'),
                          Tab(text: 'REVIEWS'),
                          Tab(text: 'SHIPPING'),
                        ],
                      ),
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Description tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(product.description),
                            ),
                            
                            // Reviews tab
                            product.reviews.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No reviews yet',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            // TODO: Implement add review functionality
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Review functionality coming soon!'),
                                              ),
                                            );
                                          },
                                          child: const Text('Write a Review'),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: product.reviews.length,
                                    itemBuilder: (ctx, index) {
                                      final review = product.reviews[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    review.user.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    review.createdAt.toString().substring(0, 10),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  RatingBar.builder(
                                                    initialRating: review.rating.toDouble(),
                                                    minRating: 1,
                                                    direction: Axis.horizontal,
                                                    allowHalfRating: false,
                                                    itemCount: 5,
                                                    itemSize: 16,
                                                    ignoreGestures: true,
                                                    itemBuilder: (context, _) => const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                    ),
                                                    onRatingUpdate: (rating) {},
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    review.title,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(review.content),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            
                            // Shipping tab
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Shipping Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'This is a group buy product. Shipping will be initiated once the Minimum Order Quantity (MOQ) is reached.',
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Standard Shipping: \$4.99',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Delivery in 5-7 business days'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Express Shipping: \$9.99',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Delivery in 2-3 business days'),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Return Policy',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Returns are accepted within 30 days of delivery for products in their original condition. Please note that shipping costs are non-refundable.',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}