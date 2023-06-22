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
from django.contrib.auth import get_user_model
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


#viewset filter by authenticated user

class MyObtainTokenPairView(TokenObtainPairView):
    permission_classes = (AllowAny,)
    serializer_class = MyTokenObtainPairSerializer


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer
