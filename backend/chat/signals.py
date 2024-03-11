# В файле signals.py вашего приложения
from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver
from .models import Chat, ChatAdmins, ChatMembers, User, ActionLog

@receiver(post_delete, sender=Chat)
def log_chat_deletion(sender, instance, **kwargs):
    ActionLog.objects.create(user=instance.user_id, action_type='Удален чат', target_object_id=instance.chat_id)

@receiver(post_delete, sender=ChatAdmins)
def log_chat_admin_removal(sender, instance, **kwargs):
    ActionLog.objects.create(user=instance.user_id, action_type='Удален администратор группы', target_object_id=instance.chat_id)

@receiver(post_delete, sender=ChatMembers)
def log_chat_member_removal(sender, instance, **kwargs):
    ActionLog.objects.create(user=instance.user_id, action_type='Удален участник группы', target_object_id=instance.chat_id)

@receiver(post_delete, sender=User)
def log_user_deletion(sender, instance, **kwargs):
    ActionLog.objects.create(user=instance, action_type='Удален пользователь', target_object_id=instance.user_id)

@receiver(post_save, sender=Chat)
def log_chat_creation(sender, instance, created, **kwargs):
    if created:
        ActionLog.objects.create(user=instance.user_id, action_type='Создан чат', target_object_id=instance.chat_id)

@receiver(post_save, sender=ChatMembers)
def log_chat_member_addition(sender, instance, created, **kwargs):
    if created:
        ActionLog.objects.create(
            user=instance.user_id,
            action_type='Добавлен участник в чат',
            target_object_id=instance.chat_id.chat_id
        )

@receiver(post_save, sender=ChatAdmins)
def log_chat_admin_addition(sender, instance, created, **kwargs):
    if created:
        ActionLog.objects.create(
            user=instance.user_id,
            action_type='Добавлен администратор в чат',
            target_object_id=instance.chat_id.chat_id  # Используйте instance.id вместо instance.chat_id
        )

@receiver(post_save, sender=ChatMembers)
def log_chat_member_update(sender, instance, **kwargs):
    print("called signal for member")
    if instance.left_at:
        print("if worked")
        # Если left_at не установлено, значит, это обновление, а не создание
        ActionLog.objects.create(
            user=instance.user_id,
            action_type='Удален участник группы',
            target_object_id=instance.chat_id.chat_id
        )

@receiver(post_save, sender=ChatAdmins)
def log_chat_admin_update(sender, instance, **kwargs):
    print("called signal for admin")
    if instance.left_at:
        print("if worked")
        # Если left_at не установлено, значит, это обновление, а не создание
        ActionLog.objects.create(
            user=instance.user_id,
            action_type='Отозваны права администратора в группе',
            target_object_id=instance.chat_id.chat_id
        )