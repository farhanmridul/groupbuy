from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404

from .models import Product, Category, ProductBatch, Review
from api.serializers import (
    ProductSerializer, CategorySerializer, 
    ProductBatchSerializer, ReviewSerializer
)
from orders.models import WaitlistItem


class ProductViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for products
    """
    queryset = Product.objects.filter(is_active=True)
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by category if provided
        category_slug = self.request.query_params.get('category')
        if category_slug:
            queryset = queryset.filter(category__slug=category_slug)
        
        # Filter by search term if provided
        search_term = self.request.query_params.get('search')
        if search_term:
            queryset = queryset.filter(title__icontains=search_term)
        
        # Sorting
        sort = self.request.query_params.get('sort', 'newest')
        if sort == 'price_low':
            queryset = queryset.order_by('wholesale_price')
        elif sort == 'price_high':
            queryset = queryset.order_by('-wholesale_price')
        elif sort == 'discount':
            # For simplicity, just sort by the price difference
            queryset = queryset.extra(
                select={'discount': 'market_price - wholesale_price'}
            ).order_by('-discount')
        else:  # default: newest
            queryset = queryset.order_by('-created_at')
        
        return queryset
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def join_waitlist(self, request, pk=None):
        """Join the waitlist for a product"""
        product = self.get_object()
        
        # Get active batch or return error
        active_batch = ProductBatch.objects.filter(
            product=product, 
            is_active=True, 
            is_fulfilled=False
        ).first()
        
        if not active_batch:
            return Response(
                {"detail": "No active batch available for this product."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user is already in the waitlist
        if WaitlistItem.objects.filter(
            user=request.user,
            batch=active_batch,
            is_active=True
        ).exists():
            return Response(
                {"detail": "You are already in the waitlist for this product."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create a waitlist item
        quantity = int(request.data.get('quantity', 1))
        WaitlistItem.objects.create(
            user=request.user,
            batch=active_batch,
            deposit_amount=product.wholesale_price * 0.05 * quantity,  # 5% deposit
            quantity=quantity
        )
        
        # Update batch current quantity
        active_batch.current_quantity += quantity
        
        # Check if MOQ is reached
        if active_batch.current_quantity >= active_batch.target_quantity:
            active_batch.is_fulfilled = True
            # In a real app, we would notify customers and process orders
        
        active_batch.save()
        
        return Response(
            {"detail": "You have successfully joined the waitlist for this product."},
            status=status.HTTP_201_CREATED
        )
    
    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def add_review(self, request, pk=None):
        """Add a review for a product"""
        product = self.get_object()
        
        # Check if user has already reviewed this product
        if Review.objects.filter(product=product, user=request.user).exists():
            return Response(
                {"detail": "You have already reviewed this product."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = ReviewSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(product=product, user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for categories
    """
    queryset = Category.objects.filter(is_active=True)
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]


class ProductBatchViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for product batches
    """
    queryset = ProductBatch.objects.filter(is_active=True)
    serializer_class = ProductBatchSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by product if provided
        product_id = self.request.query_params.get('product')
        if product_id:
            queryset = queryset.filter(product_id=product_id)
        
        # Filter by fulfilled status if provided
        is_fulfilled = self.request.query_params.get('fulfilled')
        if is_fulfilled is not None:
            is_fulfilled = is_fulfilled.lower() == 'true'
            queryset = queryset.filter(is_fulfilled=is_fulfilled)
        
        return queryset


class ReviewViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for reviews
    """
    queryset = Review.objects.filter(is_approved=True)
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by product if provided
        product_id = self.request.query_params.get('product')
        if product_id:
            queryset = queryset.filter(product_id=product_id)
        
        # Filter by user if provided
        user_id = self.request.query_params.get('user')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        
        return queryset
