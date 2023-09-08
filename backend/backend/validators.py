import gzip
import os
import re
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _


class NumberValidator(object):
    def  __init__ (self,  min_digits = 0): 
        self.min_digits  =  min_digits 
    
    def validate(self, password, user=None):
        if not re.findall('\d', password):
            raise ValidationError(
                _("Пароль должен содерать хотя бы одну цифру от 0 до 9."),
                code='password_no_number',
            )

    def get_help_text(self):
        return _(
            "Пароль должен содерать хотя бы одну цифру от 0 до 9."
        )


class CharacterValidator(object):
    def validate(self, password, user=None):
        if not re.findall('[a-z]', password):
            raise ValidationError(
                _("Пароль должен содержать хотя бы одну букву латинского алфавита."),
                code='password_no_lower',
            )

    def get_help_text(self):
        return _(
            "Пароль должен содержать хотя бы одну букву латинского алфавита."
        )


class SymbolValidator(object):
    def validate(self, password, user=None):
        if not re.findall('[()[\]{}|\\`~!@#$%^&*_\-+=;:\'",<>./?]', password):
            raise ValidationError(
                _("Пароль должен содержать хотя бы один символ: " +
                  "()[]{}|\`~!@#$%^&*_-+=;:'\",<>./?"),
                code='password_no_symbol',
            )

    def get_help_text(self):
        return _(
            "Пароль должен содержать хотя бы один символ: " +
            "()[]{}|\`~!@#$%^&*_-+=;:'\",<>./?"
        )
    
class CommonPasswordValidator:
    
    DEFAULT_PASSWORD_LIST_PATH = os.path.join(
        os.path.dirname(os.path.realpath(__file__)), 'common-passwords.txt.gz'
    )

    def __init__(self, password_list_path=DEFAULT_PASSWORD_LIST_PATH):
        try:
            with gzip.open(password_list_path) as f:
                common_passwords_lines = f.read().decode().splitlines()
        except IOError:
            with open(password_list_path) as f:
                common_passwords_lines = f.readlines()

        self.passwords = {p.strip() for p in common_passwords_lines}

    def validate(self, password, user=None):
        if password.lower().strip() in self.passwords:
            raise ValidationError(
                _("Этот пароль слишком распространен."),
                code='password_too_common',
            )

    def get_help_text(self):
        return _("Your password can't be a commonly used password.")