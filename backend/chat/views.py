from datetime import timezone
from datetime import datetime
from profanity.validators import validate_is_profane
from django.core.exceptions import ValidationError
import logging

import requests
from chat.models import (
    ActionLog,
    Chat,
    ChatAdmins,
    Department,
    DepartmentEmployee, 
    Message,
    Roles,
    UserProfile, 
    ChatMembers
)
from rest_framework import (
    viewsets,
    generics
)
from chat.serializers import (
    CreateChatSerializer,
    DepartmentEmployeeSerializer,
    DepartmentSerializer,
    RoleSerializer,
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
        
        admin_ids = request.data.get('admin_ids', [])
        user_ids = request.data.get('user_ids', [])

        chat_name = request.data.get('chat_name', None)
        print(chat_name)
        avatar = request.data.get('avatar', None)
        print(avatar)

        if chat_name or avatar:
            if chat_name:
                chat.chat_name = chat_name
                chat.save()
                print("chat name saved")

            if avatar:
                chat.avatar = avatar
                chat.save()
                print("avatar saved")

            serializer = ChatSerializer(chat, context={'request': request})
            return Response(serializer.data)
        

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
            
            chat.refresh_from_db()  # Обновляем данные чата из базы данных
            chat.people_count = chat.chatmembers_set.exclude(left_at__isnull=True).count()  # Пересчитываем количество участников
            chat.save()
            serializer = ChatSerializer(chat, context={'request': request})
            return Response(serializer.data)
        else:
             return Response({'error': 'Неверные данные'}, status=status.HTTP_400_BAD_REQUEST)

        

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        print("INSTANCE DELETE " + str(instance))  
        instance.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    
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

    def get_queryset(self):
        # Фильтруем записи ChatMembers, где поле left_at пустое
        return ChatMembers.objects.filter(left_at__isnull=True)


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

    def create(self, request, *args, **kwargs):
        # print(request.data['sender_id'])
        # print(request.data['chat_id'])
        # resp = requests.get('http://localhost:8080/', params={
        #     'sender_id' : request.data['sender_id'], 
        #     'chat_id' : request.data['chat_id']
        #     })
        # print(resp)
        # return super().create(request)
        print("Received message creation request:", request.data)
        body = request.data.get('body', None)
        
        # Проверяем, есть ли текст сообщения в запросе
        if body:
            # Пытаемся валидировать текст сообщения
            try:
                validate_is_profane(body)
                print("TRY")
            except ValidationError as e:
                print("EXCEPT")
                # Если текст содержит нецензурные слова, создаем запись в журнале действий
                ActionLog.objects.create(
                    user=User.objects.get(id=request.user.id),
                    action_type='Использование нецензурной лексики',
                    target_object_id=request.data.get('chat_id', None),
                    #details=str(e)  # Записываем информацию об исключении в детали
                )
                print(str(e))
                # raise ValidationError('Please remove any profanity/swear words.')
                return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        
        # Если валидация прошла успешно или текст сообщения отсутствует, продолжаем создание сообщения
        return super().create(request, *args, **kwargs)


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
    
    def partial_update(self, request, *args, **kwargs):
        try:
            print("TRY CALLED")
            avatar = request.data.get('avatar')  # Получаем файл из запроса
            user_profile = self.get_object()
            if avatar:
                user_profile.avatar = avatar  # Сохраняем файл в поле avatar объекта UserProfile
                user_profile.save()
            # Получаем данные из запроса
            # user_id = request.data.get('user_id')
            # first_name = request.data.get('user', {}).get('first_name')
            # last_name = request.data.get('user', {}).get('last_name')
            # middle_name = request.data.get('user', {}).get('middle_name')
            # department_name = request.data.get('department_employee', {}).get('department_name')
            # role_name = request.data.get('department_employee', {}).get('role')

            # print("GOT DATA")
            # print(f"user_id: {user_id}, first_name: {first_name}, last_name: {last_name}, middle_name: {middle_name}, department_name: {department_name}, role_name: {role_name}")
            # # Обновляем данные пользователя
            # user_profile = UserProfile.objects.get(user_id=user_id)
            # user = user_profile.user
            # user.first_name = first_name
            # user.last_name = last_name
            # user.middle_name = middle_name
            # user.save()
            # print("USER SAVED")
            # role = Roles.objects.get(role_name=role_name)
            # # Получаем отдел
            # department = Department.objects.get(department_name=department_name)
            # print("GOT DEPARTMENT")
            # print(department.department_id)
            # user = User.objects.get(id=user_id)
            # print("GOT USER")
            # print(user.id)
            # # Пытаемся получить объект DepartmentEmployee, связанный с пользователем и отделом
            # # Если объект не найден, он будет создан
            # try:
            #     department_employee, created = DepartmentEmployee.objects.update_or_create(user_id=user, department_id=department, role=role)
            #     print("DEPARTMENT CREATED")
            #     if created:
            #         print("DEPARTMENT CREATED")
            #     else:
            #         print("DEPARTMENT UPDATED")
            # except Exception as e:
            #     print("ERROR:", str(e))
            #     raise e
            # Обновляем роль пользователя в отделе
            # department_employee.role = role_name
            # print("ROLE SAVED")
            # department_employee.save()
            # print("DEP EMPLOYEE SAVED")
            return Response({'message': 'Настройки пользователя успешно обновлены'}, status=status.HTTP_200_OK)
        except UserProfile.DoesNotExist:
            return Response({'error': 'Профиль пользователя не найден'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class AllUserProfileViewSet(viewsets.ModelViewSet):
    queryset = UserProfile.objects.all().order_by('created_at')
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
#viewset filter by authenticated user


class DepartmentViewSet(viewsets.ModelViewSet):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer


class RoleViewSet(viewsets.ModelViewSet):
    queryset = Roles.objects.all()
    serializer_class = RoleSerializer

    
class DepartmentEmployeeViewSet(viewsets.ModelViewSet):
    queryset = DepartmentEmployee.objects.all()
    serializer_class = DepartmentEmployeeSerializer



class MyObtainTokenPairView(TokenObtainPairView):
    permission_classes = (AllowAny,)
    serializer_class = MyTokenObtainPairSerializer


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (AllowAny,)
    serializer_class = RegisterSerializer

    def post(self, request):
        print("REGISTER VIEW")
        serializer = RegisterSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            response_data = serializer.save()
            return Response(response_data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    
