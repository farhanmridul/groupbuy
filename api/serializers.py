from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password

from products.models import Product, Category, ProductImage, ProductBatch, Review
from orders.models import WaitlistItem, Cart, CartItem, Order, OrderItem, ShippingAddress, Payment
from accounts.models import User


class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'image', 'alt_text', 'is_featured']


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'description', 'image', 'is_active']


class ReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    
    class Meta:
        model = Review
        fields = ['id', 'user', 'user_name', 'title', 'content', 'rating', 'created_at']
        read_only_fields = ['user', 'created_at']
    
    def get_user_name(self, obj):
        return obj.user.get_full_name()


class ProductBatchSerializer(serializers.ModelSerializer):
    progress_percentage = serializers.SerializerMethodField()
    remaining_quantity = serializers.SerializerMethodField()
    
    class Meta:
        model = ProductBatch
        fields = [
            'id', 'product', 'batch_number', 'target_quantity', 'current_quantity',
            'is_active', 'is_fulfilled', 'created_at', 'fulfilled_at',
            'estimated_shipping_date', 'progress_percentage', 'remaining_quantity'
        ]
    
    def get_progress_percentage(self, obj):
        return obj.get_progress_percentage()
    
    def get_remaining_quantity(self, obj):
        return obj.get_remaining_quantity()


class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(),
        write_only=True,
        source='category'
    )
    images = ProductImageSerializer(many=True, read_only=True)
    reviews = ReviewSerializer(many=True, read_only=True)
    active_batch = serializers.SerializerMethodField()
    discount_percentage = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'title', 'slug', 'category', 'category_id', 'description',
            'market_price', 'wholesale_price', 'moq', 'stock', 'is_active',
            'created_at', 'updated_at', 'images', 'reviews', 'active_batch',
            'discount_percentage'
        ]
    
    def get_active_batch(self, obj):
        active_batch = ProductBatch.objects.filter(
            product=obj,
            is_active=True,
            is_fulfilled=False
        ).first()
        
        if active_batch:
            return ProductBatchSerializer(active_batch).data
        return None
    
    def get_discount_percentage(self, obj):
        return obj.get_discount_percentage()


class CartItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(),
        write_only=True,
        source='product'
    )
    total_price = serializers.SerializerMethodField()
    
    class Meta:
        model = CartItem
        fields = ['id', 'product', 'product_id', 'quantity', 'total_price']
    
    def get_total_price(self, obj):
        return obj.get_total_price()


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total_items = serializers.SerializerMethodField()
    total_price = serializers.SerializerMethodField()
    
    class Meta:
        model = Cart
        fields = ['id', 'user', 'items', 'total_items', 'total_price', 'created_at', 'updated_at']
        read_only_fields = ['user']
    
    def get_total_items(self, obj):
        return obj.get_total_items()
    
    def get_total_price(self, obj):
        return obj.get_total_price()


class ShippingAddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShippingAddress
        fields = [
            'id', 'user', 'name', 'address_line1', 'address_line2', 'city',
            'state', 'postal_code', 'country', 'phone', 'is_default'
        ]
        read_only_fields = ['user']


class OrderItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    batch = ProductBatchSerializer(read_only=True)
    total_price = serializers.SerializerMethodField()
    
    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'batch', 'price', 'quantity', 'total_price']
    
    def get_total_price(self, obj):
        return obj.get_total_price()


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = [
            'id', 'user', 'order', 'waitlist_item', 'payment_type',
            'payment_method', 'payment_id', 'amount', 'status',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'payment_id', 'created_at', 'updated_at']


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    shipping_address = ShippingAddressSerializer(read_only=True)
    shipping_address_id = serializers.PrimaryKeyRelatedField(
        queryset=ShippingAddress.objects.all(),
        write_only=True,
        source='shipping_address'
    )
    payments = PaymentSerializer(many=True, read_only=True)
    total_items = serializers.SerializerMethodField()
    
    class Meta:
        model = Order
        fields = [
            'id', 'user', 'order_number', 'status', 'payment_status',
            'shipping_address', 'shipping_address_id', 'shipping_method',
            'shipping_cost', 'subtotal', 'total', 'deposit_amount',
            'deposit_paid', 'payment_id', 'notes', 'created_at',
            'updated_at', 'estimated_delivery', 'items', 'payments',
            'total_items'
        ]
        read_only_fields = [
            'user', 'order_number', 'status', 'payment_status',
            'subtotal', 'total', 'deposit_amount', 'deposit_paid',
            'payment_id', 'created_at', 'updated_at'
        ]
    
    def get_total_items(self, obj):
        return obj.get_total_items()


class WaitlistItemSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    batch = ProductBatchSerializer(read_only=True)
    product = serializers.SerializerMethodField()
    
    class Meta:
        model = WaitlistItem
        fields = [
            'id', 'user', 'batch', 'product', 'quantity',
            'deposit_amount', 'deposit_paid', 'payment_id',
            'is_active', 'created_at', 'updated_at'
        ]
    
    def get_product(self, obj):
        return ProductSerializer(obj.batch.product).data


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = [
            'id', 'email', 'first_name', 'last_name', 'full_name',
            'phone', 'date_joined', 'is_active', 'is_staff'
        ]
        read_only_fields = ['id', 'email', 'date_joined', 'is_active', 'is_staff']
    
    def get_full_name(self, obj):
        return obj.get_full_name()


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True, write_only=True)
    remember_me = serializers.BooleanField(required=False, default=False)


class RegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)
    
    class Meta:
        model = User
        fields = ['email', 'password', 'password2', 'first_name', 'last_name', 'phone']
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs
    
    def create(self, validated_data):
        validated_data.pop('password2')
        user = User.objects.create_user(**validated_data)
        return user
