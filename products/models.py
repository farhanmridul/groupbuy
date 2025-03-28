from django.db import models
from django.urls import reverse
from django.utils.text import slugify
from django.core.validators import MinValueValidator
from accounts.models import User


class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    image = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = 'Categories'
        ordering = ('name',)

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def get_absolute_url(self):
        return reverse('category_detail', args=[self.slug])


class ProductImage(models.Model):
    product = models.ForeignKey('Product', related_name='images', on_delete=models.CASCADE)
    image = models.URLField()
    alt_text = models.CharField(max_length=255, blank=True)
    is_featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ('-is_featured', 'created_at')

    def __str__(self):
        return f"Image for {self.product.title}"


class Product(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True)
    category = models.ForeignKey(Category, related_name='products', on_delete=models.CASCADE)
    description = models.TextField()
    market_price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    wholesale_price = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(0)])
    moq = models.PositiveIntegerField(help_text="Minimum Order Quantity")
    stock = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ('-created_at',)

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
        super().save(*args, **kwargs)

    def get_absolute_url(self):
        return reverse('product_detail', args=[self.slug])

    def get_discount_percentage(self):
        """Calculate the discount percentage."""
        if self.market_price == 0:
            return 0
        return int(((self.market_price - self.wholesale_price) / self.market_price) * 100)


class ProductBatch(models.Model):
    product = models.ForeignKey(Product, related_name='batches', on_delete=models.CASCADE)
    batch_number = models.PositiveIntegerField()
    target_quantity = models.PositiveIntegerField(help_text="MOQ for this batch")
    current_quantity = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    is_fulfilled = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    fulfilled_at = models.DateTimeField(null=True, blank=True)
    estimated_shipping_date = models.DateField(null=True, blank=True)

    class Meta:
        verbose_name_plural = 'Product Batches'
        ordering = ('product', '-batch_number')
        unique_together = ('product', 'batch_number')

    def __str__(self):
        return f"{self.product.title} - Batch #{self.batch_number}"

    def get_progress_percentage(self):
        """Calculate the progress towards MOQ."""
        if self.target_quantity == 0:
            return 100
        return int((self.current_quantity / self.target_quantity) * 100)

    def get_remaining_quantity(self):
        """Calculate remaining quantity needed to fulfill MOQ."""
        remaining = self.target_quantity - self.current_quantity
        return max(0, remaining)

    def is_moq_reached(self):
        """Check if MOQ has been reached."""
        return self.current_quantity >= self.target_quantity


class Review(models.Model):
    RATING_CHOICES = (
        (1, '1 - Poor'),
        (2, '2 - Fair'),
        (3, '3 - Good'),
        (4, '4 - Very Good'),
        (5, '5 - Excellent')
    )
    
    product = models.ForeignKey(Product, related_name='reviews', on_delete=models.CASCADE)
    user = models.ForeignKey(User, related_name='reviews', on_delete=models.CASCADE)
    title = models.CharField(max_length=100)
    content = models.TextField()
    rating = models.PositiveSmallIntegerField(choices=RATING_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_approved = models.BooleanField(default=False)

    class Meta:
        ordering = ('-created_at',)
        unique_together = ('product', 'user')

    def __str__(self):
        return f"{self.product.title} - {self.rating} stars"
