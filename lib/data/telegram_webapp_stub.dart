import 'telegram_webapp.dart';

TelegramWebApp createTelegramWebApp() => _StubTelegramWebApp();

class _StubTelegramWebApp implements TelegramWebApp {
  @override
  bool get active => false;

  @override
  TelegramUser? get user => null;

  @override
  String get startParam => '';

  @override
  TelegramInsets get insets => TelegramInsets.zero;

  @override
  void ready() {}

  @override
  void expand() {}

  @override
  void hapticLight() {}

  @override
  void setBackVisible(bool visible) {}

  @override
  void onBack(void Function() handler) {}

  @override
  void onInsets(void Function(TelegramInsets insets) handler) {}

  @override
  void close() {}
}
