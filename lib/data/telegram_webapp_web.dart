// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js_util' as js;

import 'telegram_webapp.dart';

TelegramWebApp createTelegramWebApp() => _WebTelegramWebApp();

dynamic _webApp() {
  try {
    final tg = js.getProperty(html.window, 'Telegram');
    if (tg == null) return null;
    return js.getProperty(tg, 'WebApp');
  } catch (_) {
    return null;
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

String _asString(dynamic value) {
  if (value == null) return '';
  return '$value';
}

class _WebTelegramWebApp implements TelegramWebApp {
  void Function()? _back;
  void Function(TelegramInsets)? _insetsHandler;
  bool _listening = false;

  @override
  bool get active {
    final wa = _webApp();
    if (wa == null) return false;
    final init = _asString(js.getProperty(wa, 'initData'));
    if (init.isNotEmpty) return true;
    final platform = _asString(js.getProperty(wa, 'platform')).toLowerCase();
    return platform.isNotEmpty && platform != 'unknown';
  }

  @override
  TelegramUser? get user {
    final wa = _webApp();
    if (wa == null) return null;
    try {
      final unsafe = js.getProperty(wa, 'initDataUnsafe');
      if (unsafe == null) return null;
      final raw = js.getProperty(unsafe, 'user');
      if (raw == null) return null;
      final id = _asInt(js.getProperty(raw, 'id'));
      if (id == null) return null;
      final nick = _asString(js.getProperty(raw, 'username'));
      final lang = _asString(js.getProperty(raw, 'language_code'));
      return TelegramUser(
        id: id,
        firstName: _asString(js.getProperty(raw, 'first_name')),
        lastName: _asString(js.getProperty(raw, 'last_name')),
        username: nick.isEmpty ? null : nick,
        languageCode: lang.isEmpty ? null : lang,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  String get startParam {
    final wa = _webApp();
    if (wa != null) {
      try {
        final unsafe = js.getProperty(wa, 'initDataUnsafe');
        if (unsafe != null) {
          final fromUnsafe = _asString(js.getProperty(unsafe, 'start_param'));
          if (fromUnsafe.isNotEmpty) return fromUnsafe;
        }
        final fromWa = _asString(js.getProperty(wa, 'initDataUnsafe') != null
            ? js.getProperty(js.getProperty(wa, 'initDataUnsafe'), 'start_param')
            : '');
        if (fromWa.isNotEmpty) return fromWa;
      } catch (_) {}
    }
    final uri = Uri.base;
    for (final key in const ['tgWebAppStartParam', 'startapp', 'start']) {
      final v = uri.queryParameters[key];
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    final hash = uri.fragment;
    if (hash.isNotEmpty) {
      final q = Uri.splitQueryString(hash.startsWith('?') ? hash.substring(1) : hash);
      for (final key in const ['tgWebAppStartParam', 'startapp', 'start']) {
        final v = q[key];
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
    }
    return '';
  }

  @override
  TelegramInsets get insets {
    final wa = _webApp();
    if (wa == null) return TelegramInsets.zero;
    dynamic raw;
    try {
      raw = js.getProperty(wa, 'contentSafeAreaInset');
    } catch (_) {}
    if (raw == null) {
      try {
        raw = js.getProperty(wa, 'safeAreaInset');
      } catch (_) {}
    }
    if (raw == null) return TelegramInsets.zero;
    try {
      return TelegramInsets(
        top: _asDouble(js.getProperty(raw, 'top')),
        bottom: _asDouble(js.getProperty(raw, 'bottom')),
        left: _asDouble(js.getProperty(raw, 'left')),
        right: _asDouble(js.getProperty(raw, 'right')),
      );
    } catch (_) {
      return TelegramInsets.zero;
    }
  }

  @override
  void ready() {
    final wa = _webApp();
    if (wa == null) return;
    try {
      js.callMethod(wa, 'ready', []);
      js.callMethod(wa, 'expand', []);
      js.callMethod(wa, 'setHeaderColor', ['#07070A']);
      js.callMethod(wa, 'setBackgroundColor', ['#07070A']);
    } catch (_) {}
    try {
      js.callMethod(wa, 'disableVerticalSwipes', []);
    } catch (_) {}
    _listen();
  }

  @override
  void expand() {
    final wa = _webApp();
    if (wa == null) return;
    try {
      js.callMethod(wa, 'expand', []);
    } catch (_) {}
  }

  @override
  void hapticLight() {
    final wa = _webApp();
    if (wa == null) return;
    try {
      final hf = js.getProperty(wa, 'HapticFeedback');
      if (hf != null) js.callMethod(hf, 'impactOccurred', ['light']);
    } catch (_) {}
  }

  @override
  void setBackVisible(bool visible) {
    final wa = _webApp();
    if (wa == null) return;
    try {
      final bb = js.getProperty(wa, 'BackButton');
      if (bb == null) return;
      js.callMethod(bb, visible ? 'show' : 'hide', []);
    } catch (_) {}
  }

  @override
  void onBack(void Function() handler) {
    _back = handler;
    final wa = _webApp();
    if (wa == null) return;
    try {
      final bb = js.getProperty(wa, 'BackButton');
      if (bb == null) return;
      js.callMethod(bb, 'onClick', [
        js.allowInterop(() {
          _back?.call();
        }),
      ]);
    } catch (_) {}
  }

  @override
  void onInsets(void Function(TelegramInsets insets) handler) {
    _insetsHandler = handler;
    _listen();
  }

  @override
  void close() {
    final wa = _webApp();
    if (wa == null) return;
    try {
      js.callMethod(wa, 'close', []);
    } catch (_) {}
  }

  void _listen() {
    if (_listening) return;
    final wa = _webApp();
    if (wa == null) return;
    _listening = true;
    void notify(_) {
      _insetsHandler?.call(insets);
    }

    try {
      final cb = js.allowInterop(notify);
      js.callMethod(wa, 'onEvent', ['viewportChanged', cb]);
      js.callMethod(wa, 'onEvent', ['safeAreaChanged', cb]);
      js.callMethod(wa, 'onEvent', ['contentSafeAreaChanged', cb]);
    } catch (_) {}
  }
}
