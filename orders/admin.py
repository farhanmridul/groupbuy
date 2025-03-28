from django.contrib import admin
from .models import WaitlistItem, Cart, CartItem, Order, OrderItem, ShippingAddress, Payment

class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ('product', 'price', 'quantity')

class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0

@admin.register(WaitlistItem)
class WaitlistItemAdmin(admin.ModelAdmin):
    list_display = ('user', 'batch', 'quantity', 'deposit_amount', 'deposit_paid', 'is_active', 'created_at')
    list_filter = ('deposit_paid', 'is_active', 'created_at')
    search_fields = ('user__email', 'batch__product__title')
    readonly_fields = ('created_at',)

@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ('user', 'get_total_items', 'get_total_price', 'created_at', 'updated_at')
    search_fields = ('user__email',)
    inlines = [CartItemInline]
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('order_number', 'user', 'status', 'payment_status', 'total', 'created_at')
    list_filter = ('status', 'payment_status', 'created_at')
    search_fields = ('order_number', 'user__email')
    readonly_fields = ('created_at', 'updated_at')
    inlines = [OrderItemInline]
    fieldsets = (
        (None, {
            'fields': ('order_number', 'user', 'status', 'payment_status')
        }),
        ('Shipping Information', {
            'fields': ('shipping_address', 'shipping_method', 'shipping_cost', 'estimated_delivery')
        }),
        ('Financial Details', {
            'fields': ('subtotal', 'total', 'deposit_amount', 'deposit_paid', 'payment_id')
        }),
        ('Additional Information', {
            'fields': ('notes', 'created_at', 'updated_at')
        }),
    )

@admin.register(ShippingAddress)
class ShippingAddressAdmin(admin.ModelAdmin):
    list_display = ('user', 'name', 'city', 'country', 'is_default')
    list_filter = ('is_default', 'country', 'city')
    search_fields = ('user__email', 'name', 'address_line1', 'city')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('payment_id', 'user', 'payment_type', 'amount', 'status', 'created_at')
    list_filter = ('payment_type', 'payment_method', 'status', 'created_at')
    search_fields = ('payment_id', 'user__email', 'order__order_number')
    readonly_fields = ('created_at', 'updated_at')
