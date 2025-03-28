from django.http import Http404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAdminUser, AllowAny


@api_view(['GET'])
@permission_classes([AllowAny])
def api_root(request):
    """
    API root with endpoint documentation
    """
    return Response({
        'status': 'API is running',
        'version': '1.0',
        'documentation': {
            'auth': {
                'login': '/api/auth/login/',
                'register': '/api/auth/register/',
                'logout': '/api/auth/logout/',
                'current_user': '/api/auth/user/',
            },
            'products': {
                'list': '/api/products/',
                'detail': '/api/products/{id}/',
                'join_waitlist': '/api/products/{id}/join_waitlist/',
                'add_review': '/api/products/{id}/add_review/',
            },
            'categories': {
                'list': '/api/categories/',
                'detail': '/api/categories/{id}/',
            },
            'batches': {
                'list': '/api/batches/',
                'detail': '/api/batches/{id}/',
            },
            'cart': {
                'detail': '/api/cart/',
                'add_item': '/api/cart/add_item/',
                'update_item': '/api/cart/update_item/',
                'remove_item': '/api/cart/remove_item/',
                'clear': '/api/cart/clear/',
            },
            'orders': {
                'list': '/api/orders/',
                'detail': '/api/orders/{id}/',
                'create_order': '/api/orders/create_order/',
                'process_payment': '/api/orders/{id}/process_payment/',
            },
            'shipping_addresses': {
                'list': '/api/shipping-addresses/',
                'detail': '/api/shipping-addresses/{id}/',
                'set_default': '/api/shipping-addresses/{id}/set_default/',
            },
            'waitlist': {
                'list': '/api/waitlist/',
                'detail': '/api/waitlist/{id}/',
            },
        }
    })
