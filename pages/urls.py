from django.urls import path
from . import views

app_name = 'pages'

urlpatterns = [
    path('how-it-works/', views.how_it_works, name='how_it_works'),
    path('faq/', views.faq, name='faq'),
    path('shipping-returns/', views.shipping_returns, name='shipping_returns'),
    path('privacy-policy/', views.privacy_policy, name='privacy_policy'),
    path('terms-conditions/', views.terms_conditions, name='terms_conditions'),
]