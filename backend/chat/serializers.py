from django.contrib.auth.models import Group
from backend.generator import generate_username
from chat.models import Chat, ChatMembers, Message, UserProfile
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework.validators import UniqueValidator
from django.contrib.auth.password_validation import validate_password
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils.translation import gettext as _
#from .models import User
User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['url', 'id', 'username', 'first_name', 'last_name', 'middle_name']


class ChatMembersSerializer(serializers.ModelSerializer):
    avatar = serializers.ImageField(source='chat_id.avatar', read_only=True)
    chat_name = serializers.CharField(source='chat_id.chat_name', read_only=True)
    people_count = serializers.SerializerMethodField(read_only=True)
    group_chat = serializers.CharField(source='chat_id.group_chat', read_only=True)
    
    def get_people_count(self, obj):
        return obj.chat_id.chatmembers_set.count()
    
    class Meta:
        model = ChatMembers
        fields = ['url', 'chat_id', 'chat_name', 'avatar', 'user_id', 'joined_at', 'left_at', 'people_count', 'group_chat']

class ChatAdminsSerializer(serializers.ModelSerializer):
    chat_name = serializers.CharField(source='chat_id.chat_name', read_only=True)
    
    class Meta:
        model = ChatMembers
        fields = ['url', 'chat_id', 'chat_name', 'user_id', 'joined_at', 'left_at']

class ChatSerializer(serializers.ModelSerializer):
    people_count = serializers.SerializerMethodField(read_only=True)

    def get_people_count(self, obj):
        return obj.chatmembers_set.count()
    
    class Meta:
        model = Chat
        fields = ['url', 'chat_id', 'chat_name', 'user_id', 'created_at', 'updated_at', 'group_chat', 'people_count']

    

class CreateChatSerializer(serializers.ModelSerializer):
    user_ids = serializers.ListField(write_only=True)
    admin_id = serializers.IntegerField(write_only=True)
    chat_name = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    avatar = serializers.ImageField(write_only=True, required=False, allow_null=True)
    group_chat = serializers.BooleanField(write_only=True, default=True)

    class Meta:
        model = Chat
        fields = ['user_ids', 'admin_id', 'chat_name', 'avatar', 'group_chat']
    


class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender_id.username', read_only=True)
    sender_first_name = serializers.CharField(source='sender_id.first_name', read_only=True)
    sender_last_name = serializers.CharField(source='sender_id.last_name', read_only=True)
    avatar = serializers.CharField(source='sender_id.avatar', read_only=True)

    class Meta:
        model = Message
        fields = ['url', 'message_id', 'sender_id', 'sender_username', 'sender_first_name', 'sender_last_name', 'avatar', 'chat_id', 'body', 'created_at']



class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer()
    class Meta:
        model = UserProfile
        fields = ['url', 'id', 'user_id', 'user', 'avatar', 'created_at', 'updated_at']


class MyTokenObtainPairSerializer(TokenObtainPairSerializer):

    @classmethod
    def get_token(cls, user):
        token = super(MyTokenObtainPairSerializer, cls).get_token(user)

        # Add custom claims
        token['username'] = user.username
        return token


class RegisterSerializer(serializers.ModelSerializer):

    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ('first_name', 'last_name', 'middle_name', 'password', 'password2')
        extra_kwargs = {
            'first_name': {'required': True},
            'last_name': {'required': True},
            'middle_name': {'required': True},
        }

    
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Пароли не совпадают."})
        return attrs

    

    def create(self, validated_data):

        username = generate_username(validated_data['first_name'],validated_data['middle_name'])

        while(User.objects.filter(username=username).exists()):
            username = generate_username(validated_data['first_name'], validated_data['middle_name'])
        
        user = User.objects.create(
            username=username,
            first_name=validated_data['first_name'],
            last_name=validated_data['last_name'],
            middle_name=validated_data['middle_name']
        )
        
        user.set_password(validated_data['password'])

        user.save()

        refresh = RefreshToken.for_user(user)
        user_serializer = UserSerializer(user, context=self.context)  
        return {
            'user': user_serializer.data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }