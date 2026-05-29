class AuthSession {
  final String userId;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: (json['id'] ?? '').toString(),
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
    );
  }
}
