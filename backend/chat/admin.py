from asyncio import format_helpers
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.db.models import Count
from .forms import CustomUserChangeForm, CustomUserCreationForm
from .models import *
from django.urls import reverse
from django.utils.http import urlencode
from django.contrib.auth import get_user_model
#from .models import User
User = get_user_model()


class CustomUserAdmin(UserAdmin):
    add_form = CustomUserCreationForm
    form = CustomUserChangeForm

    model = User

    list_display = ('username', 'email', 'first_name', 'last_name', 'middle_name', 'is_active',
                    'is_staff', 'is_superuser', 'last_login', )
    list_filter = ('is_active', 'is_staff', 'is_superuser')
    fieldsets = (
        (None, {'fields': ('username', 'email', 'first_name', 'last_name', 'middle_name', 'password')}),
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



admin.site.register(UserProfile)
admin.site.register(User, CustomUserAdmin)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ("chat_id", "sender_id", "body", 'created_at')


@admin.register(ChatMembers)
class ChatMembersAdmin(admin.ModelAdmin):
    list_display = ("chat_id", "user_id", 'joined_at', 'left_at')

    def group_chat(self, obj):
        return obj.group_chat
    
    group_chat.admin_order_field = 'group_chat'
    group_chat.boolean = True
    group_chat.short_description = 'Group Chat'

@admin.register(Chat)
class ChatAdmin(admin.ModelAdmin):
    list_display = ("chat_id", 'chat_name', 'user_id', 'group_chat', 'people_count', 'created_at', 'updated_at')
    
    def people_count(self, obj):
        return obj.chatmembers_set.count()
    
    