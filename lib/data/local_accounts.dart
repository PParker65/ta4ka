import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_account.dart';
import 'password_hash.dart';
import 'persist_accounts_stub.dart'
    if (dart.library.io) 'persist_accounts_io.dart' as persist;

export 'local_account.dart';

const kLocalAccountsPrefsKey = 'kolesasave_local_accounts_v1';

class LocalAccountStore {
  LocalAccountStore._();

  static final LocalAccountStore instance = LocalAccountStore._();

  final Map<String, LocalAccount> _accounts = {};
  var _ready = false;

  Future<void> resetForTest() async {
    _accounts.clear();
    _ready = false;
    await init();
  }

  Future<void> init() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    _readPrefs(prefs);
    for (final account in await persist.loadSqliteAccounts()) {
      if (account.email.isEmpty) continue;
      final existing = _accounts[account.email];
      final shop = (existing?.shopName.trim().isNotEmpty ?? false)
          ? existing!.shopName
          : account.shopName;
      final shown = (existing?.displayName.trim().isNotEmpty ?? false)
          ? existing!.displayName
          : account.displayName;
      _accounts[account.email] = LocalAccount(
        email: account.email,
        displayName: shown,
        salt: account.salt,
        passwordHash: account.passwordHash,
        role: account.role,
        shopName: shop,
      );
    }
    await _flush(prefs);
    _ready = true;
  }

  Future<void> _ensure() async {
    if (!_ready) await init();
  }

  void _readPrefs(SharedPreferences prefs) {
    final raw = prefs.getString(kLocalAccountsPrefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return;
      for (final item in list) {
        if (item is! Map) continue;
        final account = LocalAccount.fromJson(Map<String, dynamic>.from(item));
        if (account.email.isEmpty) continue;
        _accounts[account.email] = account;
      }
    } catch (_) {}
  }

  Future<void> _flush([SharedPreferences? existing]) async {
    final prefs = existing ?? await SharedPreferences.getInstance();
    final list = _accounts.values.map((item) => item.toJson()).toList();
    await prefs.setString(kLocalAccountsPrefsKey, jsonEncode(list));
    await persist.saveSqliteAccounts(_accounts.values.toList());
  }

  String normalize(String raw) => raw.trim().toLowerCase();

  bool looksLikeEmail(String raw) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalize(raw));
  }

  LocalAccount? find(String email) => _accounts[normalize(email)];

  bool exists(String email) => find(email) != null;

  Future<LocalAccount> register({
    required String email,
    required String password,
    String displayName = '',
    String role = 'storage',
    String shopName = '',
  }) async {
    await _ensure();
    final key = normalize(email);
    if (!looksLikeEmail(key)) {
      throw const LocalAccountException('email');
    }
    if (password.length < 8) {
      throw const LocalAccountException('weak');
    }
    if (_accounts.containsKey(key)) {
      throw const LocalAccountException('exists');
    }
    final salt = newPasswordSalt();
    final shop = shopName.trim();
    final shown = displayName.trim().isEmpty
        ? (shop.isEmpty ? key : shop)
        : displayName.trim();
    final account = LocalAccount(
      email: key,
      displayName: shown,
      salt: salt,
      passwordHash: hashPassword(password, salt),
      role: role,
      shopName: shop,
    );
    _accounts[key] = account;
    await _flush();
    return account;
  }

  Future<LocalAccount?> authenticate(String email, String password) async {
    await _ensure();
    final account = find(email);
    if (account == null) return null;
    if (!verifyPassword(
      password: password,
      salt: account.salt,
      expectedHash: account.passwordHash,
    )) {
      return null;
    }
    return account;
  }
}

class LocalAccountException implements Exception {
  const LocalAccountException(this.code);

  final String code;
}
