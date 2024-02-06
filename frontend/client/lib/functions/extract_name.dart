String extractDisplayName(
    String fullName, String currentUserFirstName, String currentUserLastName) {
  // Разбиваем строку по разделителю "-"
  List<String> nameParts = fullName.split('-');

  // Проверяем, что список содержит две части
  if (nameParts.length == 2) {
    // Извлекаем часть, которая не равна имени и фамилии авторизованного пользователя
    String otherPart = nameParts[0].trim() == currentUserFirstName &&
            nameParts[1].trim() == currentUserLastName
        ? nameParts[0].trim()
        : nameParts[1].trim();

    return otherPart;
  }

  // Если список не содержит две части, возвращаем исходное имя
  return fullName;
}
