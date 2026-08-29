import 'telegram_webapp_stub.dart'
    if (dart.library.html) 'telegram_webapp_web.dart' as impl;

class TelegramUser {
  const TelegramUser({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    this.username,
    this.languageCode,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String? username;
  final String? languageCode;

  String get displayName {
    final parts = [firstName, lastName].where((p) => p.trim().isNotEmpty);
    if (parts.isNotEmpty) return parts.join(' ');
    final nick = username?.trim();
    if (nick != null && nick.isNotEmpty) return '@$nick';
    return 'Telegram';
  }
}

class TelegramInsets {
  const TelegramInsets({
    this.top = 0,
    this.bottom = 0,
    this.left = 0,
    this.right = 0,
  });

  static const zero = TelegramInsets();

  final double top;
  final double bottom;
  final double left;
  final double right;

  bool get isEmpty => top == 0 && bottom == 0 && left == 0 && right == 0;
}

abstract class TelegramWebApp {
  static final TelegramWebApp instance = impl.createTelegramWebApp();

  bool get active;
  TelegramUser? get user;
  String get startParam;
  TelegramInsets get insets;

  void ready();
  void expand();
  void hapticLight();
  void setBackVisible(bool visible);
  void onBack(void Function() handler);
  void onInsets(void Function(TelegramInsets insets) handler);
  void close();
}
