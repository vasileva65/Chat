from django.urls import path, include
from rest_framework.routers import DefaultRouter
from chat import views

# Create a router and register our viewsets with it.
router = DefaultRouter()
router.register(r'users', views.UserViewSet,basename="user")
router.register(r'messages', views.MessageViewSet,basename="message")
router.register(r'chats', views.ChatViewSet,basename="chat")

# The API URLs are now determined automatically by the router.
urlpatterns = [
    path('', include(router.urls)),
]