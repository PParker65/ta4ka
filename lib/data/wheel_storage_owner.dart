const kStaffStorageLogin = 'admin';
const kShopJournalOwnerEmail = 'irinaogiyko@gmail.com';
const kShopJournalHydrateVersion = 'irina-v1';
const kWheelStoragePrefsKey = 'autoshift_wheel_storage_v1';
const kStorageDbName = 'autoshift_wheel_storage.db';

String normalizeStorageOwner(String login) => login.trim().toLowerCase();

bool isStaffStorageOwner(String login) =>
    normalizeStorageOwner(login) == kStaffStorageLogin;

/// Only this registered shop email receives the AutoShift journal copy.
bool isShopJournalRecipient(String login) =>
    normalizeStorageOwner(login) == kShopJournalOwnerEmail;

String sanitizeStorageOwner(String login) {
  final raw = normalizeStorageOwner(login);
  final buf = StringBuffer();
  var dashed = false;
  for (final code in raw.codeUnits) {
    final ok = (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57) ||
        code == 46 ||
        code == 95;
    if (ok) {
      buf.writeCharCode(code);
      dashed = false;
    } else if (!dashed && buf.isNotEmpty) {
      buf.write('_');
      dashed = true;
    }
  }
  var safe = buf.toString();
  if (safe.endsWith('_')) safe = safe.substring(0, safe.length - 1);
  if (safe.length > 80) safe = safe.substring(0, 80);
  return safe;
}

/// Legacy SharedPreferences blob stays on the staff login so the 29-lot
/// shop journal is not wiped or copied onto new emails.
String wheelStoragePrefsKeyFor(String ownerKey) {
  if (isStaffStorageOwner(ownerKey)) return kWheelStoragePrefsKey;
  final safe = sanitizeStorageOwner(ownerKey);
  return 'autoshift_wheel_storage_u_$safe';
}

String wheelStorageDbFileName(String ownerKey) {
  if (isStaffStorageOwner(ownerKey)) return kStorageDbName;
  return 'autoshift_wheel_storage_${sanitizeStorageOwner(ownerKey)}.db';
}
