from django.test import TestCase
from django.contrib.auth import get_user_model
from chat.models import UserProfile, Chat, ChatAdmins, ChatMembers, Message, Department, Roles, DepartmentEmployee, ActionLog
from django.utils import timezone

User = get_user_model()
from django.conf import settings

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