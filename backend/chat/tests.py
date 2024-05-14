
from django.contrib.auth import get_user_model
from .models import UserProfile, Chat, ChatAdmins, ChatMembers, Message, Department, Roles, DepartmentEmployee, ActionLog

from django.test import TestCase

class UserModelTest(TestCase):
    def test_user_creation(self):
        user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )
        self.assertEqual(user.username, 'testuser')
        self.assertTrue(user.check_password('12345'))
        self.assertEqual(user.first_name, 'John')
        self.assertEqual(user.last_name, 'Doe')

class UserProfileModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )

    def test_user_profile_creation(self):
        user_profile = UserProfile.objects.create(user=self.user)
        self.assertEqual(user_profile.user, self.user)

class ChatModelTest(TestCase):
    def test_chat_creation(self):
        user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )
        chat = Chat.objects.create(chat_name='Test Chat', user_id=user)
        self.assertEqual(chat.chat_name, 'Test Chat')
        self.assertEqual(chat.user_id, user)

# Similarly, write tests for other models like ChatAdmins, ChatMembers, Message, Department, Roles, DepartmentEmployee, ActionLog

class ChatAdminsModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )
        self.chat = Chat.objects.create(chat_name='Test Chat', user_id=self.user)

    def test_chat_admin_creation(self):
        chat_admin = ChatAdmins.objects.create(chat_id=self.chat, user_id=self.user)
        self.assertEqual(chat_admin.chat_id, self.chat)
        self.assertEqual(chat_admin.user_id, self.user)

class ChatMembersModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )
        self.chat = Chat.objects.create(chat_name='Test Chat', user_id=self.user)

    def test_chat_member_creation(self):
        chat_member = ChatMembers.objects.create(chat_id=self.chat, user_id=self.user)
        self.assertEqual(chat_member.chat_id, self.chat)
        self.assertEqual(chat_member.user_id, self.user)

class MessageModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )
        self.chat = Chat.objects.create(chat_name='Test Chat', user_id=self.user)

    def test_message_creation(self):
        message = Message.objects.create(sender_id=self.user, chat_id=self.chat, body='Test message')
        self.assertEqual(message.sender_id, self.user)
        self.assertEqual(message.chat_id, self.chat)
        self.assertEqual(message.body, 'Test message')

class DepartmentModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )

    def test_department_creation(self):
        department = Department.objects.create(head_id=self.user, department_name='Test Department')
        self.assertEqual(department.head_id, self.user)
        self.assertEqual(department.department_name, 'Test Department')

class RolesModelTest(TestCase):
    def test_role_creation(self):
        role = Roles.objects.create(role_name='Test Role')
        self.assertEqual(role.role_name, 'Test Role')

class DepartmentEmployeeModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )
        self.department = Department.objects.create(head_id=self.user, department_name='Test Department')
        self.role = Roles.objects.create(role_name='Test Role')

    def test_department_employee_creation(self):
        department_employee = DepartmentEmployee.objects.create(department_id=self.department, user_id=self.user, role=self.role)
        self.assertEqual(department_employee.department_id, self.department)
        self.assertEqual(department_employee.user_id, self.user)
        self.assertEqual(department_employee.role, self.role)

class ActionLogModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            password='12345',
            first_name='John',
            last_name='Doe'
        )

    def test_action_log_creation(self):
        action_log = ActionLog.objects.create(user=self.user, action_type='Test Action', target_object_id=1)
        self.assertEqual(action_log.user, self.user)
        self.assertEqual(action_log.action_type, 'Test Action')
        self.assertEqual(action_log.target_object_id, 1)
