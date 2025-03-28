from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.utils.crypto import get_random_string
import uuid
from decimal import Decimal

from .models import (
    WaitlistItem, Cart, CartItem, Order, OrderItem, 
    ShippingAddress, Payment
)
from products.models import Product, ProductBatch
from api.serializers import (
    WaitlistItemSerializer, CartSerializer, CartItemSerializer,
    OrderSerializer, OrderItemSerializer, ShippingAddressSerializer,
    PaymentSerializer
)


class CartViewSet(viewsets.ModelViewSet):
    """
    API endpoint for user's cart
    """
    serializer_class = CartSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Cart.objects.filter(user=self.request.user)
    
    def get_object(self):
        """Get user's cart or create if it doesn't exist."""
        cart, created = Cart.objects.get_or_create(user=self.request.user)
        return cart
    
    @action(detail=False, methods=['post'])
    def add_item(self, request):
        """Add item to cart."""
        product_id = request.data.get('product_id')
        quantity = int(request.data.get('quantity', 1))
        
        if not product_id:
            return Response(
                {"detail": "Product ID is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response(
                {"detail": "Product not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        cart = self.get_object()
        
        # Check if product is already in cart
        cart_item, item_created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            defaults={'quantity': quantity}
        )
        
        if not item_created:
            cart_item.quantity += quantity
            cart_item.save()
        
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def update_item(self, request):
        """Update cart item quantity."""
        item_id = request.data.get('item_id')
        quantity = int(request.data.get('quantity', 1))
        
        if not item_id:
            return Response(
                {"detail": "Item ID is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            cart_item = CartItem.objects.get(id=item_id, cart__user=request.user)
        except CartItem.DoesNotExist:
            return Response(
                {"detail": "Cart item not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        if quantity <= 0:
            cart_item.delete()
        else:
            cart_item.quantity = quantity
            cart_item.save()
        
        cart = self.get_object()
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def remove_item(self, request):
        """Remove item from cart."""
        item_id = request.data.get('item_id')
        
        if not item_id:
            return Response(
                {"detail": "Item ID is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            cart_item = CartItem.objects.get(id=item_id, cart__user=request.user)
        except CartItem.DoesNotExist:
            return Response(
                {"detail": "Cart item not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        cart_item.delete()
        
        cart = self.get_object()
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    
    @action(detail=False, methods=['post'])
    def clear(self, request):
        """Clear all items from cart."""
        cart = self.get_object()
        cart.clear()
        
        serializer = CartSerializer(cart)
        return Response(serializer.data)


class ShippingAddressViewSet(viewsets.ModelViewSet):
    """
    API endpoint for user's shipping addresses
    """
    serializer_class = ShippingAddressSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return ShippingAddress.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    @action(detail=True, methods=['post'])
    def set_default(self, request, pk=None):
        """Set address as default."""
        address = self.get_object()
        address.is_default = True
        address.save()
        
        serializer = ShippingAddressSerializer(address)
        return Response(serializer.data)


class OrderViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for user's orders
    """
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Order.objects.filter(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def create_order(self, request):
        """Create new order from cart."""
        # Get user's cart
        try:
            cart = Cart.objects.get(user=request.user)
        except Cart.DoesNotExist:
            return Response(
                {"detail": "Cart not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        if cart.items.count() == 0:
            return Response(
                {"detail": "Your cart is empty."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get shipping address
        address_id = request.data.get('address_id')
        if not address_id:
            return Response(
                {"detail": "Shipping address ID is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            shipping_address = ShippingAddress.objects.get(id=address_id, user=request.user)
        except ShippingAddress.DoesNotExist:
            return Response(
                {"detail": "Shipping address not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Create order
        with transaction.atomic():
            # Calculate totals
            subtotal = cart.get_total_price()
            shipping_cost = Decimal('10.00')  # Fixed shipping cost for simplicity
            total = subtotal + shipping_cost
            deposit_amount = subtotal * Decimal('0.05')
            
            # Generate unique order number
            order_number = f"ORD-{get_random_string(8).upper()}"
            
            # Create order
            order = Order.objects.create(
                user=request.user,
                order_number=order_number,
                status='pending',
                payment_status='pending',
                shipping_address=shipping_address,
                shipping_cost=shipping_cost,
                subtotal=subtotal,
                total=total,
                deposit_amount=deposit_amount
            )
            
            # Create order items
            for cart_item in cart.items.all():
                product = cart_item.product
                
                # Get active batch or create new one
                active_batch = ProductBatch.objects.filter(
                    product=product,
                    is_active=True,
                    is_fulfilled=False
                ).first()
                
                if not active_batch:
                    # Create new batch if none exists
                    batch_count = ProductBatch.objects.filter(product=product).count()
                    active_batch = ProductBatch.objects.create(
                        product=product,
                        batch_number=batch_count + 1,
                        target_quantity=product.moq,
                        current_quantity=0,
                        is_active=True
                    )
                
                # Create order item
                order_item = OrderItem.objects.create(
                    order=order,
                    product=product,
                    batch=active_batch,
                    price=product.wholesale_price,
                    quantity=cart_item.quantity
                )
                
                # Create waitlist item for this product/batch
                waitlist_item = WaitlistItem.objects.create(
                    user=request.user,
                    batch=active_batch,
                    quantity=cart_item.quantity,
                    deposit_amount=product.wholesale_price * Decimal('0.05') * cart_item.quantity
                )
                
                # Update batch current quantity
                active_batch.current_quantity += cart_item.quantity
                
                # Check if MOQ is reached
                if active_batch.current_quantity >= active_batch.target_quantity:
                    active_batch.is_fulfilled = True
                    order.status = 'ready_to_ship'
                else:
                    order.status = 'waiting_for_moq'
                
                active_batch.save()
            
            order.save()
            
            # Clear cart after successful order
            cart.clear()
            
            serializer = OrderSerializer(order)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def process_payment(self, request, pk=None):
        """Process payment for order."""
        order = self.get_object()
        
        if order.deposit_paid:
            return Response(
                {"detail": "Deposit already paid for this order."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # In a real app, this would integrate with a payment provider
        # For this demo, we'll simulate a successful payment
        payment_id = f"PAY-{uuid.uuid4().hex[:12].upper()}"
        payment_method = request.data.get('payment_method', 'credit_card')
        
        # Create payment record
        payment = Payment.objects.create(
            user=request.user,
            order=order,
            payment_type='deposit',
            payment_method=payment_method,
            payment_id=payment_id,
            amount=order.deposit_amount,
            status='completed'
        )
        
        # Update order status
        order.deposit_paid = True
        order.payment_status = 'deposit_paid'
        order.payment_id = payment_id
        order.save()
        
        # Update waitlist items
        for item in OrderItem.objects.filter(order=order):
            waitlist_item = WaitlistItem.objects.filter(
                user=request.user,
                batch=item.batch,
                is_active=True
            ).first()
            
            if waitlist_item:
                waitlist_item.deposit_paid = True
                waitlist_item.payment_id = payment_id
                waitlist_item.save()
        
        serializer = OrderSerializer(order)
        return Response(serializer.data)


class WaitlistItemViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for user's waitlist items
    """
    serializer_class = WaitlistItemSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return WaitlistItem.objects.filter(user=self.request.user, is_active=True)
