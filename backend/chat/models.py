from typing import Any
from django.db import models
from django.contrib.auth.models import AbstractUser
from profanity.validators import validate_is_profane
from django.conf import settings
from .manager import CustomUserManager
from django.db.models.signals import post_save
from django.core.validators import MinLengthValidator
from django.utils import timezone
from django.dispatch import receiver
from django.db import transaction


class User(AbstractUser):
    first_name = models.CharField(max_length=150, verbose_name='Имя', validators=[
        MinLengthValidator(limit_value=1, message=("Имя не может быть пустым."))
    ])
    last_name = models.CharField(max_length=100, verbose_name='Фамилия', validators=[
    MinLengthValidator(limit_value=1, message=("Фамилия не может быть пустой."))
])
    middle_name = models.CharField(max_length=150, blank=True, verbose_name='Отчество')

    objects = CustomUserManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = []

    class Meta:
        verbose_name = 'Пользователь'
        verbose_name_plural = 'Пользователи'

    def __str__(self):
        return self.username

    def save(self, *args, **kwargs):
        self.first_name = self.first_name.capitalize()
        self.last_name = self.last_name.capitalize()
        self.middle_name = self.middle_name.capitalize()
        super().save(*args, **kwargs)

    
    
class UserProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    avatar = models.ImageField(upload_to ='user_photos/', default='user_photos/default.jpg', height_field=None, width_field=None)
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Время создания')
    updated_at = models.DateTimeField(auto_now=True, null=True, verbose_name='Время обновления')

    class Meta:
        verbose_name = 'Профиль пользователя'
        verbose_name_plural = 'Профили пользователей'

    def __str__(self):
        return str(self.user)
    
    
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        with transaction.atomic():  # Создаем профиль пользователя внутри транзакции
            UserProfile.objects.create(user=instance)

post_save.connect(create_user_profile, sender=User)

class Chat(models.Model):
    chat_id = models.AutoField(primary_key=True, verbose_name='ID чата')
    chat_name = models.CharField(max_length=50, unique=True, null=True, blank=True, verbose_name='Название')
    user_id = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, verbose_name='ID пользователя')
    avatar = models.ImageField(upload_to ='chat_photos/', default='chat_photos/default.jpg', null=True,
        blank=True, height_field=None, width_field=None, verbose_name='Аватар')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Время создания')
    updated_at = models.DateTimeField(auto_now=True, null=True, verbose_name='Время обновления')
    group_chat = models.BooleanField(default=False, verbose_name='Является ли групповым чатом')
    # TODO: add last read concept
    
    class Meta:
        verbose_name = 'Чат'
        verbose_name_plural = 'Чаты'


    def __str__(self):
        return self.chat_name
    

class ChatAdmins(models.Model):
    chat_id = models.ForeignKey(Chat, on_delete=models.CASCADE, verbose_name='ID чата')
    user_id = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, verbose_name='ID пользователя')
    joined_at = models.DateTimeField(auto_now_add=True, verbose_name='Время становления администратором')
    left_at = models.DateTimeField(null=True, blank=True, verbose_name='Время лишения прав администратора')

    class Meta:
        verbose_name = 'Администратор чата'
        verbose_name_plural = 'Администраторы чата'


    def __str__(self):
        return self.chat_id.chat_name + ' ' + self.user_id.username

    def save(self, *args, **kwargs):
        if not self.pk:
            self.left_at = None
        super().save(*args, **kwargs)
    

class ChatMembers(models.Model):
    chat_id = models.ForeignKey(Chat, on_delete=models.CASCADE, verbose_name='ID чата')
    user_id = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, verbose_name='ID пользователя')
    joined_at = models.DateTimeField(auto_now_add=True, verbose_name='Время присоединения')
    left_at = models.DateTimeField(null=True, blank=True, verbose_name='Время выхода из чата')

    class Meta:
        verbose_name = 'Участник чата'
        verbose_name_plural = 'Участники чата'

    def __str__(self):
        return self.chat_id.chat_name + ' ' + self.user_id.username
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.left_at = None
        super().save(*args, **kwargs)


class Message(models.Model):
    message_id = models.AutoField(primary_key=True, verbose_name='ID сообщения')
    sender_id = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='message', on_delete=models.CASCADE, verbose_name='ID отправителя')
    chat_id = models.ForeignKey(Chat, on_delete=models.CASCADE, verbose_name='ID чата')
    body = models.TextField( verbose_name='Содержание сообщения')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='Время создания')
    updated_at = models.DateTimeField(auto_now=True, null=True, verbose_name='Время обновления')
    #is_read = models.BooleanField(default=False)
    # TODO: add position concept

    class Meta:
        verbose_name = 'Сообщение'
        verbose_name_plural = 'Сообщения'

    def __str__(self):
        return self.chat_id.chat_name
    
    def __str__(self):
        return self.body

class Department(models.Model):
    department_id = models.AutoField(primary_key=True, verbose_name='ID подразделения')
    head_id = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, verbose_name='ID главы подразделения')
    department_name = models.CharField(max_length=255, unique=True, null=True, blank=True, verbose_name='Название')

    def __str__(self):
        return self.department_name

    class Meta:
        verbose_name = 'Подразделение'
        verbose_name_plural = 'Подразделения'

@receiver(post_save, sender=Department)
def create_department_employee(sender, instance, created, **kwargs):
    if created:
        head_id = instance.head_id
        department = instance
        role_name = "Начальник"

        # Получаем или создаем роль "Начальник"
        role, _ = Roles.objects.get_or_create(role_name=role_name)

        # Создаем запись DepartmentEmployee
        DepartmentEmployee.objects.create(
            department_id=department,
            user_id=head_id,
            role=role
        )

class Roles(models.Model):
    role_id = models.AutoField(primary_key=True, verbose_name='ID должности')
    # department_id = models.ForeignKey(Department, on_delete=models.CASCADE, verbose_name='ID подразделения')
    role_name = models.TextField(verbose_name='Должность', blank=True, unique=True)
    
    class Meta:
        verbose_name = 'Должность'
        verbose_name_plural = 'Должности'

    def __str__(self):
        return self.role_name


class DepartmentEmployee(models.Model):
    department_id = models.ForeignKey(Department, on_delete=models.CASCADE, verbose_name='ID подразделения')
    user_id = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, verbose_name='ID пользователя')
    role = models.ForeignKey(Roles, on_delete=models.CASCADE, verbose_name='ID должности', blank=True, null=True)
    joined_at = models.DateTimeField(auto_now_add=True, verbose_name='Время присоединения')
    left_at = models.DateTimeField(null=True, blank=True, verbose_name='Время выхода из подразделения')
    
    class Meta:
        verbose_name = 'Участник подразделения'
        verbose_name_plural = 'Участники подразделения'

    def __str__(self):
        return self.department_id.department_name + ' ' + self.user_id.username
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.left_at = None
        super().save(*args, **kwargs)


class ActionLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, verbose_name='ID пользователя')
    action_type = models.CharField(max_length=255, verbose_name='Тип действия')
    target_object_id = models.PositiveIntegerField(verbose_name='ID объекта действия')
    timestamp = models.DateTimeField(default=timezone.now)
    # action_data = models.JSONField(blank=True, null=True)

    def __str__(self):
        return f"{self.user} - {self.action_type} on {self.target_object_id}"

    class Meta:
        verbose_name = 'Журнал действий'
        verbose_name_plural = 'Журналы действий'
        

class Notification(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.message}"


