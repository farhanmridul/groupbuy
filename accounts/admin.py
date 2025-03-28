from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _

from .models import User, StaffProfile


class StaffProfileInline(admin.StackedInline):
    model = StaffProfile
    can_delete = False
    verbose_name_plural = 'Staff Profile'
    fk_name = 'user'


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """Admin configuration for custom User model."""
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'phone')}),
        (_('Permissions'), {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'is_customer', 'groups', 'user_permissions'),
        }),
        (_('Important dates'), {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'first_name', 'last_name'),
        }),
    )
    list_display = ('email', 'first_name', 'last_name', 'is_staff')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)
    inlines = [StaffProfileInline]
    
    def get_inlines(self, request, obj=None):
        if obj and obj.is_staff:
            return self.inlines
        return []


@admin.register(StaffProfile)
class StaffProfileAdmin(admin.ModelAdmin):
    """Admin configuration for StaffProfile model."""
    list_display = ('user', 'role', 'department', 'can_manage_products', 'can_manage_orders')
    list_filter = ('role', 'can_manage_products', 'can_manage_orders', 'can_manage_users')
    search_fields = ('user__email', 'user__first_name', 'user__last_name', 'department')
    fieldsets = (
        (None, {'fields': ('user', 'role', 'department', 'bio')}),
        ('Permissions', {
            'fields': ('can_manage_products', 'can_manage_orders', 'can_manage_users', 
                      'can_manage_staff', 'can_view_reports'),
        }),
    )
