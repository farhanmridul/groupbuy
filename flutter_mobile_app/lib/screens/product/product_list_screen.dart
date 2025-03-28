import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/routes.dart';
import '../../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  final int? categoryId;
  
  const ProductListScreen({Key? key, this.categoryId}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _searchQuery;
  String _sortBy = 'newest';
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadProducts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      await productProvider.fetchProducts(
        category: widget.categoryId?.toString(),
        search: _searchQuery,
        page: _currentPage,
      );
      
      setState(() {
        _hasMoreData = productProvider.products.length >= 10; // Assuming 10 items per page
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final initialProductCount = productProvider.products.length;
      
      await productProvider.fetchProducts(
        category: widget.categoryId?.toString(),
        search: _searchQuery,
        page: _currentPage,
      );
      
      final newProductCount = productProvider.products.length;
      
      setState(() {
        _hasMoreData = newProductCount > initialProductCount;
      });
    } catch (error) {
      setState(() {
        _currentPage--; // Revert page increment
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more products: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearch(String? query) {
    setState(() {
      _searchQuery = query;
    });
    _loadProducts();
  }

  void _onSort(String value) {
    setState(() {
      _sortBy = value;
    });
    // TODO: Implement sorting
    _loadProducts();
  }

  void _openProductDetail(BuildContext context, Product product) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    // Set selected product before navigating
    await productProvider.fetchProductDetail(product.id);
    
    if (mounted) {
      Navigator.of(context).pushNamed(AppRoutes.productDetail);
    }
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      value: _sortBy,
      icon: const Icon(Icons.arrow_drop_down),
      items: [
        DropdownMenuItem(value: 'newest', child: Text('Newest')),
        DropdownMenuItem(value: 'price_low_high', child: Text('Price: Low to High')),
        DropdownMenuItem(value: 'price_high_low', child: Text('Price: High to Low')),
        DropdownMenuItem(value: 'discount', child: Text('Discount %')),
        DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
      ],
      onChanged: (value) {
        if (value != null) {
          _onSort(value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    
    final category = widget.categoryId != null 
        ? categoryProvider.findById(widget.categoryId!)
        : null;
    
    final screenTitle = category?.name ?? 'All Products';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _onSearch,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // TODO: Implement filters
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Filters coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.cart);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Sort by:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSortDropdown(),
                Spacer(),
                Text(
                  '${productProvider.products.length} products',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Product grid
          Expanded(
            child: _isLoading && productProvider.products.isEmpty
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : productProvider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery != null && _searchQuery!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Try a different search term',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _isLoadingMore
                            ? productProvider.products.length + 2
                            : productProvider.products.length,
                        itemBuilder: (ctx, index) {
                          if (index >= productProvider.products.length) {
                            return Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          
                          final product = productProvider.products[index];
                          
                          return GestureDetector(
                            onTap: () => _openProductDetail(context, product),
                            child: ProductCard(product: product),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}