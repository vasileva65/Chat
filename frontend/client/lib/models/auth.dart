class Auth {
  String userId;
  String token;
  String refreshToken;
  String authError;
  bool authenticated;

  Auth(this.userId, this.token, this.refreshToken, this.authenticated,
      {this.authError = ''});
}
