class AuthSession {
  const AuthSession({
    required this.displayName,
    required this.login,
    required this.role,
    this.password = '',
    this.avatarBase64,
  });

  final String displayName;
  final String login;
  final String role;
  final String password;
  final String? avatarBase64;

  bool get isShop =>
      role == 'shop_admin' || role == 'master' || role == 'receptionist';
  bool get isShopAdmin => role == 'shop_admin';
  bool get isOwner => role == 'shop_admin';
  bool get isReceptionist => role == 'receptionist';
  bool get isMaster => role == 'master';
  bool get isClient => role == 'client';

  AuthSession copyWith({
    String? displayName,
    String? login,
    String? role,
    String? password,
    String? avatarBase64,
    bool clearAvatar = false,
  }) {
    return AuthSession(
      displayName: displayName ?? this.displayName,
      login: login ?? this.login,
      role: role ?? this.role,
      password: password ?? this.password,
      avatarBase64: clearAvatar ? null : (avatarBase64 ?? this.avatarBase64),
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'login': login,
        'role': role,
        'password': password,
        'avatarBase64': avatarBase64,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      displayName: json['displayName'] as String? ?? '',
      login: json['login'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      password: json['password'] as String? ?? '',
      avatarBase64: json['avatarBase64'] as String?,
    );
  }
}
