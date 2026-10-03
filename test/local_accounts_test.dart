import 'package:autoservice/data/local_accounts.dart';
import 'package:autoservice/data/password_hash.dart';
import 'package:autoservice/presentation/storage/storage_l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('password hash is not plaintext and verifies', () {
    const password = 'Secret1234';
    final salt = newPasswordSalt();
    final hash = hashPassword(password, salt);
    expect(hash, isNot(password));
    expect(hash.contains(password), isFalse);
    expect(verifyPassword(password: password, salt: salt, expectedHash: hash), isTrue);
    expect(verifyPassword(password: 'wrong', salt: salt, expectedHash: hash), isFalse);
  });

  test('register then new store instance can login from prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final first = LocalAccountStore.instance;
    await first.init();
    await first.register(
      email: 'desk@kolesasave.com',
      password: 'Storage99',
      displayName: 'Desk',
      shopName: 'Pit Stop',
    );
    expect(first.exists('desk@kolesasave.com'), isTrue);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kLocalAccountsPrefsKey);
    expect(raw, isNotNull);
    expect(raw!.contains('Storage99'), isFalse);
    expect(raw.contains('desk@kolesasave.com'), isTrue);

    await LocalAccountStore.instance.resetForTest();
    final hit = await LocalAccountStore.instance.authenticate(
      'desk@kolesasave.com',
      'Storage99',
    );
    expect(hit, isNotNull);
    expect(hit!.email, 'desk@kolesasave.com');
    expect(hit.shopName, 'Pit Stop');
    expect(hit.resolvedShopName, 'Pit Stop');
    expect(raw.contains('Pit Stop'), isTrue);
    expect(
      await LocalAccountStore.instance.authenticate('desk@kolesasave.com', 'nope'),
      isNull,
    );
  });

  test('storage brand uses shop name and AutoShift only for admin', () {
    expect(
      resolveStorageShopName(displayName: 'Pit Stop', login: 'desk@x.com'),
      'Pit Stop',
    );
    expect(
      resolveStorageShopName(displayName: 'admin@x.com', login: 'admin'),
      'AutoShift',
    );
    expect(
      resolveStorageShopName(displayName: '', login: 'admin'),
      'AutoShift',
    );
    expect(
      resolveStorageShopName(displayName: 'desk@x.com', login: 'desk@x.com'),
      '',
    );
  });
}
