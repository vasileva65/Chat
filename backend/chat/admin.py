from asyncio import format_helpers
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.db.models import Count
from .forms import CustomUserChangeForm, CustomUserCreationForm
from .models import *
from django.urls import reverse
from django.utils.http import urlencode
from django.contrib.auth import get_user_model
User = get_user_model()


class CustomUserAdmin(UserAdmin):
    add_form = CustomUserCreationForm
    form = CustomUserChangeForm

    model = User

    list_display = ('username', 'email', 'is_active',
                    'is_staff', 'is_superuser', 'last_login',)
    list_filter = ('is_active', 'is_staff', 'is_superuser')
    fieldsets = (
        (None, {'fields': ('username', 'email', 'password')}),
        ('Permissions', {'fields': ('is_staff', 'is_active',
         'is_superuser', 'groups', 'user_permissions')}),
        ('Dates', {'fields': ('last_login', 'date_joined')})
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'first_name', 'last_name', 'middle_name', 'password1', 'password2', 'is_staff', 'is_active')}
         ),
    )
    search_fields = ('email',)
    ordering = ('email',)

#admin.site.register(CustomUserChangeForm, CustomUserAdmin)


admin.site.register(Chat)
admin.site.register(UserProfile)
admin.site.register(User, CustomUserAdmin)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ("chat_id", "sender_id", "body")


@admin.register(ChatMembers)
class ChatMembersAdmin(admin.ModelAdmin):
    list_display = ("chat_id", "user_id")
