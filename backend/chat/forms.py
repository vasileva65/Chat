from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from django import forms
from django.contrib.auth import get_user_model
#from .models import User
User = get_user_model()

class CustomUserCreationForm(UserCreationForm):

    def clean_username(self):
        username = self.cleaned_data['username']
        try:
            User.objects.get(username=username)
        except User.DoesNotExist:
            return username
        raise forms.ValidationError(self.error_messages['duplicate_username'])

    class Meta:
        model = User
        fields = ('username',)

class CustomUserChangeForm(UserChangeForm):

    class Meta:
        model = User
        fields = ('username',)