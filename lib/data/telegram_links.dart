import 'open_link.dart';
import 'telegram_webapp.dart';

/// BotFather username without @. Override at build:
/// `--dart-define=APEX_TG_BOT=your_bot --dart-define=APEX_TG_APP=app`
const kTelegramBotUsername = String.fromEnvironment(
  'APEX_TG_BOT',
  defaultValue: 'chip365auto_bot',
);

const kTelegramAppShortName = String.fromEnvironment(
  'APEX_TG_APP',
  defaultValue: 'app',
);

bool get hasTelegramBot => kTelegramBotUsername.trim().isNotEmpty;

String telegramMiniAppUrl({String? start}) {
  final bot = kTelegramBotUsername.trim();
  if (bot.isEmpty) return 'https://t.me';
  final base = 'https://t.me/$bot/$kTelegramAppShortName';
  final param = (start ?? '').trim();
  if (param.isEmpty) return base;
  return '$base?startapp=$param';
}

void openTelegramMiniApp({String? start}) {
  if (TelegramWebApp.instance.active) return;
  openLink(telegramMiniAppUrl(start: start));
}
