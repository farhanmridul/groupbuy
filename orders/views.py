from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.contrib import messages
from django.utils import timezone
from django.conf import settings
from django.db import transaction
from django.urls import reverse
from django.utils.crypto import get_random_string

import uuid
import json
from decimal import Decimal

from .models import Cart, CartItem, Order, OrderItem, ShippingAddress, Payment, WaitlistItem
from products.models import Product, ProductBatch
from accounts.forms import ShippingAddressForm


@login_required
def cart_view(request):
    """View shopping cart."""
    # Get or create user's cart
    cart, created = Cart.objects.get_or_create(user=request.user)
    
    context = {
        'cart': cart,
        'cart_items': cart.items.all(),
    }
    return render(request, 'orders/cart.html', context)


@login_required
def add_to_cart(request):
    """Add product to cart."""
    if request.method == 'POST':
        product_id = request.POST.get('product_id')
        quantity = int(request.POST.get('quantity', 1))

        # <-- NEW: Check for market price flag -->
        is_market_price = (request.POST.get('is_market_price') == 'true')
        
        if not product_id:
            return JsonResponse({'status': 'error', 'message': 'Product ID is required'})
        
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'Product not found'})
        
        # Get or create user's cart
        cart, created = Cart.objects.get_or_create(user=request.user)
        
        # Check if product is already in cart
        cart_item, item_created = CartItem.objects.get_or_create(
            cart=cart,
            product=product,
            defaults={'quantity': quantity, 'is_market_price': is_market_price}
        )
        
        if not item_created:
            # If the item already existed, update its quantity
            cart_item.quantity += quantity
            # Optionally update is_market_price if you want to override it
            # cart_item.is_market_price = is_market_price
            cart_item.save()
        
        return JsonResponse({
            'status': 'success',
            'message': f'{product.title} added to cart',
            'cart_total': cart.get_total_items()
        })
    
    return JsonResponse({'status': 'error', 'message': 'Invalid request'})


@login_required
def update_cart(request):
    """Update cart item quantity."""
    if request.method == 'POST':
        item_id = request.POST.get('item_id')
        quantity = int(request.POST.get('quantity', 1))
        
        if not item_id:
            return JsonResponse({'status': 'error', 'message': 'Item ID is required'})
        
        try:
            cart_item = CartItem.objects.get(id=item_id, cart__user=request.user)
        except CartItem.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'Cart item not found'})
        
        if quantity <= 0:
            cart_item.delete()
            message = 'Item removed from cart'
        else:
            cart_item.quantity = quantity
            cart_item.save()
            message = 'Cart updated'
        
        cart = cart_item.cart
        return JsonResponse({
            'status': 'success',
            'message': message,
            'cart_total': cart.get_total_items(),
            'item_total': cart_item.get_total_price() if quantity > 0 else 0,
            'cart_subtotal': cart.get_total_price()
        })
    
    return JsonResponse({'status': 'error', 'message': 'Invalid request'})


@login_required
def remove_from_cart(request, item_id):
    """Remove item from cart."""
    cart_item = get_object_or_404(CartItem, id=item_id, cart__user=request.user)
    cart_item.delete()
    messages.success(request, 'Item removed from cart')
    return redirect('cart')


@login_required
def checkout(request):
    """Checkout process."""
    # Get user's cart
    cart, created = Cart.objects.get_or_create(user=request.user)
    
    if cart.items.count() == 0:
        messages.warning(request, 'Your cart is empty')
        return redirect('cart')
    
    # Get user's shipping addresses
    shipping_addresses = ShippingAddress.objects.filter(user=request.user)
    default_address = shipping_addresses.filter(is_default=True).first()
    
    # Calculate deposit amount (5% of total)
    subtotal = cart.get_total_price()
    deposit_amount = subtotal * Decimal('0.05')
    
    # For simplicity, use fixed shipping cost
    shipping_cost = Decimal('10.00')
    total = subtotal + shipping_cost
    
    # Initialize shipping address form
    address_form = ShippingAddressForm()
    
    if request.method == 'POST':
        # Process checkout
        address_id = request.POST.get('address_id')
        
        # If user is adding a new address
        if address_id == 'new':
            address_form = ShippingAddressForm(request.POST)
            if address_form.is_valid():
                address = address_form.save(commit=False)
                address.user = request.user
                address.save()
                address_id = address.id
            else:
                # Form is invalid, show errors
                context = {
                    'cart': cart,
                    'cart_items': cart.items.all(),
                    'shipping_addresses': shipping_addresses,
                    'default_address': default_address,
                    'address_form': address_form,
                    'subtotal': subtotal,
                    'shipping_cost': shipping_cost,
                    'total': total,
                    'deposit_amount': deposit_amount,
                }
                return render(request, 'orders/checkout.html', context)
        
        # Get shipping address
        try:
            shipping_address = ShippingAddress.objects.get(id=address_id, user=request.user)
        except ShippingAddress.DoesNotExist:
            messages.error(request, 'Please select a valid shipping address')
            return redirect('checkout')
        
        # Create order
        with transaction.atomic():
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
                
                # If this cart item is a MARKET PRICE purchase:
                if cart_item.is_market_price:
                    # Create an OrderItem with MARKET PRICE (no batch/waitlist)
                    OrderItem.objects.create(
                        order=order,
                        product=product,
                        batch=None,  # no group-buy batch
                        price=product.market_price,
                        quantity=cart_item.quantity
                    )
                    
                    # We do NOT create a waitlist item for immediate purchases
                    # We also do not alter any batch or set any 'waiting_for_moq' status
                    # Because the user is buying outright at market price.
                
                else:
                    # Otherwise, it's a GROUP BUY purchase → use wholesale price + waitlist
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
                    
                    # Create order item with wholesale price
                    order_item = OrderItem.objects.create(
                        order=order,
                        product=product,
                        batch=active_batch,
                        price=product.wholesale_price,
                        quantity=cart_item.quantity
                    )
                    
                    # Create waitlist item for group-buy
                    WaitlistItem.objects.create(
                        user=request.user,
                        batch=active_batch,
                        quantity=cart_item.quantity,
                        deposit_amount=product.wholesale_price * Decimal('0.05') * cart_item.quantity
                    )
                    
                    # Update batch quantity
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
            
            # Redirect to payment page (simulate deposit payment in this demo)
            return redirect('order_confirmation', order_id=order.id)
    
    context = {
        'cart': cart,
        'cart_items': cart.items.all(),
        'shipping_addresses': shipping_addresses,
        'default_address': default_address,
        'address_form': address_form,
        'subtotal': subtotal,
        'shipping_cost': shipping_cost,
        'total': total,
        'deposit_amount': deposit_amount,
    }
    return render(request, 'orders/checkout.html', context)


@login_required
def order_confirmation(request, order_id):
    """Order confirmation page."""
    order = get_object_or_404(Order, id=order_id, user=request.user)
    
    # In a real app, this would integrate with a payment provider
    # For this demo, we'll simulate the payment status
    if request.method == 'POST':
        # Simulate successful deposit payment
        payment_id = f"PAY-{uuid.uuid4().hex[:12].upper()}"
        
        # Create payment record
        payment = Payment.objects.create(
            user=request.user,
            order=order,
            payment_type='deposit',
            payment_method='credit_card',
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
            # Only group-buy items have a batch & waitlist
            if item.batch:
                waitlist_item = WaitlistItem.objects.filter(
                    user=request.user,
                    batch=item.batch,
                    is_active=True
                ).first()
                
                if waitlist_item:
                    waitlist_item.deposit_paid = True
                    waitlist_item.payment_id = payment_id
                    waitlist_item.save()
        
        messages.success(request, 'Deposit payment successful! You have joined the waitlist.')
        return redirect('order_detail', order_id=order.id)
    
    context = {
        'order': order,
        'order_items': order.items.all(),
    }
    return render(request, 'orders/order_confirmation.html', context)


@login_required
def order_detail(request, order_id):
    """Order detail page."""
    order = get_object_or_404(Order, id=order_id, user=request.user)
    
    context = {
        'order': order,
        'order_items': order.items.all(),
    }
    return render(request, 'orders/order_detail.html', context)


@login_required
def order_list(request):
    """List user's orders."""
    orders = Order.objects.filter(user=request.user).order_by('-created_at')
    
    context = {
        'orders': orders,
    }
    return render(request, 'orders/order_list.html', context)


@login_required
def waitlist_items(request):
    """List user's waitlist items."""
    waitlist_items = WaitlistItem.objects.filter(
        user=request.user, 
        is_active=True
    ).select_related('batch', 'batch__product')
    
    context = {
        'waitlist_items': waitlist_items,
    }
    return render(request, 'orders/waitlist_items.html', context)
