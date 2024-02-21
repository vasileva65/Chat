class UserProfile {
  int userId;
  String username;
  String name;
  String lastname;
  String middlename;
  String avatar;
  UserProfile(this.userId, this.username, this.name, this.lastname,
      this.middlename, this.avatar);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
