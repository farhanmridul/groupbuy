from django.db import models
from django.utils import timezone
from accounts.models import User
from products.models import Product, ProductBatch


class WaitlistItem(models.Model):
    """Represents a customer's interest in a product batch."""
    user = models.ForeignKey(User, related_name='waitlist_items', on_delete=models.CASCADE)
    batch = models.ForeignKey(ProductBatch, related_name='waitlist_items', on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    deposit_amount = models.DecimalField(max_digits=10, decimal_places=2)
    deposit_paid = models.BooleanField(default=False)
    payment_id = models.CharField(max_length=100, blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ('-created_at',)
        unique_together = ('user', 'batch')

    def __str__(self):
        return f"{self.user.email} - {self.batch.product.title} - Batch #{self.batch.batch_number}"


class Cart(models.Model):
    """Shopping cart model."""
    user = models.OneToOneField(User, related_name='cart', on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Cart for {self.user.email}"

    def get_total_items(self):
        """Get total number of items in cart."""
        return sum(item.quantity for item in self.items.all())

    def get_total_price(self):
        """Get total price of all items in cart."""
        return sum(item.get_total_price() for item in self.items.all())

    def clear(self):
        """Clear all items from cart."""
        self.items.all().delete()
        self.save()


class CartItem(models.Model):
    """Shopping cart item model."""
    cart = models.ForeignKey(Cart, related_name='items', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name='cart_items', on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('cart', 'product')

    def __str__(self):
        return f"{self.product.title} ({self.quantity}) in cart for {self.cart.user.email}"

    def get_total_price(self):
        """Get total price for this cart item."""
        return self.product.wholesale_price * self.quantity


class Order(models.Model):
    """Order model representing a customer purchase."""
    ORDER_STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('waiting_for_moq', 'Waiting for MOQ'),
        ('ready_to_ship', 'Ready to Ship'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
        ('refunded', 'Refunded'),
    )
    
    PAYMENT_STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('deposit_paid', 'Deposit Paid'),
        ('full_payment', 'Full Payment'),
        ('refunded', 'Refunded'),
        ('failed', 'Failed'),
    )
    
    user = models.ForeignKey(User, related_name='orders', on_delete=models.CASCADE)
    order_number = models.CharField(max_length=20, unique=True)
    status = models.CharField(max_length=20, choices=ORDER_STATUS_CHOICES, default='pending')
    payment_status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='pending')
    shipping_address = models.ForeignKey('ShippingAddress', on_delete=models.SET_NULL, null=True, blank=True)
    shipping_method = models.CharField(max_length=100, blank=True)
    shipping_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    deposit_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    deposit_paid = models.BooleanField(default=False)
    payment_id = models.CharField(max_length=100, blank=True, null=True)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    estimated_delivery = models.DateField(null=True, blank=True)

    class Meta:
        ordering = ('-created_at',)

    def __str__(self):
        return f"Order {self.order_number} ({self.status})"

    def get_total_items(self):
        """Get total number of items in order."""
        return sum(item.quantity for item in self.items.all())

    def calculate_total(self):
        """Calculate order total including shipping."""
        self.subtotal = sum(item.get_total_price() for item in self.items.all())
        self.total = self.subtotal + self.shipping_cost
        self.save()


class OrderItem(models.Model):
    """Order item model representing a product in an order."""
    order = models.ForeignKey(Order, related_name='items', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name='order_items', on_delete=models.CASCADE)
    batch = models.ForeignKey(ProductBatch, related_name='order_items', on_delete=models.SET_NULL, null=True, blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)  # Price at the time of order
    quantity = models.PositiveIntegerField(default=1)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.product.title} ({self.quantity}) in Order {self.order.order_number}"

    def get_total_price(self):
        """Get total price for this order item."""
        return self.price * self.quantity


class ShippingAddress(models.Model):
    """Shipping address model."""
    user = models.ForeignKey(User, related_name='shipping_addresses', on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    address_line1 = models.CharField(max_length=255)
    address_line2 = models.CharField(max_length=255, blank=True)
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    postal_code = models.CharField(max_length=20)
    country = models.CharField(max_length=100)
    phone = models.CharField(max_length=20)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = 'Shipping Addresses'
        ordering = ('-is_default', '-created_at')

    def __str__(self):
        return f"Shipping Address for {self.user.email} - {self.name}"

    def save(self, *args, **kwargs):
        if self.is_default:
            # Set all other addresses of this user to non-default
            ShippingAddress.objects.filter(user=self.user, is_default=True).update(is_default=False)
        super().save(*args, **kwargs)


class Payment(models.Model):
    """Payment model."""
    PAYMENT_TYPE_CHOICES = (
        ('deposit', 'Deposit'),
        ('full', 'Full Payment'),
        ('refund', 'Refund'),
    )
    
    PAYMENT_METHOD_CHOICES = (
        ('credit_card', 'Credit Card'),
        ('paypal', 'PayPal'),
        ('bank_transfer', 'Bank Transfer'),
        ('other', 'Other'),
    )
    
    PAYMENT_STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    )
    
    user = models.ForeignKey(User, related_name='payments', on_delete=models.CASCADE)
    order = models.ForeignKey(Order, related_name='payments', on_delete=models.CASCADE, null=True, blank=True)
    waitlist_item = models.ForeignKey(WaitlistItem, related_name='payments', on_delete=models.CASCADE, null=True, blank=True)
    payment_type = models.CharField(max_length=20, choices=PAYMENT_TYPE_CHOICES)
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES)
    payment_id = models.CharField(max_length=100, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=PAYMENT_STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ('-created_at',)

    def __str__(self):
        if self.order:
            return f"Payment of {self.amount} for Order {self.order.order_number}"
        elif self.waitlist_item:
            return f"Deposit of {self.amount} for {self.waitlist_item.batch.product.title}"
        else:
            return f"Payment of {self.amount} by {self.user.email}"
class CartItem(models.Model):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name="items")
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    is_market_price = models.BooleanField(default=False)

    def get_total_price(self):
        """
        Returns the total cost for this CartItem using market_price
        if is_market_price is True, otherwise the product's wholesale_price.
        """
        if self.is_market_price:
            return self.product.market_price * self.quantity
        else:
            return self.product.wholesale_price * self.quantity

