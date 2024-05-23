from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .forms import CustomUserChangeForm, CustomUserCreationForm
from .models import *
from django.contrib.auth import get_user_model
from django import forms
from django.db.models import Q

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
    search_fields = ('email', 'username', 'first_name', 'last_name', 'middle_name')
    ordering = ('email',)

#admin.site.register(CustomUserChangeForm, CustomUserAdmin)


class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user_id', 'get_username')
    search_fields = ('user__username','user__email','user__first_name', 'user__last_name', 'user__middle_name')

    def get_username(self, obj):
        return obj.user.username
    
    get_username.short_description = 'Username'
    
admin.site.register(UserProfile, UserProfileAdmin)

admin.site.register(User, CustomUserAdmin)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ("chat_id", "sender_id", "body", 'created_at')
    search_fields = ('chat_id__chat_name', 'sender_id__username')


@admin.register(ChatMembers)
class ChatMembersAdmin(admin.ModelAdmin):
    list_display = ("chat_id", "user_id", 'joined_at', 'left_at')
    search_fields = ('chat_id__chat_name', 'user_id__username')
    list_filter = ('chat_id', 'user_id')

    def group_chat(self, obj):
        return obj.group_chat
    
    group_chat.admin_order_field = 'group_chat'
    group_chat.boolean = True
    group_chat.short_description = 'Group Chat'


class ChatAdminsForm(forms.ModelForm):
    class Meta:
        model = ChatAdmins
        fields = '__all__'

    def __init__(self, *args, **kwargs):
        super(ChatAdminsForm, self).__init__(*args, **kwargs)
        if 'instance' in kwargs and kwargs['instance']:
            chat_id = kwargs['instance'].chat_id_id
            self.fields['user_id'].queryset = get_user_model().objects.filter(
                Q(chatmembers__chat_id=chat_id) | Q(chatadmins__chat_id=chat_id)
            ).distinct()

class ChatAdminsAdmin(admin.ModelAdmin):
    list_display = ("chat_id", "user_id", 'joined_at', 'left_at')
    search_fields = ('chat_id__chat_name', 'user_id__username')
    list_filter = ('chat_id', 'user_id')
    form = ChatAdminsForm

    def group_chat(self, obj):
        return obj.group_chat
    
    group_chat.admin_order_field = 'group_chat'
    group_chat.boolean = True
    group_chat.short_description = 'Group Chat'

admin.site.register(ChatAdmins, ChatAdminsAdmin)
    

@admin.register(Chat)
class ChatAdmin(admin.ModelAdmin):
    list_display = ("chat_id", 'chat_name', 'user_id', 'group_chat', 'people_count', 'created_at', 'updated_at')
    search_fields = ('chat_name', 'user_id__username')
    list_filter = ('user_id', 'group_chat')

    def people_count(self, obj):
        return obj.chatmembers_set.filter(left_at__isnull=True).count()
    
@admin.register(ActionLog)
class ActionLogAdmin(admin.ModelAdmin):
    list_display = ['timestamp', 'user', 'action_type', 'target_object_id']
    search_fields = ['user__username', 'action_type', 'target_object_id']
    list_filter = ['action_type', 'user', 'target_object_id']

@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ('department_id', 'head_id', 'department_name')
    search_fields = ('department_name', 'head_id__username')
    list_filter = ('head_id',)

@admin.register(Roles)
class RolesAdmin(admin.ModelAdmin):
    list_display = ('role_id', 'role_name')
    search_fields = ('role_name',)
    list_filter = ('role_name',)

@admin.register(DepartmentEmployee)
class DepartmentEmployeeAdmin(admin.ModelAdmin):
    list_display = ('department_id', 'user_id', 'get_role_name', 'joined_at', 'left_at')
    search_fields = ('department_id__department_name', 'user_id__username', 'role__role_name')
    list_filter = ('department_id', 'user_id', 'role')
    
    def get_role_name(self, obj):
        return obj.role.role_name if obj.role else None

    get_role_name.short_description = 'Должность'
    

    
    