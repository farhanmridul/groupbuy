import os
import django
import random
from decimal import Decimal
from datetime import datetime, timedelta

# Initialize Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'groupbuy_ecommerce.settings')
django.setup()

from django.contrib.auth import get_user_model
from products.models import Category, Product, ProductImage, ProductBatch, Review
from orders.models import Cart, CartItem, Order, OrderItem, ShippingAddress, WaitlistItem

User = get_user_model()

# Create categories
categories = [
    {'name': 'Electronics', 'description': 'Electronic gadgets and devices'},
    {'name': 'Home & Kitchen', 'description': 'Home appliances and kitchen essentials'},
    {'name': 'Fashion', 'description': 'Clothing and accessories'},
    {'name': 'Health & Beauty', 'description': 'Personal care and beauty products'},
]

for cat_data in categories:
    Category.objects.get_or_create(
        name=cat_data['name'],
        defaults={
            'description': cat_data['description'],
            'is_active': True
        }
    )

# Create products
products_data = [
    {
        'title': 'Wireless Earbuds',
        'category': 'Electronics',
        'description': 'High-quality wireless earbuds with noise cancellation',
        'market_price': '89.99',
        'wholesale_price': '49.99',
        'moq': 50,
        'stock': 100
    },
    {
        'title': 'Coffee Maker',
        'category': 'Home & Kitchen',
        'description': 'Programmable coffee maker with built-in grinder',
        'market_price': '129.99',
        'wholesale_price': '79.99',
        'moq': 30,
        'stock': 50
    },
    {
        'title': 'Leather Jacket',
        'category': 'Fashion',
        'description': 'Genuine leather jacket with quilted lining',
        'market_price': '199.99',
        'wholesale_price': '119.99',
        'moq': 20,
        'stock': 30
    },
    {
        'title': 'Skincare Set',
        'category': 'Health & Beauty',
        'description': 'Complete skincare set with cleanser, toner, and moisturizer',
        'market_price': '79.99',
        'wholesale_price': '44.99',
        'moq': 40,
        'stock': 60
    },
]

for product_data in products_data:
    category = Category.objects.get(name=product_data['category'])
    product, created = Product.objects.get_or_create(
        title=product_data['title'],
        defaults={
            'category': category,
            'description': product_data['description'],
            'market_price': Decimal(product_data['market_price']),
            'wholesale_price': Decimal(product_data['wholesale_price']),
            'moq': product_data['moq'],
            'stock': product_data['stock'],
            'is_active': True
        }
    )
    
    if created:
        # Create a sample product image
        ProductImage.objects.create(
            product=product,
            image='https://picsum.photos/seed/{}/400/300'.format(product.slug),
            is_featured=True
        )
        
        # Create a batch for this product
        batch = ProductBatch.objects.create(
            product=product,
            batch_number=1,
            target_quantity=product.moq,
            current_quantity=random.randint(5, product.moq - 1),
            is_active=True,
            estimated_shipping_date=datetime.now().date() + timedelta(days=30)
        )

# Create regular users
users_data = [
    {'email': 'customer1@example.com', 'first_name': 'John', 'last_name': 'Doe'},
    {'email': 'customer2@example.com', 'first_name': 'Jane', 'last_name': 'Smith'},
]

for user_data in users_data:
    user, created = User.objects.get_or_create(
        email=user_data['email'],
        defaults={
            'first_name': user_data['first_name'],
            'last_name': user_data['last_name'],
            'is_active': True
        }
    )
    
    if created:
        user.set_password('password123')
        user.save()
        
        # Create shipping address
        ShippingAddress.objects.create(
            user=user,
            name=f"{user.first_name} {user.last_name}",
            address_line1="123 Main Street",
            city="Anytown",
            state="State",
            postal_code="12345",
            country="Country",
            phone="123-456-7890",
            is_default=True
        )
        
        # Create cart
        cart, _ = Cart.objects.get_or_create(user=user)
        
        # Add random products to cart
        for product in Product.objects.order_by('?')[:2]:
            CartItem.objects.get_or_create(
                cart=cart,
                product=product,
                defaults={'quantity': random.randint(1, 3)}
            )
        
        # Add user to a waitlist
        product = Product.objects.order_by('?').first()
        batch = ProductBatch.objects.filter(product=product, is_active=True).first()
        if batch:
            WaitlistItem.objects.get_or_create(
                user=user,
                batch=batch,
                defaults={
                    'quantity': 1,
                    'deposit_amount': product.wholesale_price * Decimal('0.05'),
                    'deposit_paid': random.choice([True, False]),
                    'is_active': True
                }
            )

print("Sample data created successfully!")