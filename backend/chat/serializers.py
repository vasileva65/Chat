from django.contrib.auth.models import Group
from chat.models import Chat, ChatMembers, Message, UserProfile
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework.validators import UniqueValidator
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth import get_user_model
#from .models import User
User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['url', 'id', 'username', 'first_name', 'last_name']


class ChatMembersSerializer(serializers.ModelSerializer):
    avatar = serializers.ImageField(source='chat_id.avatar', read_only=True)
    chat_name = serializers.CharField(source='chat_id.chat_name', read_only=True)
    class Meta:
        model = ChatMembers
        fields = ['url', 'chat_id', 'chat_name', 'avatar', 'user_id', 'joined_at', 'left_at']

class ChatSerializer(serializers.ModelSerializer):
    class Meta:
        model = Chat
        fields = ['url', 'chat_id', 'chat_name', 'user_id', 'created_at', 'updated_at']


class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender_id.username', read_only=True)
    sender_first_name = serializers.CharField(source='sender_id.first_name', read_only=True)
    sender_last_name = serializers.CharField(source='sender_id.last_name', read_only=True)

    class Meta:
        model = Message
        fields = ['url', 'message_id', 'sender_id', 'sender_username', 'sender_first_name', 'sender_last_name', 'chat_id', 'body', 'created_at']



class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer()
    class Meta:
        model = UserProfile
        fields = ['url', 'user_id', 'user', 'avatar', 'created_at', 'updated_at']


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):

    @classmethod
    def get_token(cls, user):
        token = super(MyTokenObtainPairSerializer, cls).get_token(user)

        # Add custom claims
        token['username'] = user.username
        return token


class RegisterSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(
            required=True,
            validators=[UniqueValidator(queryset=User.objects.all())]
            )

    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ('username', 'password', 'password2', 'email', 'first_name', 'last_name')
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True}
        }

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})

        return attrs

    def create(self, validated_data):
        user = User.objects.create(
            username=validated_data['username'],
            email=validated_data['email'],
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name']
        )
        
        user.set_password(validated_data['password'])
        user.save()

        return user
