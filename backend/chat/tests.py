from django.test import TestCase
from django.contrib.auth import get_user_model
from django.http import HttpRequest

from chat.serializers import ChatAdminsSerializer, ChatMembersSerializer, ChatSerializer, CreateChatSerializer, DepartmentEmployeeSerializer, DepartmentSerializer, MessageSerializer,  RegisterSerializer, RoleSerializer, UserProfileSerializer, UserSerializer
from .models import UserProfile, Chat, ChatAdmins, ChatMembers, Message, Department, Roles, DepartmentEmployee, ActionLog
from django.utils import timezone

from rest_framework.test import APITestCase
from rest_framework import status
User = get_user_model()

class ModelTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='testuser', password='12345', first_name='John', last_name='Doe')
        self.user_profile = UserProfile.objects.get(user_id=self.user.id)
        self.chat = Chat.objects.create(chat_name='Test Chat', user_id=self.user)
        self.chat_admin = ChatAdmins.objects.create(chat_id=self.chat, user_id=self.user)
        self.chat_member = ChatMembers.objects.create(chat_id=self.chat, user_id=self.user)
        self.message = Message.objects.create(sender_id=self.user, chat_id=self.chat, body='Test message')
        self.department = Department.objects.create(head_id=self.user, department_name='Test Department')
        self.role = Roles.objects.create(role_name='Test Role')
        self.department_employee = DepartmentEmployee.objects.create(department_id=self.department, user_id=self.user, role=self.role)
        self.action_log = ActionLog.objects.create(user=self.user, action_type='Test Action', target_object_id=1, timestamp=timezone.now())

    def test_user_profile_creation(self):
        self.assertEqual(str(self.user_profile), str(self.user))

    def test_chat_creation(self):
        self.assertEqual(str(self.chat), 'Test Chat')

    def test_chat_admin_creation(self):
        self.assertEqual(str(self.chat_admin), 'Test Chat testuser')

    def test_chat_member_creation(self):
        self.assertEqual(str(self.chat_member), 'Test Chat testuser')

    def test_message_creation(self):
        self.assertEqual(str(self.message), 'Test message')

    def test_department_creation(self):
        self.assertEqual(str(self.department), 'Test Department')

    def test_role_creation(self):
        self.assertEqual(str(self.role), 'Test Role')

    def test_department_employee_creation(self):
        self.assertEqual(str(self.department_employee), 'Test Department testuser')

    def test_action_log_creation(self):
        self.assertEqual(str(self.action_log), f"{self.user} - Test Action on 1")

from rest_framework.test import APIRequestFactory
class UserSerializerTestCase(APITestCase):
    
    def setUp(self):
        self.user_data = {
            'id': 1,
            'username': 'test_user',
            'first_name': 'John',
            'last_name': 'Doe',
            'middle_name': 'Smith'
        }
        self.user = User.objects.create(**self.user_data)
        self.factory = APIRequestFactory()

    def test_user_serializer_data(self):
        request = self.factory.get('/api/users/1/')
        serializer_context = {'request': request}
        serializer = UserSerializer(instance=self.user, context=serializer_context)
        self.assertEqual(serializer.data['id'], self.user_data['id'])

    def test_user_serializer_fields(self):
        expected_fields = {'url', 'id', 'username', 'first_name', 'last_name', 'middle_name'}
        request = self.factory.get('/api/users/1/')
        serializer_context = {'request': request}
        serializer = UserSerializer(instance=self.user, context=serializer_context)
        self.assertEqual(set(serializer.data.keys()), expected_fields)


class ChatMembersSerializerTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='test_user')
        self.chat = Chat.objects.create(chat_name='Test Chat', group_chat=True, user_id=self.user)
        
        self.chat_member = ChatMembers.objects.create(chat_id=self.chat, user_id=self.user, left_at=None)
        self.factory = APIRequestFactory()

    def test_chat_members_serializer(self):
        request = self.factory.get('/')
        serializer = ChatMembersSerializer(instance=self.chat_member, context={'request': request})
        data = serializer.data
        self.assertEqual(data['chat_name'], 'Test Chat')
        self.assertEqual(data['people_count'], 1)

class ChatAdminsSerializerTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='test_user')
        self.chat = Chat.objects.create(chat_name='Test Chat', group_chat=True, user_id=self.user)
        self.chat_member = ChatMembers.objects.create(chat_id=self.chat, user_id=self.user)
        self.factory = APIRequestFactory()

    def test_chat_admins_serializer(self):
        request = self.factory.get('/')
        serializer = ChatAdminsSerializer(instance=self.chat_member, context={'request': request})
        data = serializer.data
        self.assertEqual(data['chat_name'], 'Test Chat')

class ChatSerializerTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='test_user')
        self.chat = Chat.objects.create(chat_name='Test Chat', group_chat=True, user_id=self.user)
        self.chat_member = ChatMembers.objects.create(chat_id=self.chat, user_id=self.user)
        self.factory = APIRequestFactory()

    def test_chat_serializer(self):
        request = self.factory.get('/')
        serializer = ChatSerializer(instance=self.chat, context={'request': request})
        data = serializer.data
        self.assertEqual(data['chat_name'], 'Test Chat')
        self.assertEqual(data['people_count'], 1)

class CreateChatSerializerTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='test_user')

    def test_create_chat_serializer(self):
        data = {
            'user_ids': [self.user.pk],
            'admin_id': self.user.pk,
            'chat_name': 'New Chat',
            'group_chat': True
        }
        serializer = CreateChatSerializer(data=data)
        self.assertTrue(serializer.is_valid())

class MessageSerializerTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='test_user', first_name='Test', last_name='User')
        self.chat = Chat.objects.create(chat_name='Test Chat', group_chat=True, user_id=self.user)
        # Создаем сообщение, указывая чат
        self.message = Message.objects.create(sender_id=self.user, chat_id=self.chat, body='Test message')
        self.factory = APIRequestFactory()

    def test_message_serializer(self):
        request = self.factory.get('/')
        serializer = MessageSerializer(instance=self.message, context={'request': request})
        data = serializer.data
        self.assertEqual(data['sender_username'], 'test_user')
        self.assertEqual(data['sender_first_name'], 'Test')
        self.assertEqual(data['sender_last_name'], 'User')
        self.assertIsNotNone(data['avatar'])


class DepartmentSerializerTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='head_user')
        self.department = Department.objects.create(department_name='Test Department', head_id=self.user)

    def test_department_serializer(self):
        serializer = DepartmentSerializer(instance=self.department)
        data = serializer.data
        self.assertEqual(data['department_name'], 'Test Department')

class RoleSerializerTestCase(TestCase):
    def setUp(self):
        self.role = Roles.objects.create(role_name='Test Role')

    def test_role_serializer(self):
        serializer = RoleSerializer(instance=self.role)
        data = serializer.data
        self.assertEqual(data['role_name'], 'Test Role')

class DepartmentEmployeeSerializerTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='test_user')
        self.department = Department.objects.create(department_name='Test Department', head_id=self.user)
        self.role = Roles.objects.create(role_name='Test Role')
        self.department_employee = DepartmentEmployee.objects.create(department_id=self.department, user_id=self.user, role=self.role)

    def test_department_employee_serializer(self):
        serializer = DepartmentEmployeeSerializer(instance=self.department_employee)
        data = serializer.data
        self.assertEqual(data['department_name'], 'Test Department')
        self.assertEqual(data['role'], 'Test Role')
        self.assertEqual(data['user_id'], self.user.id)

class UserProfileSerializerTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='test_user', first_name='Test', last_name='User', middle_name='Middle')
        self.profile = UserProfile.objects.get(user_id=self.user.id)
        self.factory = APIRequestFactory()

    def test_user_profile_serializer(self):
        request = self.factory.get('/')
        serializer_context = {'request': request}
        serializer = UserProfileSerializer(instance=self.profile, context=serializer_context)
        data = serializer.data
        self.assertEqual(data['user']['username'], 'test_user')

class RegisterSerializerTestCase(APITestCase):
    def test_register_serializer(self):
        data = {
            'first_name': 'Test',
            'last_name': 'User',
            'middle_name': 'Middle',
            'password': 'zxcvbnm,1',
            'password2': 'zxcvbnm,1'
        }
        serializer = RegisterSerializer(data=data, context={'request': None})
        serializer.is_valid(raise_exception=True)
        response = serializer.create(validated_data=serializer.validated_data)
        self.assertTrue(User.objects.filter(username=response['user']['username']).exists()) # Проверяем, что пользователь создан

from rest_framework_simplejwt.tokens import AccessToken
class UserViewSetTestCase(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test_user', password='password123')
        self.token = AccessToken.for_user(self.user)

    def test_list_users(self):
        url = '/users/'
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)  # Проверяем, что получили только одного пользователя

    def test_retrieve_user(self):
        url = f'/users/{self.user.id}/'
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'test_user')  # Проверяем, что получили нужного пользователя

    def test_create_user(self):
        url = '/users/'
        data = {'username': 'new_user', 'first_name': 'New', 'last_name': 'User', 'middle_name': 'Middle', 'url': '/users/', 'id': 1}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.post(url, data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(username='new_user').exists())  # Проверяем, что пользователь создан

    def test_update_user(self):
        url = f'/users/{self.user.id}/'
        data = {'username': 'updated_user', 'first_name': 'Updated', 'last_name': 'User', 'middle_name': 'Middle', 'url': '/users/', 'id': 1}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.put(url, data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(User.objects.get(id=self.user.id).username, 'updated_user')  # Проверяем, что пользователь обновлен

    def test_delete_user(self):
        url = f'/users/{self.user.id}/'
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(User.objects.filter(id=self.user.id).exists())  # Проверяем, что пользователь удален

class ChatViewSetTestCase(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test_user', password='password123')
        self.token = AccessToken.for_user(self.user)
        self.chat = Chat.objects.create(chat_name='Test Chat', user_id=self.user)
        self.user1 = get_user_model().objects.create_user(username='user1', password='password1')
        self.user2 = get_user_model().objects.create_user(username='user2', password='password2')
        self.admin = get_user_model().objects.create_user(username='admin', password='admin123')
        ChatAdmins.objects.create(chat_id=self.chat, user_id=self.admin)
        ChatMembers.objects.create(chat_id=self.chat, user_id=self.user1)

    def test_create_chat(self):
        url = '/chats/create_chat/'
        data = {
            'chat_name': 'Unique Chat Name',
            'admin_id': self.user.id,
            'user_ids': [],  # Можно добавить пользователей, если необходимо
            'group_chat': True,
            'avatar': None  # Можно добавить ссылку на изображение
        }
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Chat.objects.filter(chat_name='Unique Chat Name').exists())
    
    def test_partial_update_chat_name(self):
        url = f'/chats/partial_update/{self.chat.chat_id}/'
        new_chat_name = 'Updated Chat Name'
        data = {'chat_name': new_chat_name}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.patch(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.chat.refresh_from_db()
        self.assertEqual(self.chat.chat_name, new_chat_name)
    
    def test_partial_update_avatar(self):
        url = f'/chats/partial_update/{self.chat.chat_id}/'
        new_avatar = 'new_avatar.jpg'  # Новое значение для поля avatar
        data = {'avatar': new_avatar}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.patch(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.chat.refresh_from_db()
        self.assertEqual(self.chat.avatar, new_avatar)
    
    def test_partial_update_user_ids(self):
        url = f'/chats/partial_update/{self.chat.chat_id}/'
        new_user_ids = [self.user1.id, self.user2.id]  # Новые значения для поля user_ids
        data = {'user_ids': new_user_ids}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.patch(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Проверяем, что записи ChatMembers были созданы для новых пользователей
        for user_id in new_user_ids:
            self.assertTrue(ChatMembers.objects.filter(chat_id=self.chat, user_id=user_id).exists())

    def test_partial_update_admin_id(self):
        url = f'/chats/partial_update/{self.chat.chat_id}/'
        new_admin_id = self.user2.id  # Передаем идентификатор нового администратора
        data = {'admin_ids': [new_admin_id]}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.patch(url, data, format='json')
        print(response.data)
        print(data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Проверяем, что запись ChatAdmins была создана для нового администратора
        self.assertTrue(ChatAdmins.objects.filter(chat_id=self.chat, user_id=new_admin_id).exists())

    def test_partial_update_admin_leave_chat(self):
        url = f'/chats/partial_update/{self.chat.chat_id}/'
        data = {'admin_id': self.admin.id}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.patch(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Проверяем, что у администратора теперь есть временная метка left_at
        admin = ChatAdmins.objects.get(chat_id=self.chat, user_id=self.admin.id)
        self.assertIsNotNone(admin.left_at)

    def test_partial_update_user_leave_chat(self):
        url = f'/chats/partial_update/{self.chat.chat_id}/'
        data = {'user_id': self.user1.id}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.patch(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Проверяем, что у пользователя теперь есть временная метка left_at
        user = ChatMembers.objects.get(chat_id=self.chat, user_id=self.user1.id)
        self.assertIsNotNone(user.left_at)