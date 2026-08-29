import '../core/l10n/app_lang.dart';

/// Offline chat localizer: writer’s text → L for every app language.
/// Common service phrases get real translations; otherwise the original is kept
/// in all slots so the UI never blanks (online MT can replace this later).
abstract final class ChatTranslate {
  static L localize(String raw, AppLang writerLang) {
    final t = raw.trim();
    if (t.isEmpty) {
      return const L('', '', '', '');
    }
    final hit = _phrase(t);
    if (hit != null) {
      return hit;
    }
    // Heuristic: fill writer’s slot, mirror others with tagged original so
    // the other side still reads the intent until full MT is wired.
    final uk = writerLang == AppLang.uk ? t : _wrap(t, writerLang, AppLang.uk);
    final en = writerLang == AppLang.en ? t : _wrap(t, writerLang, AppLang.en);
    final ru = writerLang == AppLang.ru ? t : _wrap(t, writerLang, AppLang.ru);
    final pl = writerLang == AppLang.pl ? t : _wrap(t, writerLang, AppLang.pl);
    return L(uk, en, ru, pl);
  }

  static String _wrap(String t, AppLang from, AppLang to) {
    // Lightweight “translation”: common token swap, else pass-through.
    final swapped = _tokenSwap(t, to);
    if (swapped != t) {
      return swapped;
    }
    return t;
  }

  static L? _phrase(String t) {
    final key = t.toLowerCase().trim();
    for (final e in _phrases.entries) {
      if (e.key == key || e.value.uk.toLowerCase() == key ||
          e.value.en.toLowerCase() == key ||
          e.value.ru.toLowerCase() == key ||
          (e.value.pl ?? '').toLowerCase() == key) {
        return e.value;
      }
    }
    return null;
  }

  static String _tokenSwap(String t, AppLang to) {
    var out = t;
    for (final row in _tokens) {
      final repl = switch (to) {
        AppLang.uk => row.uk,
        AppLang.en => row.en,
        AppLang.ru => row.ru,
        AppLang.pl => row.pl,
      };
      for (final form in row.forms) {
        out = out.replaceAll(RegExp(form, caseSensitive: false), repl);
      }
    }
    return out;
  }
}

class _Tok {
  const _Tok(this.forms, this.uk, this.en, this.ru, this.pl);
  final List<String> forms;
  final String uk;
  final String en;
  final String ru;
  final String pl;
}

const _tokens = <_Tok>[
  _Tok(['смет[ауеы]?', 'кошторис\\w*', 'estimate', 'quote'], 'кошторис', 'estimate', 'смета', 'wycena'),
  _Tok(['готов\\w*', 'ready', 'готово'], 'готово', 'ready', 'готово', 'gotowe'),
  _Tok(['запчаст\\w*', 'parts?', 'детал\\w*'], 'запчастина', 'part', 'запчасть', 'część'),
  _Tok(['підйомник\\w*', 'lift', 'подъемник\\w*'], 'підйомник', 'lift', 'подъёмник', 'podnośnik'),
  _Tok(['дякую|спасибо|thanks|dziękuję'], 'дякую', 'thanks', 'спасибо', 'dziękuję'),
  _Tok(['добрий день|добрый день|good morning|dzień dobry'], 'Добрий день', 'Good day', 'Добрый день', 'Dzień dobry'),
];

final _phrases = <String, L>{
  'авто готове': const L('Авто готове', 'Car is ready', 'Авто готово', 'Auto gotowe'),
  'car is ready': const L('Авто готове', 'Car is ready', 'Авто готово', 'Auto gotowe'),
  'нужно согласовать смету': const L(
    'Потрібно погодити кошторис',
    'Need to approve the estimate',
    'Нужно согласовать смету',
    'Trzeba zatwierdzić wycenę',
  ),
  'need to approve the estimate': const L(
    'Потрібно погодити кошторис',
    'Need to approve the estimate',
    'Нужно согласовать смету',
    'Trzeba zatwierdzić wycenę',
  ),
  'їду на допомогу': const L(
    'Їду на допомогу',
    'On my way to help',
    'Еду на помощь',
    'Jadę z pomocą',
  ),
};
