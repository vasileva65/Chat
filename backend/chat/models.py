from django.db import models
from django.contrib.auth.models import User

'''
class User(models.Model):
    user_id = models.PositiveIntegerField(primary_key=True)
    login = models.CharField(max_length=20, unique=True)
    name = models.CharField(max_length=20)
    lastname = models.CharField(max_length=50)
    surname = models.CharField(max_length=50)
    job_title = models.CharField(max_length=255)

    def __str__(self):
        return "%s %s" % (self.name, self.lastname)
'''

class Chat(models.Model):
    chat_id = models.PositiveIntegerField(primary_key=True)
    chat_name = models.CharField(max_length=20, unique=True)
    user_id = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    #last_read

    def __str__(self):
        return self.chat_name

class Message(models.Model):
    message_id = models.PositiveIntegerField(primary_key=True)
    sender_id = models.ForeignKey('auth.User', related_name='message', on_delete=models.CASCADE)
    chat_id = models.ForeignKey(Chat, on_delete=models.CASCADE)
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_read = models.BooleanField(default=False)
    #position

    def __str__(self):
        return self.body




