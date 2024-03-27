from datetime import timezone
from datetime import datetime

import logging

import requests
from chat.models import (
    ActionLog,
    Chat,
    ChatAdmins, 
    Message,
    UserProfile, 
    ChatMembers
)
from rest_framework import (
    viewsets,
    generics
)
from chat.serializers import (
    CreateChatSerializer,
    UserSerializer, 
    ChatSerializer, 
    MessageSerializer,
    UserProfileSerializer,
    MyTokenObtainPairSerializer,
    RegisterSerializer, 
    ChatMembersSerializer,
    ChatAdminsSerializer
)
from rest_framework import permissions
from rest_framework.permissions import (
    IsAuthenticated,
    AllowAny
)
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework import serializers
from django.db.models import Count

from django.contrib.auth import get_user_model
#from .models import User
User = get_user_model()

from django.shortcuts import get_object_or_404


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

    def get_queryset(self):
        queryset = Chat.objects.annotate(people_count=Count('chatmembers')).all()
        return queryset
    
    def partial_update(self, request, *args, **kwargs):
        print("partial update called")
        chat = self.get_object()
        user_id = request.data.get('user_id', None)
        admin_id = request.data.get('admin_id', None)
        print(admin_id)
        admin_ids = request.data.get('admin_ids', [])
        user_ids = request.data.get('user_ids', [])

        if user_ids:
            users = User.objects.filter(id__in=user_ids)

            if len(users) != len(user_ids):
                return Response({'error': 'Invalid user ids'}, status=status.HTTP_400_BAD_REQUEST)

            for user in users:
                ChatMembers.objects.create(chat_id=chat, user_id=user)

            serializer = ChatSerializer(chat, context={'request': request})
            return Response(serializer.data)
        
        if admin_ids:
            admins = User.objects.filter(id__in=admin_ids)

            if len(admins) != len(admin_ids):
                return Response({'error': 'Invalid admin ids'}, status=status.HTTP_400_BAD_REQUEST)

            for admin in admins:
                ChatAdmins.objects.create(chat_id=chat, user_id=admin)

            serializer = ChatSerializer(chat, context={'request': request})
            return Response(serializer.data)
        
        if admin_id:
            print("admin id close")
            try:
                print("try called")
                chat_admin = ChatAdmins.objects.get(chat_id=chat, user_id=admin_id, left_at__isnull=True)
                print(chat_admin)
                chat_admin.left_at = datetime.now()
                print(chat_admin.left_at)
                chat_admin.save()
                print("saved")
            except ChatAdmins.DoesNotExist:
                return Response({'error': 'Пользователь не является администратором этого чата'}, status=status.HTTP_404_NOT_FOUND)
            
            serializer = ChatSerializer(chat, context={'request': request})
            return Response(serializer.data)
        if user_id:
            print("user id close")
            try:
                print("try called")
                chat_user = ChatMembers.objects.get(chat_id=chat, user_id=user_id, left_at__isnull=True)
                print(chat_user)
                chat_user.left_at = datetime.now()
                print(chat_user.left_at)
                chat_user.save()
                print("saved")
            except ChatMembers.DoesNotExist:
                return Response({'error': 'Пользователь не является участником этого чата'}, status=status.HTTP_404_NOT_FOUND)
            
            serializer = ChatSerializer(chat, context={'request': request})
            return Response(serializer.data)
        else:
             return Response({'error': 'Неверные данные'}, status=status.HTTP_400_BAD_REQUEST)

        

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    
    #@action(detail=True, methods=['patch'])
    # def remove_member_or_admin(self, request, *args, **kwargs):
    #     print("removing called")
    #     chat = self.get_object()
    #     # user_id = request.data.get('user_id', '')
    #     admin_id = request.data.get('admin_id')
    #     admin_id = int(admin_id)
    #     # if user_id:
    #     #     try:
    #     #         chat_member = ChatMembers.objects.get(chat_id=chat, user_id=user_id)
    #     #         chat_member.left_at = timezone.now()
    #     #         chat_member.save()
    #     #     except ChatMembers.DoesNotExist:
    #     #         return Response({'error': 'Пользователь не является участником этого чата'}, status=status.HTTP_404_NOT_FOUND)
    #     if admin_id:
    #         try:
    #             chat_admin = ChatAdmins.objects.get(chat_id=chat, user_id=admin_id)
    #             chat_admin.left_at = timezone.now()
    #             chat_admin.save()
    #         except ChatAdmins.DoesNotExist:
    #             return Response({'error': 'Пользователь не является администратором этого чата'}, status=status.HTTP_404_NOT_FOUND)
    #     else:
    #          return Response({'error': 'Неверные данные'}, status=status.HTTP_400_BAD_REQUEST)

    #     serializer = ChatSerializer(chat, context={'request': request})
    #     return Response(serializer.data)
    
    @action(detail=False, methods=['post'], serializer_class=CreateChatSerializer)
    def create_chat(self, request, *args, **kwargs):
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except serializers.ValidationError as e:
            print(e)
            return Response({'error': 'Validation error'}, status=status.HTTP_400_BAD_REQUEST)

    def perform_create(self, serializer):
        user_ids = serializer.validated_data['user_ids']
        admin_id = serializer.validated_data['admin_id']
        #chat_name = serializer.validated_data['chat_name']
        avatar = serializer.validated_data['avatar'] or 'chat_photos/default.jpg'
        group_chat = serializer.validated_data['group_chat']

        admin_user = get_user_model().objects.get(id=admin_id)
        
        print("ADMIN:") 
        print(admin_user) 

        if group_chat:
        # If it's a group chat, use the provided chat_name
            chat_name = serializer.validated_data['chat_name']
        else:
        # If it's a personal chat, dynamically generate the chat name
            other_user = get_user_model().objects.get(id=user_ids[0])  # Assuming it's a one-on-one chat
            chat_name = f"{admin_user.first_name} {admin_user.last_name} - {other_user.first_name} {other_user.last_name}"
        
        chat = Chat(chat_name=chat_name, group_chat=group_chat, avatar=avatar, user_id=admin_user)
        chat.save()
        print("CHAT SAVED")
        print(type(user_ids))
        users = get_user_model().objects.filter(id__in=user_ids)
        print("USERS: ")
        print(users)

        for user in users:
            ChatMembers.objects.create(chat_id=chat, user_id=user)

        ChatMembers.objects.create(chat_id=chat, user_id=admin_user)
        ChatAdmins.objects.create(chat_id=chat, user_id=admin_user)
        print("ChatMembers created successfully")
        serializer.instance = chat


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


class ChatAdminsViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows chats to be viewed or edited.
    """
    queryset = ChatAdmins.objects.all()
    serializer_class = ChatAdminsSerializer
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

    
