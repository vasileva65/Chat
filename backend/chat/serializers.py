from django.contrib.auth.models import User, Group
from chat.models import Message
from rest_framework import serializers


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['url', 'id', 'username', 'chats']


class ChatSerializer(serializers.ModelSerializer):
    class Meta:
        model = Group
        fields = ['url', 'id', 'name', 'user_id']


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['url', 'message_id', 'sender_id', 'chat_id', 'body', 'created_at']
