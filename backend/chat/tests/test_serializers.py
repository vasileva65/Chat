from django.test import TestCase
from django.contrib.auth import get_user_model


from chat.serializers import ChatAdminsSerializer, ChatMembersSerializer, ChatSerializer, CreateChatSerializer, DepartmentEmployeeSerializer, DepartmentSerializer, MessageSerializer,  RegisterSerializer, RoleSerializer, UserProfileSerializer, UserSerializer
from chat.models import UserProfile, Chat, ChatMembers, Message, Department, Roles, DepartmentEmployee

from rest_framework.test import APITestCase
User = get_user_model()
from django.conf import settings


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