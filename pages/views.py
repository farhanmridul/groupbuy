from django.shortcuts import render

def how_it_works(request):
    """How It Works page."""
    return render(request, 'pages/how_it_works.html')

def faq(request):
    """Frequently Asked Questions page."""
    return render(request, 'pages/faq.html')

def shipping_returns(request):
    """Shipping and Returns Policy page."""
    return render(request, 'pages/shipping_returns.html')

def privacy_policy(request):
    """Privacy Policy page."""
    return render(request, 'pages/privacy_policy.html')

def terms_conditions(request):
    """Terms and Conditions page."""
    return render(request, 'pages/terms_conditions.html')