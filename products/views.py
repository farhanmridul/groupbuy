from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.db.models import Avg, Count
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.views.decorators.http import require_POST
from django.contrib import messages

from .models import Product, Category, ProductBatch, Review
from .forms import ReviewForm
from orders.models import WaitlistItem
from decimal import Decimal

def home_view(request):
    """Home page view."""
    featured_products = Product.objects.filter(is_active=True).order_by('-created_at')[:8]
    active_batches = ProductBatch.objects.filter(is_active=True, is_fulfilled=False).order_by('?')[:4]
    
    # Get products with most waitlist entries
    trending_products = Product.objects.annotate(
        waitlist_count=Count('batches__waitlist_items')
    ).filter(is_active=True).order_by('-waitlist_count')[:4]
    
    context = {
        'featured_products': featured_products,
        'active_batches': active_batches,
        'trending_products': trending_products,
    }
    return render(request, 'home.html', context)

def product_list(request):
    """Product listing page."""
    products = Product.objects.filter(is_active=True)
    
    # Filter by category if provided
    category_slug = request.GET.get('category')
    if category_slug:
        category = get_object_or_404(Category, slug=category_slug)
        products = products.filter(category=category)
    
    # Filter by search term if provided
    search_term = request.GET.get('search')
    if search_term:
        products = products.filter(title__icontains=search_term)
    
    # Sorting
    sort = request.GET.get('sort', 'newest')
    if sort == 'price_low':
        products = products.order_by('wholesale_price')
    elif sort == 'price_high':
        products = products.order_by('-wholesale_price')
    elif sort == 'discount':
        # This is a bit tricky with Django ORM, we'd ideally calculate in the DB
        # For simplicity, we'll sort in memory
        products = sorted(
            products,
            key=lambda p: ((p.market_price - p.wholesale_price) / p.market_price if p.market_price else 0),
            reverse=True
        )
    else:  # default: newest
        products = products.order_by('-created_at')
    
    # Pagination
    paginator = Paginator(products, 12)
    page = request.GET.get('page')
    products = paginator.get_page(page)
    
    context = {
        'products': products,
        'sort': sort,
        'search_term': search_term,
    }
    return render(request, 'products/product_list.html', context)

def product_detail(request, slug):
    """Product detail page."""
    product = get_object_or_404(Product, slug=slug, is_active=True)
    
    # Get active batch or create a new one if none exists
    active_batch = ProductBatch.objects.filter(
        product=product, 
        is_active=True, 
        is_fulfilled=False
    ).first()
    
    # If no active batch, we'd create one in a real app
    # For this demo, just show a placeholder
    if not active_batch:
        active_batch = {
            "batch_number": 1,
            "target_quantity": product.moq,
            "current_quantity": 0,
            "get_progress_percentage": lambda: 0,
            "get_remaining_quantity": lambda: product.moq
        }
    
    # Get user's waitlist status for this product
    user_in_waitlist = False
    if request.user.is_authenticated:
        user_in_waitlist = WaitlistItem.objects.filter(
            user=request.user,
            batch__product=product,
            is_active=True
        ).exists()
    
    # Related products
    related_products = Product.objects.filter(
        category=product.category, 
        is_active=True
    ).exclude(id=product.id)[:4]
    
    # Reviews
    reviews = product.reviews.filter(is_approved=True).select_related('user')
    avg_rating = reviews.aggregate(Avg('rating'))['rating__avg'] or 0
    
    # Review form for logged-in users
    review_form = None
    user_has_reviewed = False
    
    if request.user.is_authenticated:
        user_has_reviewed = reviews.filter(user=request.user).exists()
        if not user_has_reviewed:
            review_form = ReviewForm()
    
    context = {
        'product': product,
        'active_batch': active_batch,
        'user_in_waitlist': user_in_waitlist,
        'related_products': related_products,
        'reviews': reviews,
        'avg_rating': avg_rating,
        'review_form': review_form,
        'user_has_reviewed': user_has_reviewed,
    }
    return render(request, 'products/product_detail.html', context)

def category_list(request):
    """List all product categories."""
    categories = Category.objects.filter(is_active=True)
    context = {'categories': categories}
    return render(request, 'products/category_list.html', context)

@login_required
@require_POST
def add_review(request, product_id):
    """Add a product review."""
    product = get_object_or_404(Product, id=product_id, is_active=True)
    
    # Check if user has already reviewed this product
    if Review.objects.filter(product=product, user=request.user).exists():
        messages.error(request, "You have already reviewed this product.")
        return redirect(product.get_absolute_url())
    
    form = ReviewForm(request.POST)
    if form.is_valid():
        review = form.save(commit=False)
        review.product = product
        review.user = request.user
        review.save()
        messages.success(request, "Your review has been submitted and is pending approval.")
    else:
        messages.error(request, "There was an error with your review. Please try again.")
    
    return redirect(product.get_absolute_url())

@login_required


def join_waitlist(request, product_id):
    """Add user to product waitlist."""
    product = get_object_or_404(Product, id=product_id, is_active=True)
    
    # Get active batch or return error
    active_batch = ProductBatch.objects.filter(
        product=product, 
        is_active=True, 
        is_fulfilled=False
    ).first()
    
    if not active_batch:
        messages.error(request, "No active batch available for this product.")
        return redirect(product.get_absolute_url())
    
    # Check if user is already in the waitlist
    if WaitlistItem.objects.filter(
        user=request.user,
        batch=active_batch,
        is_active=True
    ).exists():
        messages.info(request, "You are already in the waitlist for this product.")
        return redirect(product.get_absolute_url())
    
    # Create a waitlist item - in a real app, this would redirect to payment
    # For this demo, we'll just add them directly
    WaitlistItem.objects.create(
        user=request.user,
        batch=active_batch,
        deposit_amount=product.wholesale_price * Decimal('0.05'),  # 5% deposit
        quantity=1  # Default to 1 for simplicity
    )
    
    # Update batch current quantity
    active_batch.current_quantity += 1
    
    # Check if MOQ is reached
    if active_batch.current_quantity >= active_batch.target_quantity:
        active_batch.is_fulfilled = True
        # In a real app, we would notify customers and process orders
    
    active_batch.save()
    
    messages.success(request, "You have successfully joined the waitlist for this product.")
    return redirect(product.get_absolute_url())

def get_batch_status(request, batch_id):
    """AJAX endpoint to get current batch status."""
    batch = get_object_or_404(ProductBatch, id=batch_id)
    
    data = {
        'current_quantity': batch.current_quantity,
        'target_quantity': batch.target_quantity,
        'progress_percentage': batch.get_progress_percentage(),
        'remaining_quantity': batch.get_remaining_quantity(),
        'is_fulfilled': batch.is_fulfilled
    }
    
    return JsonResponse(data)
