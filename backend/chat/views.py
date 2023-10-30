import logging

import requests
from chat.models import (
    Chat, 
    Message,
    UserProfile, 
    ChatMembers
)
from rest_framework import (
    viewsets,
    generics
)
from chat.serializers import (
    UserSerializer, 
    ChatSerializer, 
    MessageSerializer,
    UserProfileSerializer,
    MyTokenObtainPairSerializer,
    RegisterSerializer, 
    ChatMembersSerializer
)
from rest_framework import permissions
from rest_framework.permissions import (
    IsAuthenticated,
    AllowAny
)
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework import status
from rest_framework.response import Response

from django.contrib.auth import get_user_model
#from .models import User
User = get_user_model()


class UserViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows users to be viewed or edited.
    """
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]


class ChatViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows chats to be viewed or edited.
    """
    queryset = Chat.objects.all()
    serializer_class = ChatSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        user_ids = request.data.get('user_ids')
        group_chat = request.data.get('group_chat', False)

        if user_ids:
            users = User.objects.filter(id__in=user_ids)

            if len(users) != len(user_ids):
                return Response({'error': 'Invalid user ids'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Проверяем, существует ли уже чат с этими пользователями
            chat = Chat.objects.filter(users__in=users).distinct()

            if chat:
                return Response({'error': 'Chat already exists'}, status=status.HTTP_400_BAD_REQUEST)
            
            # Создаем новый чат
            if group_chat:
                chat_name = request.data.get('chat_name')
            else:
                chat_name = ', '.join([user.first_name + ' ' + user.last_name for user in users])
            chat = Chat(chat_name=chat_name, group_chat=group_chat)
            chat.save()
            chat.users.set(users)

            serializer = ChatSerializer(chat)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        
        return Response({'error': 'Invalid data'}, status=status.HTTP_400_BAD_REQUEST)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        user_ids = request.data.get('user_ids')

        if user_ids:
            users = User.objects.filter(id__in=user_ids)

            if len(users) != len(user_ids):
                return Response({'error': 'Invalid user ids'}, status=status.HTTP_400_BAD_REQUEST)

            # Проверяем, существует ли уже чат с этими пользователями
            chat = Chat.objects.filter(users__in=users).exclude(chat_id=instance.chat_id).distinct()

            if chat:
                return Response({'error': 'Chat already exists'}, status=status.HTTP_400_BAD_REQUEST)

            # Обновляем чат
            instance.users.set(users)
            instance.save()

            serializer = ChatSerializer(instance)
            return Response(serializer.data)

        return Response({'error': 'Invalid data'}, status=status.HTTP_400_BAD_REQUEST)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Object-level permission to only allow owners of an object to edit it.
    Assumes the model instance has an `owner` attribute.
    """

    def has_permission(self, request, view):
        # Read permissions are allowed to any request,
        # so we'll always allow GET, HEAD or OPTIONS requests.
        if request.method in permissions.SAFE_METHODS:
            return True

        # Instance must have an attribute named `owner`.
        return int(request.data['sender_id']) == request.user.pk

class ChatMembersViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows chats to be viewed or edited.
    """
    queryset = ChatMembers.objects.all()
    serializer_class = ChatMembersSerializer
    permission_classes = [IsAuthenticated]
    

class MessageViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows messages to be viewed or edited.
    """
    queryset = Message.objects.all().order_by('created_at')
    serializer_class = MessageSerializer
    permission_classes = [IsAuthenticated, IsOwnerOrReadOnly]

    def create(self, request):
        print(request.data['sender_id'])
        print(request.data['chat_id'])
        resp = requests.get('http://localhost:8080/', params={
            'sender_id' : request.data['sender_id'], 
            'chat_id' : request.data['chat_id']
            })
        print(resp)
        return super().create(request)


class UserProfileViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows messages to be viewed or edited.
    """
    queryset = UserProfile.objects.all().order_by('created_at')
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
    def get_queryset(self):
        
        print(self.request.user)
        print("get_queryset")
        print(UserProfile.objects.filter(user_id=self.request.user.id))
        return UserProfile.objects.filter(user_id=self.request.user.id)
    
    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(serializer.data)

class AllUserProfileViewSet(viewsets.ModelViewSet):
    queryset = UserProfile.objects.all().order_by('created_at')
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
#viewset filter by authenticated user

class MyObtainTokenPairView(TokenObtainPairView):
    permission_classes = (AllowAny,)
    serializer_class = MyTokenObtainPairSerializer


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer

    def post(self, request):
        serializer = RegisterSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            response_data = serializer.save()
            return Response(response_data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    
