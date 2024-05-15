from datetime import datetime
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.http import HttpRequest
from rest_framework.test import APIRequestFactory
from chat.views import ChatMembersViewSet, IsOwnerOrReadOnly
from chat.serializers import ChatAdminsSerializer, ChatMembersSerializer, ChatSerializer, CreateChatSerializer, DepartmentEmployeeSerializer, DepartmentSerializer, MessageSerializer,  RegisterSerializer, RoleSerializer, UserProfileSerializer, UserSerializer
from chat.models import UserProfile, Chat, ChatAdmins, ChatMembers, Message, Department, Roles, DepartmentEmployee, ActionLog
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
User = get_user_model()
import os
from django.conf import settings

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
    
    def test_create_group_chat(self):
        url = '/chats/create_chat/'
        data = {
            'chat_name': 'Unique Chat Name',
            'admin_id': self.user.id,
            'user_ids': [],
            'group_chat': True,
            'avatar': None
        }
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Chat.objects.filter(chat_name='Unique Chat Name').exists())

    def test_create_personal_chat(self):
        url = '/chats/create_chat/'
        data = {
            'admin_id': self.user.id,
            'user_ids': [self.user2.id],
            'group_chat': False,
            'avatar': None
        }
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        chat = Chat.objects.get(chat_name=f'{self.user.first_name} {self.user.last_name} - {self.user2.first_name} {self.user2.last_name}')
        self.assertIsNotNone(chat)

    def test_missing_admin_id(self):
        url = '/chats/create_chat/'
        data = {
            'chat_name': 'Chat without Admin',
            'user_ids': [],
            'group_chat': True,
            'avatar': None
        }
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_invalid_admin_id(self):
        url = '/chats/create_chat/'
        data = {
            'chat_name': 'Chat with Invalid Admin',
            'admin_id': 999,
            'user_ids': [],
            'group_chat': True,
            'avatar': None
        }
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('User with provided admin_id does not exist', response.data['error'])

    def test_create_chat_with_avatar(self):
        url = '/chats/create_chat/'
        avatar_path = os.path.join(settings.BASE_DIR, 'test_media', 'Снимок.JPG')
        with open(avatar_path, 'rb') as avatar:
            data = {
                'chat_name': 'Chat with Avatar',
                'admin_id': self.user.id,
                'user_ids': [self.user1.id],
                'group_chat': True,
                'avatar': avatar
            }
            self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
            response = self.client.post(url, data, format='multipart')
            print(response.data)
            print(data)
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)
            self.assertTrue(Chat.objects.filter(chat_name='Chat with Avatar').exists())

    def test_add_chat_members_and_admins(self):
        
        url = '/chats/create_chat/'
        data = {
            'chat_name': 'Chat with Members',
            'admin_id': self.user.id,
            'user_ids': [self.user2.id],
            'group_chat': True,
            'avatar': None
        }
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        chat = Chat.objects.get(chat_name='Chat with Members')
        self.assertTrue(ChatMembers.objects.filter(chat_id=chat, user_id=self.user).exists())
        self.assertTrue(ChatMembers.objects.filter(chat_id=chat, user_id=self.user2).exists())
        self.assertTrue(ChatAdmins.objects.filter(chat_id=chat, user_id=self.user).exists())

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
    
    def test_delete_chat(self):
        url = f'/chats/{self.chat.chat_id}/'
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Chat.objects.filter(chat_id=self.chat.chat_id).exists())

    def test_get_chats(self):
        url = '/chats/'
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)
        self.assertTrue(any(chat['chat_id'] == self.chat.chat_id for chat in response.data))

    def test_access_nonexistent_chat(self):
        url = f'/chats/999999/'
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_partial_update_invalid_data(self):
        url = f'/chats/partial_update/{self.chat.chat_id}/'
        data = {'invalid_field': 'value'}
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = self.client.patch(url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

class IsOwnerOrReadOnlyTestCase(TestCase):
    def setUp(self):
        self.factory = APIRequestFactory()
        self.user = User.objects.create_user(username='test_user', password='password123')

    def test_has_permission_read_only(self):
        request = self.factory.get('/fake-url/')
        request.user = self.user

        permission = IsOwnerOrReadOnly()
        self.assertTrue(permission.has_permission(request, None))

    def test_has_permission_edit_not_owner(self):
        request = self.factory.post('/fake-url/', {'sender_id': 2})  # Sender ID is not the same as request user ID
        request.user = self.user
        request.data = {'sender_id': 2}

        permission = IsOwnerOrReadOnly()
        self.assertFalse(permission.has_permission(request, None))

    def test_has_permission_edit_owner(self):
        request = self.factory.post('/fake-url/', {'sender_id': self.user.pk})
        request.user = self.user
        request.data = {'sender_id': self.user.pk}  # Adding data to the request

        permission = IsOwnerOrReadOnly()
        self.assertTrue(permission.has_permission(request, None))

from rest_framework.test import force_authenticate

class ChatMembersViewSetTestCase(APITestCase):
    def setUp(self):
        self.factory = APIRequestFactory()
        self.user = User.objects.create_user(username='test_user', password='password123')
        self.token = AccessToken.for_user(self.user)
        self.chat = Chat.objects.create(chat_name='Test Chat', user_id=self.user)
        self.chat_member = ChatMembers.objects.create(chat_id=self.chat, user_id=self.user)

    def test_list_chat_members(self):
        request = self.factory.get('/chatmembers/')
        force_authenticate(request, user=self.user)  # Устанавливаем аутентификацию для пользователя
        response = ChatMembersViewSet.as_view({'get': 'list'})(request)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)  

    def test_create_chat_member(self):
        new_user = User.objects.create_user(username='new_user', password='password123')
        token = AccessToken.for_user(new_user)
        request = self.factory.post('/chatmembers/', {'user_id': new_user.id, 'chat_id': self.chat.chat_id})
        request.META['HTTP_AUTHORIZATION'] = f'Bearer {token}'
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.token}')
        response = ChatMembersViewSet.as_view({'post': 'create'})(request)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(ChatMembers.objects.filter(user_id=new_user, chat_id=self.chat).count(), 1) 

    def test_get_queryset(self):
    # Создаем несколько дополнительных участников чата, включая одного, который покинул чат
        user2 = User.objects.create_user(username='user2', password='password123')
        user3 = User.objects.create_user(username='user3', password='password123')
        ChatMembers.objects.create(chat_id=self.chat, user_id=user2)
        ChatMembers.objects.create(chat_id=self.chat, user_id=user3)
        user3 = ChatMembers.objects.get(chat_id=self.chat, user_id=user3)
        user3.left_at = datetime.now()
        user3.save()
        # Запрашиваем queryset и применяем к нему фильтр по покинутым участникам
        queryset = ChatMembers.objects.filter(chat_id=self.chat, left_at__isnull=True).values('user_id')

        # Выводим записи из queryset для отладки
        print(list(queryset))

        # Получаем только id пользователей из queryset
        user_ids = [member['user_id'] for member in queryset]

        # Проверяем, что возвращается только активные участники чата
        self.assertEqual(len(user_ids), 2)
        self.assertTrue(all(user_id in [self.user.id, user2.id] for user_id in user_ids))

        # Проверяем, что участник, покинувший чат, не входит в queryset
        self.assertTrue(user3.left_at is not None)