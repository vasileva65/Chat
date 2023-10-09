from typing import Any
from django.db import models
from django.contrib.auth.models import AbstractUser
from profanity.validators import validate_is_profane
from django.conf import settings
from .manager import CustomUserManager
from django.db.models.signals import post_save

class User(AbstractUser):
    
    middle_name = models.CharField(max_length=150, blank=True)

    objects = CustomUserManager()

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.username


class UserProfile(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    avatar = models.ImageField(upload_to ='user_photos/', default='default.jpg', height_field=None, width_field=None)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True,null=True)

    def __str__(self):
        return str(self.user)

#create profile when user signs up
def create_profile(sender, instance, created, **kwargs):
    if created:
        user_profile = UserProfile(user=instance)
        user_profile.save()

post_save.connect(create_profile, sender=User)

class Chat(models.Model):
    chat_id = models.AutoField(primary_key=True)
    chat_name = models.CharField(max_length=20, unique=True)
    user_id = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    avatar = models.ImageField(upload_to ='chat_photos/', default='default.jpg', height_field=None, width_field=None)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True,null=True)
    # TODO: add last read concept

    def __str__(self):
        return self.chat_name

class ChatMembers(models.Model):
    chat_id = models.ForeignKey(Chat, on_delete=models.CASCADE)
    user_id = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    joined_at = models.DateTimeField(auto_now_add=True)
    left_at = models.DateTimeField(null=True, blank=True)


    def __str__(self):
        return self.chat_id.chat_name + ' ' + self.user_id.username
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.left_at = None
        super().save(*args, **kwargs)
    

class Message(models.Model):
    message_id = models.AutoField(primary_key=True)
    sender_id = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='message', on_delete=models.CASCADE)
    chat_id = models.ForeignKey(Chat, on_delete=models.CASCADE)
    body = models.TextField(validators=[validate_is_profane])
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True, null=True)
    #is_read = models.BooleanField(default=False)
    # TODO: add position concept

    def __str__(self):
        return self.chat_id.chat_name
    
    def __str__(self):
        return self.body


    


