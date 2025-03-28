"""
Context processors for Products app.
These make additional variables available to all templates.
"""
from .models import Category

def categories(request):
    """
    Add active categories to the template context for site-wide navigation.
    """
    return {
        'categories': Category.objects.filter(is_active=True)
    }