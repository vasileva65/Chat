class Auth {
  String userId;
  String token;
  String authError;
  bool authenticated;

  Auth(this.userId, this.token, this.authenticated, {this.authError = ''});
}
