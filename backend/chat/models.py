from django.db import models
from django.contrib.auth.models import User
from profanity.validators import validate_is_profane

class UserProfile(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    avatar = models.ImageField(null=True, blank=True, upload_to ='user_photos/', height_field=None, width_field=None)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return str(self.user)


class Chat(models.Model):
    chat_id = models.AutoField(primary_key=True)
    chat_name = models.CharField(max_length=20, unique=True)
    user_id = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    # TODO: add last read concept

    def __str__(self):
        return self.chat_name


class Message(models.Model):
    message_id = models.AutoField(primary_key=True)
    sender_id = models.ForeignKey('auth.User', related_name='message', on_delete=models.CASCADE)
    chat_id = models.ForeignKey(Chat, on_delete=models.CASCADE)
    body = models.TextField(validators=[validate_is_profane])
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_read = models.BooleanField(default=False)
    # TODO: add position concept

    def __str__(self):
        return self.body


    


