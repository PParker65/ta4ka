import 'package:flutter/widgets.dart';

enum AppLang { uk, en, ru, pl }

extension AppLangX on AppLang {
  Locale get locale => Locale(code);

  String get code => switch (this) {
        AppLang.uk => 'uk',
        AppLang.en => 'en',
        AppLang.ru => 'ru',
        AppLang.pl => 'pl',
      };

  String get label => switch (this) {
        AppLang.uk => 'UA',
        AppLang.en => 'EN',
        AppLang.ru => 'RU',
        AppLang.pl => 'PL',
      };

  static AppLang fromCode(String? code) {
    return AppLang.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLang.uk,
    );
  }
}

class L {
  const L(this.uk, this.en, this.ru, [this.pl]);

  final String uk;
  final String en;
  final String ru;
  /// Optional Polish; falls back to English when omitted.
  final String? pl;

  String of(AppLang lang) => switch (lang) {
        AppLang.uk => uk,
        AppLang.en => en,
        AppLang.ru => ru,
        AppLang.pl => pl ?? en,
      };
}
