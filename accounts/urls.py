from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('register/', views.register_view, name='register'),
    path('logout/', views.logout_view, name='logout'),
    path('dashboard/', views.dashboard, name='dashboard'),
    path('profile/', views.profile, name='profile'),
    path('addresses/', views.addresses, name='addresses'),
    path('addresses/set-default/<int:address_id>/', views.set_default_address, name='set_default_address'),
    path('addresses/delete/<int:address_id>/', views.delete_address, name='delete_address'),
    path('staff/', views.staff_dashboard, name='staff_dashboard'),
]
