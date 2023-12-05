from django.urls import path, include
from rest_framework.routers import DefaultRouter
from chat.views import (
    AllUserProfileViewSet,
    RegisterView,
    UserViewSet,
    MessageViewSet,
    UserProfileViewSet,
    ChatViewSet,
    ChatMembersViewSet
)
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from django.contrib import admin
from rest_framework_simplejwt.views import TokenRefreshView


# Create a router and register our viewsets with it.
router = DefaultRouter()
router.register(r'users', UserViewSet,basename="user")
router.register(r'messages', MessageViewSet,basename="message")
router.register(r'chats', ChatViewSet,basename="chat")
router.register(r'chatmembers', ChatMembersViewSet,basename="chatmembers")
router.register(r'user/profile', UserProfileViewSet,basename="userprofile")
router.register(r'userprofiles', AllUserProfileViewSet, basename="profiles")
router.register(r'chats/create_chat', ChatViewSet, basename="create_chat")


# The API URLs are now determined automatically by the router.
urlpatterns = [
    path('', include(router.urls)),
    path('admin/', admin.site.urls),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', RegisterView.as_view(), name='auth_register'),
]
