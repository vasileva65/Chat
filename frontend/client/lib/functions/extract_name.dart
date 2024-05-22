String extractDisplayName(
    String fullName, String currentUserFirstName, String currentUserLastName) {
  // Разбиваем строку по разделителю "-"
  List<String> nameParts = fullName.split('-');
  print("NAME PARTS");
  print(nameParts);

  // Проверяем, что список содержит две части
  if (nameParts.length == 2) {
    String part1 = nameParts[0].trim();
    String part2 = nameParts[1].trim();
    print("PARTS: $part1, $part2");

    // Проверяем, какая часть не соответствует имени и фамилии авторизованного пользователя
    if ((part1.contains(currentUserFirstName) &&
            part1.contains(currentUserLastName)) &&
        !(part2.contains(currentUserFirstName) &&
            part2.contains(currentUserLastName))) {
      print("IF 1");
      return part2; // part1 соответствует имени и фамилии, значит возвращаем part2
    } else if ((part2.contains(currentUserFirstName) &&
            part2.contains(currentUserLastName)) &&
        !(part1.contains(currentUserFirstName) &&
            part1.contains(currentUserLastName))) {
      print("IF 2");
      return part1; // part2 соответствует имени и фамилии, значит возвращаем part1
    } else if (!(part1.contains(currentUserFirstName) &&
        part1.contains(currentUserLastName))) {
      print("IF 3");
      return part1; // part1 не соответствует имени и фамилии, значит возвращаем part1
    } else if (!(part2.contains(currentUserFirstName) &&
        part2.contains(currentUserLastName))) {
      print("IF 4");
      return part2; // part2 не соответствует имени и фамилии, значит возвращаем part2
    }
  }

  // Если список не содержит две части или не удалось определить, возвращаем исходное имя
  return fullName;
}
