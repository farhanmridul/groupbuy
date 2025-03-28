from django.urls import path, include
from rest_framework.routers import DefaultRouter

from . import views
from products.api import ProductViewSet, CategoryViewSet, ProductBatchViewSet, ReviewViewSet
from orders.api import CartViewSet, OrderViewSet, ShippingAddressViewSet, WaitlistItemViewSet
from accounts.api import UserViewSet, AuthViewSet

# Create a router and register our viewsets with it
router = DefaultRouter()
router.register(r'products', ProductViewSet, basename='product')
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'batches', ProductBatchViewSet, basename='batch')
router.register(r'reviews', ReviewViewSet, basename='review')
router.register(r'cart', CartViewSet, basename='cart')
router.register(r'orders', OrderViewSet, basename='order')
router.register(r'shipping-addresses', ShippingAddressViewSet, basename='shipping-address')
router.register(r'waitlist', WaitlistItemViewSet, basename='waitlist')
router.register(r'users', UserViewSet, basename='user')
router.register(r'auth', AuthViewSet, basename='auth')

# The API URLs are now determined automatically by the router
urlpatterns = [
    path('', views.api_root, name='api-root'),
    path('', include(router.urls)),
]
