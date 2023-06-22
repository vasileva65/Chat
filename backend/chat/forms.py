from django.contrib.auth.forms import UserCreationForm, UserChangeForm

from django.contrib.auth import get_user_model
User = get_user_model()

class CustomUserCreationForm(UserCreationForm):

    class Meta:
        model = User
        fields = ('username',)

class CustomUserChangeForm(UserChangeForm):

    class Meta:
        model = User
        fields = ('middle_name',)