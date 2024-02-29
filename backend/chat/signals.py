# В файле signals.py вашего приложения
from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver
from .models import Chat, ChatAdmins, ChatMembers, User, ActionLog

@receiver(post_delete, sender=Chat)
def log_chat_deletion(sender, instance, **kwargs):
    ActionLog.objects.create(user=instance.user_id, action_type='Chat Deleted', target_object_id=instance.chat_id)

@receiver(post_delete, sender=ChatAdmins)
def log_chat_admin_removal(sender, instance, **kwargs):
    ActionLog.objects.create(user=instance.user_id, action_type='Admin Removed from Chat', target_object_id=instance.chat_id)

@receiver(post_delete, sender=ChatMembers)
def log_chat_member_removal(sender, instance, **kwargs):
    ActionLog.objects.create(user=instance.user_id, action_type='Member Removed from Chat', target_object_id=instance.chat_id)

@receiver(post_delete, sender=User)
def log_user_deletion(sender, instance, **kwargs):
    ActionLog.objects.create(user=instance, action_type='User Deleted', target_object_id=instance.user_id)

@receiver(post_save, sender=Chat)
def log_chat_creation(sender, instance, created, **kwargs):
    if created:
        ActionLog.objects.create(user=instance.user_id, action_type='Chat Created', target_object_id=instance.chat_id)

# from django.db.models.signals import post_save, post_delete
# from django.dispatch import receiver
# from django.apps import apps
# from django.apps import AppConfig
# from chat.models import *
# from django.core import serializers

# @receiver(post_save, sender=Chat)
# @receiver(post_save, sender=ChatAdmins)
# @receiver(post_save, sender=ChatMembers)
# @receiver(post_save, sender=User)
# @receiver(post_delete, sender=Chat)
# @receiver(post_delete, sender=ChatAdmins)
# @receiver(post_delete, sender=ChatMembers)
# @receiver(post_delete, sender=User)
# def log_database_changes(sender, instance, **kwargs):
#     # Serialize the instance to JSON
#     serialized_instance = serializers.serialize('json', [instance])
    
#     # Get the app label and model name
#     app_label = sender._meta.app_label
#     model_name = sender.__name__

#     # Log the action
#     action_type = 'Create' if kwargs.get('created') else 'Update' if kwargs.get('updated') else 'Delete'
#     ActionLog.objects.create(
#         user=instance.user_id if hasattr(instance, 'user_id') else instance,  # Assuming the user field is present
#         action_type=f"{action_type} {model_name}",
#         target_object_id=instance.user_id,
#         action_data=serialized_instance
#     )