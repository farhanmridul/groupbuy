from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login, authenticate, logout
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib import messages
from django.views.decorators.http import require_POST
from django.http import JsonResponse
from django.urls import reverse

from .forms import LoginForm, RegistrationForm, ProfileUpdateForm, ShippingAddressForm
from .models import User, StaffProfile
from orders.models import Order, WaitlistItem, ShippingAddress


def login_view(request):
    """User login page."""
    if request.user.is_authenticated:
        return redirect('home')
    
    if request.method == 'POST':
        form = LoginForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            password = form.cleaned_data['password']
            remember_me = form.cleaned_data['remember_me']
            
            user = authenticate(request, email=email, password=password)
            if user is not None:
                login(request, user)
                
                # Set session expiry based on remember_me
                if not remember_me:
                    request.session.set_expiry(0)  # Session expires when browser closes
                
                # Redirect to next page if provided, otherwise dashboard
                next_page = request.GET.get('next')
                if next_page:
                    return redirect(next_page)
                return redirect('dashboard')
            else:
                form.add_error(None, 'Invalid email or password.')
    else:
        form = LoginForm()
    
    return render(request, 'accounts/login.html', {'form': form})


def register_view(request):
    """User registration page."""
    if request.user.is_authenticated:
        return redirect('home')
    
    if request.method == 'POST':
        form = RegistrationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            messages.success(request, 'Account created successfully!')
            return redirect('dashboard')
    else:
        form = RegistrationForm()
    
    return render(request, 'accounts/register.html', {'form': form})


def logout_view(request):
    """Logout user."""
    logout(request)
    return redirect('home')


@login_required
def dashboard(request):
    """User dashboard."""
    # Get recent orders
    recent_orders = Order.objects.filter(user=request.user).order_by('-created_at')[:5]
    
    # Get active waitlist items
    active_waitlist = WaitlistItem.objects.filter(
        user=request.user, 
        is_active=True
    ).select_related('batch', 'batch__product')[:5]
    
    # Count total orders
    total_orders = Order.objects.filter(user=request.user).count()
    
    context = {
        'recent_orders': recent_orders,
        'active_waitlist': active_waitlist,
        'total_orders': total_orders,
    }
    return render(request, 'accounts/dashboard.html', context)


@login_required
def profile(request):
    """User profile page."""
    if request.method == 'POST':
        form = ProfileUpdateForm(request.POST, instance=request.user)
        if form.is_valid():
            form.save()
            messages.success(request, 'Profile updated successfully!')
            return redirect('profile')
    else:
        form = ProfileUpdateForm(instance=request.user)
    
    context = {
        'form': form,
    }
    return render(request, 'accounts/profile.html', context)


@login_required
def addresses(request):
    """User shipping addresses."""
    addresses = ShippingAddress.objects.filter(user=request.user).order_by('-is_default')
    
    if request.method == 'POST':
        form = ShippingAddressForm(request.POST)
        if form.is_valid():
            address = form.save(commit=False)
            address.user = request.user
            address.save()
            messages.success(request, 'Address added successfully!')
            return redirect('addresses')
    else:
        form = ShippingAddressForm()
    
    context = {
        'addresses': addresses,
        'form': form,
    }
    return render(request, 'accounts/addresses.html', context)


@login_required
@require_POST
def set_default_address(request, address_id):
    """Set an address as the default."""
    address = get_object_or_404(ShippingAddress, id=address_id, user=request.user)
    address.is_default = True
    address.save()
    
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return JsonResponse({'status': 'success'})
    
    messages.success(request, 'Default address updated!')
    return redirect('addresses')


@login_required
def delete_address(request, address_id):
    """Delete a shipping address."""
    address = get_object_or_404(ShippingAddress, id=address_id, user=request.user)
    address.delete()
    
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return JsonResponse({'status': 'success'})
    
    messages.success(request, 'Address deleted successfully!')
    return redirect('addresses')


# Staff views
def is_staff(user):
    """Check if user is staff."""
    return user.is_staff

@user_passes_test(is_staff)
def staff_dashboard(request):
    """Staff dashboard."""
    # Count total orders, pending orders, fulfilled MOQs
    total_orders = Order.objects.count()
    pending_orders = Order.objects.filter(status='pending').count()
    moq_waiting = Order.objects.filter(status='waiting_for_moq').count()
    
    context = {
        'total_orders': total_orders,
        'pending_orders': pending_orders,
        'moq_waiting': moq_waiting,
    }
    return render(request, 'accounts/staff_dashboard.html', context)
