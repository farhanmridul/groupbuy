from django.contrib import admin
from .models import Category, Product, ProductImage, ProductBatch, Review

class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 1

class ProductBatchInline(admin.TabularInline):
    model = ProductBatch
    extra = 1

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('name', 'description')
    prepopulated_fields = {'slug': ('name',)}

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('title', 'category', 'market_price', 'wholesale_price', 'moq', 'is_active')
    list_filter = ('is_active', 'category', 'created_at')
    search_fields = ('title', 'description')
    prepopulated_fields = {'slug': ('title',)}
    inlines = [ProductImageInline, ProductBatchInline]
    list_editable = ('is_active',)
    fieldsets = (
        (None, {
            'fields': ('title', 'slug', 'category', 'description')
        }),
        ('Pricing', {
            'fields': ('market_price', 'wholesale_price', 'moq')
        }),
        ('Inventory', {
            'fields': ('stock', 'is_active')
        }),
    )

@admin.register(ProductBatch)
class ProductBatchAdmin(admin.ModelAdmin):
    list_display = ('product', 'batch_number', 'target_quantity', 'current_quantity', 
                   'is_active', 'is_fulfilled', 'created_at')
    list_filter = ('is_active', 'is_fulfilled', 'created_at')
    search_fields = ('product__title',)
    readonly_fields = ('get_progress_percentage',)

@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ('product', 'user', 'rating', 'is_approved', 'created_at')
    list_filter = ('rating', 'is_approved', 'created_at')
    search_fields = ('product__title', 'user__email', 'content')
    list_editable = ('is_approved',)
    readonly_fields = ('created_at',)
