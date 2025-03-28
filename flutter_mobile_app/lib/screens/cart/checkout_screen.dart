import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/shipping_address.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../utils/routes.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  bool _isProcessingOrder = false;
  ShippingAddress? _selectedAddress;
  String _selectedShippingMethod = 'standard';
  final Map<String, double> _shippingCosts = {
    'standard': 4.99,
    'express': 9.99,
  };
  final Map<String, String> _shippingMethods = {
    'standard': 'Standard Shipping (5-7 days)',
    'express': 'Express Shipping (2-3 days)',
  };
  final Map<String, String> _paymentMethods = {
    'credit_card': 'Credit/Debit Card',
    'paypal': 'PayPal',
  };
  String _selectedPaymentMethod = 'credit_card';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      await orderProvider.fetchShippingAddresses();
      
      if (orderProvider.addresses.isNotEmpty) {
        // Select default address or first address if no default exists
        final defaultAddress = orderProvider.addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => orderProvider.addresses.first,
        );
        
        setState(() {
          _selectedAddress = defaultAddress;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading addresses: ${error.toString()}'),
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

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shipping address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingOrder = true;
    });

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      final order = await orderProvider.createOrder(
        shippingAddressId: _selectedAddress!.id,
        shippingMethod: _selectedShippingMethod,
        paymentMethod: _selectedPaymentMethod,
      );
      
      // Clear cart after successful order creation
      await cartProvider.clear();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.orderConfirmation,
          arguments: order,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });
      }
    }
  }

  void _addNewAddress() async {
    // Navigate to add address screen and wait for result
    final result = await Navigator.of(context).pushNamed(AppRoutes.addAddress);
    if (result is ShippingAddress) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  double get _totalAmount {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return cartProvider.totalAmount + _shippingCosts[_selectedShippingMethod]!;
  }

  double get _depositAmount {
    // Calculate deposit as 5% of total
    return _totalAmount * 0.05;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<OrderProvider>(
              builder: (ctx, orderProvider, _) {
                return Consumer<CartProvider>(
                  builder: (ctx, cartProvider, _) {
                    if (cartProvider.items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                              },
                              child: const Text('Continue Shopping'),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order summary
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Summary',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  ...cartProvider.items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: item.product.images.isNotEmpty
                                                ? Image.network(
                                                    item.product.featuredImage,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (ctx, error, stackTrace) {
                                                      return Icon(
                                                        Icons.image_not_supported,
                                                        size: 20,
                                                        color: Colors.grey[400],
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    Icons.image,
                                                    size: 20,
                                                    color: Colors.grey[400],
                                                  ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.product.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'Qty: ${item.quantity}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '\$${item.totalPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal'),
                                      Text('\$${cartProvider.totalAmount.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Shipping'),
                                      Text('\$${_shippingCosts[_selectedShippingMethod]!.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '\$${_totalAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Due Now (5% Deposit)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        '\$${_depositAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Note: You\'ll only be charged the 5% deposit now. The remaining balance will be charged when the group buy reaches its minimum order quantity (MOQ).',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Shipping Address
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Shipping Address',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _addNewAddress,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add New'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (orderProvider.addresses.isEmpty)
                                    const Text(
                                      'No shipping addresses found. Please add a new address.',
                                      style: TextStyle(color: Colors.red),
                                    )
                                  else
                                    for (final address in orderProvider.addresses)
                                      RadioListTile<ShippingAddress>(
                                        value: address,
                                        groupValue: _selectedAddress,
                                        title: Text(
                                          address.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          '${address.addressLine1}, ${address.city}, ${address.state} ${address.postalCode}, ${address.country}',
                                        ),
                                        secondary: address.isDefault
                                            ? const Chip(
                                                label: Text(
                                                  'Default',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor: Colors.green,
                                              )
                                            : null,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedAddress = value;
                                          });
                                        },
                                      ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Shipping Method
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Shipping Method',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final entry in _shippingMethods.entries)
                                    RadioListTile<String>(
                                      value: entry.key,
                                      groupValue: _selectedShippingMethod,
                                      title: Text(entry.value),
                                      subtitle: Text('\$${_shippingCosts[entry.key]!.toStringAsFixed(2)}'),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedShippingMethod = value!;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Payment Method
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final entry in _paymentMethods.entries)
                                    RadioListTile<String>(
                                      value: entry.key,
                                      groupValue: _selectedPaymentMethod,
                                      title: Text(entry.value),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPaymentMethod = value!;
                                        });
                                      },
                                    ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Note: You\'ll be redirected to complete the payment after placing the order.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Place Order Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessingOrder ? null : _placeOrder,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isProcessingOrder
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'PAY \$${_depositAmount.toStringAsFixed(2)} DEPOSIT NOW',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}