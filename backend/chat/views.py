from datetime import timezone
from django.db.models import Q
from datetime import datetime
from profanity.validators import validate_is_profane
from django.core.exceptions import ObjectDoesNotExist
from django.core.exceptions import ValidationError
from chat.models import (
    ActionLog,
    Chat,
    ChatAdmins,
    Department,
    DepartmentEmployee, 
    Message,
    PasswordResetOTP,
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
    OTPVerificationSerializer,
    PasswordResetSerializer,
    RoleSerializer,
    SetNewPasswordSerializer,
    UserSerializer, 
    ChatSerializer, 
    MessageSerializer,
    UserProfileSerializer,
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

from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.crypto import get_random_string


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
            try:
                other_chat_user_id = ChatMembers.objects.exclude(user_id=user_id).filter(chat_id=chat).values_list('user_id', flat=True).first()
                print(other_chat_user_id)
                user = User.objects.get(id=other_chat_user_id)
                chat_name = f"{user.first_name} {user.last_name}"
                chat.chat_name = chat_name
                chat.save()
                chat_user = ChatMembers.objects.get(chat_id=chat, user_id=user_id, left_at__isnull=True)
                chat_user.left_at = datetime.now()
                chat_user.save()
                user = User.objects.get(id=user_id)
                
                
                
            #     other_user = get_user_model().objects.get(id=user_ids[0])  # Assuming it's a one-on-one chat
            # chat_name = f"{admin_user.first_name} {admin_user.last_name} - {other_user.first_name} {other_user.last_name}"
            except ChatMembers.DoesNotExist:
                return Response({'error': 'Пользователь не является участником этого чата'}, status=status.HTTP_404_NOT_FOUND)
            
            remaining_members = ChatMembers.objects.filter(chat_id=chat, left_at__isnull=True).count()
            if remaining_members == 0:
                chat.delete()
                return Response({'message': 'Chat deleted because no members are left'}, status=status.HTTP_204_NO_CONTENT)
            
            # chat.refresh_from_db()  # Обновляем данные чата из базы данных
            # chat.people_count = chat.chatmembers_set.exclude(left_at__isnull=True).count()  # Пересчитываем количество участников
            # chat.save()
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
        except ObjectDoesNotExist as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def perform_create(self, serializer):
        user_ids = serializer.validated_data['user_ids']
        admin_id = serializer.validated_data['admin_id']
        #chat_name = serializer.validated_data['chat_name']
        avatar = serializer.validated_data['avatar'] or 'chat_photos/default.jpg'
        group_chat = serializer.validated_data['group_chat']

        try:
            admin_user = get_user_model().objects.get(id=admin_id)
        except get_user_model().DoesNotExist:
            raise ObjectDoesNotExist('User with provided admin_id does not exist')
        
        print("ADMIN:") 
        print(admin_user) 

        if group_chat:
        # If it's a group chat, use the provided chat_name
            chat_name = serializer.validated_data['chat_name']
        else:
        # If it's a personal chat, dynamically generate the chat name
            other_user = get_user_model().objects.get(id=user_ids[0])  # Assuming it's a one-on-one chat
            chat_name = f"{admin_user.first_name} {admin_user.last_name} - {other_user.first_name} {other_user.last_name}"
        
        users_count = len(user_ids)
        existing_chat_count = ChatMembers.objects.filter(
            Q(chat_id__chat_name=chat_name) &
            Q(user_id__in=user_ids)
        ).values('user_id').annotate(user_count=Count('user_id'))

        # Если количество найденных записей для каждого пользователя равно 1, а общее количество найденных записей
        # соответствует количеству пользователей, то это означает, что чат уже существует.
        if len(existing_chat_count) == users_count:
            raise ValidationError("A chat with the same participants and name already exists.")
    
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


class LogoutView(APIView):
    permission_classes = (IsAuthenticated,)

    def post(self, request):
        try:
            refresh_token = request.data["refresh_token"]
            token = RefreshToken(refresh_token)
            token.blacklist()

            return Response(status=status.HTTP_205_RESET_CONTENT)
        except Exception as e:
            return Response(status=status.HTTP_400_BAD_REQUEST)


class PasswordResetView(generics.GenericAPIView):
    serializer_class = PasswordResetSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']

        user = User.objects.get(email=email)
        otp = get_random_string(length=6, allowed_chars='0123456789')

        PasswordResetOTP.objects.update_or_create(user=user, defaults={'otp': otp})

        try:
            send_mail(
                "Password Reset OTP",
                f"Your OTP for password reset is {otp}",
                "no-reply@example.com",
                [email],
                fail_silently=False,
            )
            return Response({"detail": "OTP has been sent to your email."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"detail": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class OTPVerificationView(generics.GenericAPIView):
    serializer_class = OTPVerificationSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        otp = serializer.validated_data['otp']

        try:
            user = User.objects.get(email=email)
            otp_instance = PasswordResetOTP.objects.get(user=user, otp=otp)
            return Response({"detail": "OTP is valid."}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({"detail": "User does not exist."}, status=status.HTTP_400_BAD_REQUEST)
        except PasswordResetOTP.DoesNotExist:
            return Response({"detail": "Invalid OTP."}, status=status.HTTP_400_BAD_REQUEST)

class SetNewPasswordView(generics.GenericAPIView):
    serializer_class = SetNewPasswordSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        otp = serializer.validated_data['otp']
        password = serializer.validated_data['password']

        try:
            user = User.objects.get(email=email)
            otp_instance = PasswordResetOTP.objects.get(user=user, otp=otp)
            user.set_password(password)
            user.save()
            otp_instance.delete()
            return Response({"detail": "Password has been reset successfully."}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({"detail": "User does not exist."}, status=status.HTTP_400_BAD_REQUEST)
        except PasswordResetOTP.DoesNotExist:
            return Response({"detail": "Invalid OTP."}, status=status.HTTP_400_BAD_REQUEST)