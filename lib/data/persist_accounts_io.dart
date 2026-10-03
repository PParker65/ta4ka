import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'local_account.dart';

Database? _db;

Future<Database> _open() async {
  final existing = _db;
  if (existing != null) return existing;
  try {
    final dir = await getApplicationDocumentsDirectory();
    _db = sqlite3.open(p.join(dir.path, 'kolesasave_accounts.db'));
  } catch (_) {
    _db = sqlite3.openInMemory();
  }
  _db!.execute('''
    CREATE TABLE IF NOT EXISTS accounts (
      email TEXT PRIMARY KEY,
      display_name TEXT NOT NULL,
      salt TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL
    );
  ''');
  return _db!;
}

Future<List<LocalAccount>> loadSqliteAccounts() async {
  try {
    final db = await _open();
    return db.select('SELECT * FROM accounts').map((row) {
      final display = row['display_name'] as String;
      return LocalAccount(
        email: row['email'] as String,
        displayName: display,
        salt: row['salt'] as String,
        passwordHash: row['password_hash'] as String,
        role: row['role'] as String,
        shopName: display.contains('@') ? '' : display,
      );
    }).toList();
  } catch (_) {
    return const [];
  }
}

Future<void> saveSqliteAccounts(List<LocalAccount> accounts) async {
  try {
    final db = await _open();
    db.execute('DELETE FROM accounts');
    final insert = db.prepare(
      'INSERT INTO accounts (email, display_name, salt, password_hash, role) VALUES (?, ?, ?, ?, ?)',
    );
    try {
      for (final account in accounts) {
        insert.execute([
          account.email,
          account.displayName,
          account.salt,
          account.passwordHash,
          account.role,
        ]);
      }
    } finally {
      insert.dispose();
    }
  } catch (_) {}
}
