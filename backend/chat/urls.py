from django.urls import path, include
from rest_framework.routers import DefaultRouter
from chat.views import (
    AllUserProfileViewSet,
    ChatAdminsViewSet,
    DepartmentEmployeeViewSet,
    DepartmentViewSet,
    LogoutView,
    RegisterView,
    RoleViewSet,
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
from rest_framework_simplejwt.views import TokenBlacklistView


# Create a router and register our viewsets with it.
router = DefaultRouter()
router.register(r'users', UserViewSet,basename="user")
router.register(r'messages', MessageViewSet,basename="message")
router.register(r'chats', ChatViewSet,basename="chat")
router.register(r'chatmembers', ChatMembersViewSet,basename="chatmembers")
router.register(r'chatadmins', ChatAdminsViewSet,basename="chatadmins")
router.register(r'user/profile', UserProfileViewSet,basename="userprofile")
router.register(r'user/profile/partial_update', UserProfileViewSet,basename="userprofile_partial_update")
router.register(r'userprofiles', AllUserProfileViewSet, basename="profiles")
router.register(r'chats/create_chat', ChatViewSet, basename="create_chat")
router.register(r'chats/partial_update', ChatViewSet, basename='partial_update')
router.register(r'chats/remove_member_or_admin', ChatViewSet, basename='remove_member_or_admin')
router.register(r'departments', DepartmentViewSet, basename='departments')
router.register(r'roles', RoleViewSet, basename='roles')
router.register(r'department-employees', DepartmentEmployeeViewSet, basename='department_employee')

# The API URLs are now determined automatically by the router.
urlpatterns = [
    path('', include(router.urls)),
    path('admin/', admin.site.urls),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', RegisterView.as_view(), name='auth_register'),
    path("prometheus/", include("django_prometheus.urls")),
    path('logout/', LogoutView.as_view(), name='auth_logout'),
    path('silk/', include('silk.urls', namespace='silk')),
    path('api/password_reset/', include('django_rest_passwordreset.urls', namespace='password_reset')),
]
