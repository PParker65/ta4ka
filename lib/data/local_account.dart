class LocalAccount {
  const LocalAccount({
    required this.email,
    required this.displayName,
    required this.salt,
    required this.passwordHash,
    this.role = 'storage',
    this.shopName = '',
  });

  final String email;
  final String displayName;
  final String salt;
  final String passwordHash;
  final String role;
  final String shopName;

  /// Shop name saved at registration. Email leftovers are ignored.
  String get resolvedShopName {
    final shop = shopName.trim();
    if (shop.isNotEmpty) return shop;
    final display = displayName.trim();
    if (display.isNotEmpty && !display.contains('@')) return display;
    return '';
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'salt': salt,
        'passwordHash': passwordHash,
        'role': role,
        'shopName': shopName,
      };

  factory LocalAccount.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as String? ?? '';
    final shopName = (json['shopName'] as String? ?? '').trim();
    return LocalAccount(
      email: (json['email'] as String? ?? '').trim().toLowerCase(),
      displayName: displayName,
      salt: json['salt'] as String? ?? '',
      passwordHash: json['passwordHash'] as String? ?? '',
      role: json['role'] as String? ?? 'storage',
      shopName: shopName,
    );
  }
}
