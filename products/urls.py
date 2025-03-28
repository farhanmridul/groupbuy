from django.urls import path
from . import views

urlpatterns = [
    path('', views.product_list, name='product_list'),
    path('category/', views.category_list, name='category_list'),
    path('product/<slug:slug>/', views.product_detail, name='product_detail'),
    path('join-waitlist/<int:product_id>/', views.join_waitlist, name='join_waitlist'),
    path('add-review/<int:product_id>/', views.add_review, name='add_review'),
    path('batch-status/<int:batch_id>/', views.get_batch_status, name='get_batch_status'),
]
