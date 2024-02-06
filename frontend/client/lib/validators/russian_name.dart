class RussianNameValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Поле не может быть пустым';
    }

    final RegExp regex = RegExp(r'^[а-яА-Я\s]+$');
    if (!regex.hasMatch(value)) {
      return 'Пожалуйста, используйте символы русского алфавита';
    }

    return null;
  }
}
