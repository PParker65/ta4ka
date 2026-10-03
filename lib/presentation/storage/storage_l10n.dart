import '../../core/l10n/app_lang.dart';
import '../../domain/models/wheel_storage.dart';

class StorageL10n {
  const StorageL10n(this.lang);

  final AppLang lang;

  String _t(L value) => value.of(lang);

  static const fallbackBrand = 'AutoShift';

  String get brand => fallbackBrand;
  String get city => _t(const L('Варшава', 'Warsaw', 'Варшава', 'Warszawa'));
  String get title => _t(const L(
        'Зберігання шин і дисків',
        'Tire & wheel storage',
        'Хранение шин и дисков',
        'Przechowywanie opon i felg',
      ));
  String get subtitle => subtitleFor('');
  String get shopName => _t(const L(
        'Назва автосервісу',
        'Autoservice name',
        'Название автосервиса',
        'Nazwa warsztatu',
      ));
  String get shopNameHint => _t(const L(
        'Введіть назву вашого автосервісу',
        'Enter the name of your autoservice',
        'Введите название вашего автосервиса',
        'Wpisz nazwę swojego warsztatu',
      ));
  String get splashLead => _t(const L(
        'Додаток для зберігання шин і дисків',
        'An app for tire and wheel storage',
        'Приложение для хранения шин и дисков',
        'Aplikacja do przechowywania opon i felg',
      ));
  String subtitleFor(String shop) {
    final name = shop.trim();
    if (name.isEmpty) return title;
    return _t(L(
      '$name · облік комплектів',
      '$name · storage ledger',
      '$name · учёт комплектов',
      '$name · ewidencja',
    ));
  }
  String get accept => _t(const L('Прийняти на зберігання', 'Accept for storage', 'Принять на хранение', 'Przyjmij na magazyn'));
  String get release => _t(const L('Видати клієнту', 'Hand over', 'Выдать клиенту', 'Wydaj klientowi'));
  String get confirmRelease => _t(const L('Підтвердити видачу', 'Confirm handover', 'Подтвердить выдачу', 'Potwierdź wydanie'));
  String get search => _t(const L('Пошук', 'Search', 'Поиск', 'Szukaj'));
  String get searchHint => _t(const L(
        'Телефон, номер, VIN, імʼя…',
        'Phone, plate, VIN, name…',
        'Телефон, номер, VIN, имя…',
        'Telefon, tablica, VIN, imię…',
      ));
  String get phone => _t(const L('Телефон', 'Phone', 'Телефон', 'Telefon'));
  String get plate => _t(const L('Номер авто', 'License plate', 'Номер авто', 'Tablica'));
  String get vin => _t(const L('VIN', 'VIN', 'VIN', 'VIN'));
  String get firstName => _t(const L('Імʼя', 'First name', 'Имя', 'Imię'));
  String get lastName => _t(const L('Прізвище', 'Last name', 'Фамилия', 'Nazwisko'));
  String get vehicle => _t(const L('Авто', 'Vehicle', 'Авто', 'Samochód'));
  String get size => _t(const L('Розмір', 'Size', 'Размер', 'Rozmiar'));
  String get sizeAlt => _t(const L('Другий розмір', 'Second size', 'Второй размер', 'Drugi rozmiar'));
  String get rim => _t(const L('Діаметр, R', 'Rim, R', 'Диаметр, R', 'Średnica, R'));
  String get brandTire => _t(const L('Бренд гуми', 'Tire brand', 'Бренд резины', 'Marka opony'));
  String get notes => _t(const L('Нотатка', 'Note', 'Заметка', 'Notatka'));
  String get withRims => _t(const L('З дисками', 'With wheels', 'С дисками', 'Z felgami'));
  String get received => _t(const L('Прийнято', 'Received', 'Принято', 'Przyjęto'));
  String get returned => _t(const L('Видано', 'Returned', 'Выдано', 'Wydano'));
  String get active => _t(const L('На зберіганні', 'In storage', 'На хранении', 'Na magazynie'));
  String get archive => _t(const L('Видані', 'Handed over', 'Выданные', 'Wydane'));
  String get priceDay => _t(const L('Ціна за день', 'Price per day', 'Цена за день', 'Cena za dzień'));
  String get due => _t(const L('До сплати', 'Amount due', 'К оплате', 'Do zapłaty'));
  String get emptyActive => _t(const L(
        'На зберіганні нікого немає. Прийміть перший комплект.',
        'Nothing in storage. Accept the first set.',
        'На хранении никого нет. Примите первый комплект.',
        'Magazyn pusty. Przyjmij pierwszy komplet.',
      ));
  String get emptySearch => _t(const L(
        'Нічого не знайшли. Перевірте телефон, номер, VIN або імʼя.',
        'No match. Check phone, plate, VIN or name.',
        'Ничего не нашли. Проверьте телефон, номер, VIN или имя.',
        'Brak wyników. Sprawdź telefon, tablicę, VIN lub imię.',
      ));
  String get emptyArchive => _t(const L(
        'Поки немає виданих комплектів.',
        'No handed-over sets yet.',
        'Пока нет выданных комплектов.',
        'Brak wydanych kompletów.',
      ));
  String get save => _t(const L('Зберегти', 'Save', 'Сохранить', 'Zapisz'));
  String get cancel => _t(const L('Скасувати', 'Cancel', 'Отмена', 'Anuluj'));
  String get edit => _t(const L('Змінити', 'Edit', 'Изменить', 'Edytuj'));
  String get close => _t(const L('Закрити', 'Close', 'Закрыть', 'Zamknij'));
  String get done => _t(const L('Готово', 'Done', 'Готово', 'Gotowe'));
  String get receiptTitle => _t(const L('Чек зберігання', 'Storage receipt', 'Чек хранения', 'Paragon przechowywania'));
  String get thankYou => _t(const L('Дякуємо, що довірили нам колеса.', 'Thank you for trusting us with your wheels.', 'Спасибо, что доверили нам колёса.', 'Dziękujemy za zaufanie.'));
  String get dateUncertain => _t(const L(
        'Уточніть дату',
        'Confirm the date',
        'Уточните дату',
        'Ustal datę',
      ));
  String get calculate =>
      _t(const L('Порахувати', 'Calculate', 'Посчитать', 'Przelicz'));
  String get needDateToRelease => _t(const L(
        'Спочатку вкажіть дату приймання.',
        'Set the intake date first.',
        'Сначала укажите дату приёма.',
        'Najpierw podaj datę przyjęcia.',
      ));
  String get needIdentity => _t(const L(
        'Вкажіть хоча б номер авто, телефон, VIN або імʼя.',
        'Enter at least a plate, phone, VIN or name.',
        'Укажите хотя бы номер авто, телефон, VIN или имя.',
        'Podaj tablicę, telefon, VIN albo imię.',
      ));
  String get winter => _t(const L('Зима', 'Winter', 'Зима', 'Zima'));
  String get summer => _t(const L('Літо', 'Summer', 'Лето', 'Lato'));
  String get allSeason => _t(const L('Всесезон', 'All-season', 'Всесезон', 'Całoroczne'));
  String get kit => _t(const L('комплект', 'set', 'комплект', 'komplet'));
  String get pickDate => _t(const L('Дата приймання', 'Intake date', 'Дата приёма', 'Data przyjęcia'));
  String get owner => _t(const L('Клієнт', 'Customer', 'Клиент', 'Klient'));
  String get noSelection => _t(const L(
        'Виберіть комплект ліворуч або знайдіть клієнта.',
        'Select a set on the left or search for a customer.',
        'Выберите комплект слева или найдите клиента.',
        'Wybierz komplet po lewej albo znajdź klienta.',
      ));
  String get storedFor => _t(const L('Строк зберігання', 'Storage period', 'Срок хранения', 'Okres przechowywania'));
  String get perDay => _t(const L('за 1 день', 'per 1 day', 'за 1 день', 'za 1 dzień'));
  String get newLot => _t(const L('Новий комплект', 'New set', 'Новый комплект', 'Nowy komplet'));
  String get editLot => _t(const L('Картка комплекту', 'Set details', 'Карточка комплекта', 'Karta kompletu'));
  String get cellBusy =>
      _t(const L('Комірка зайнята', 'Cell occupied', 'Ячейка занята', 'Komórka zajęta'));
  String get cellFree =>
      _t(const L('вільно', 'free', 'свободно', 'wolne'));
  String get addSector => _t(const L(
        'Додати сектор',
        'Add sector',
        'Добавить сектор',
        'Dodaj sektor',
      ));
  String get removeSector => _t(const L(
        'Прибрати сектор',
        'Remove sector',
        'Убрать сектор',
        'Usuń sektor',
      ));
  String get deleteLot => _t(const L('Видалити', 'Delete', 'Удалить', 'Usuń'));
  String get editPrice => _t(const L(
        'Редагувати ціну',
        'Edit price',
        'Редактировать цену',
        'Edytuj cenę',
      ));
  String get personalPrice => _t(const L(
        'Особиста ціна',
        'Personal price',
        'Личная цена',
        'Cena indywidualna',
      ));
  String get personalPriceHint => _t(const L(
        'Тільки для цього клієнта. Загальна ціна його більше не змінить.',
        'Only this customer. The shop price will not change it later.',
        'Только для этого клиента. Общая цена его больше не изменит.',
        'Tylko dla tego klienta. Cena ogólna już go nie zmieni.',
      ));
  String get confirmDeleteLot => _t(const L(
        'Видалити цього клієнта зі списку? Місце на стелажі звільниться.',
        'Delete this customer from the list? Their rack slots will be freed.',
        'Удалить этого клиента из списка? Место на стеллаже освободится.',
        'Usunąć tego klienta z listy? Miejsca na regale się zwolnią.',
      ));
  String sectorOccupiedHint(int sector) => _t(L(
        'У секторі $sector ще лежать шини. Спочатку видайте або зніміть комплекти.',
        'Sector $sector still has tires. Take them off first.',
        'В секторе $sector ещё лежат шины. Сначала выдайте или уберите комплекты.',
        'W sektorze $sector nadal leżą opony. Najpierw wydaj lub zdejmij komplety.',
      ));
  String get heightSlots => _t(const L(
        'Колеса в ряду · 1–8',
        'Wheels in the row · 1–8',
        'Колёса в ряду · 1–8',
        'Koła w rzędzie · 1–8',
      ));
  String get needSlots => _t(const L(
        'Виберіть колеса 1–8 у цьому ряду.',
        'Pick wheels 1–8 in this row.',
        'Выберите колёса 1–8 в этом ряду.',
        'Wybierz koła 1–8 w tym rzędzie.',
      ));
  String slotTaken(String marker, int slot, String who) => _t(L(
        'У $marker місце $slot зайняте ($who). Виберіть інше.',
        'In $marker slot $slot is taken ($who). Pick another.',
        'В $marker место $slot занято ($who). Выберите другое.',
        'W $marker miejsce $slot zajęte ($who). Wybierz inne.',
      ));
  String slotNumbers(Set<int> slots) {
    final list = slots.toList()..sort();
    final text = list.join(', ');
    return _t(L(
      'місця $text',
      'slots $text',
      'места $text',
      'miejsca $text',
    ));
  }
  String sectorN(int n) => _t(L(
        'Сектор $n',
        'Sector $n',
        'Сектор $n',
        'Sektor $n',
      ));
  String get place => _t(const L('Місце', 'Place', 'Место', 'Miejsce'));
  String get row => _t(const L('Ряд', 'Row', 'Ряд', 'Rząd'));
  String get cargo => _t(const L('Що лежить', 'What is stored', 'Что лежит', 'Co leży'));
  String get cargoTires => _t(const L('Гума', 'Tires', 'Резина', 'Opony'));
  String get cargoTiresOnRims =>
      _t(const L('Диски з гумою', 'Wheels with tires', 'Диски с резиной', 'Felgi z oponami'));
  String get cargoRims =>
      _t(const L('Диски без гуми', 'Rims only', 'Диски без резины', 'Same felgi'));
  String get needPlace => _t(const L(
        'Виберіть сектор і ряд на стенді.',
        'Pick a sector and row on the stand.',
        'Выберите сектор и ряд на стенде.',
        'Wybierz sektor i rząd na regale.',
      ));
  String get needDate => _t(const L(
        'Вкажіть дату приймання.',
        'Enter the intake date.',
        'Укажите дату приёма.',
        'Podaj datę przyjęcia.',
      ));
  String cellTaken(String marker, String who) => _t(L(
        'Комірка $marker зайнята ($who). Виберіть іншу.',
        'Cell $marker is occupied ($who). Pick another.',
        'Ячейка $marker занята ($who). Выберите другую.',
        'Komórka $marker zajęta ($who). Wybierz inną.',
      ));
  String get fillMissing => _t(const L(
        'Вкажіть сектор, ряд, колеса 1–8 і що лежить: гума, диски з гумою або диски без гуми.',
        'Set sector, row, wheels 1–8 and cargo type.',
        'Укажите сектор, ряд, колёса 1–8 и что лежит: резина, диски с резиной или диски без резины.',
        'Podaj sektor, rząd, koła 1–8 i rodzaj.',
      ));
  String get guest =>
      _t(const L('Клієнт без імені', 'Unnamed customer', 'Клиент без имени', 'Klient bez imienia'));
  String rowN(int n) => _t(L('Ряд $n', 'Row $n', 'Ряд $n', 'Rząd $n'));
  String cellN(int n) => _t(L('Комірка $n', 'Cell $n', 'Ячейка $n', 'Komórka $n'));
  String get wheelCountLabel =>
      _t(const L('Скільки коліс', 'How many wheels', 'Сколько колёс', 'Ile kół'));
  String get needWheelCount => _t(const L(
        'Виберіть, скільки коліс стоїть у комірці. Не позначайте 8, якщо принесли менше.',
        'Choose how many wheels stand in the cell.',
        'Выберите, сколько колёс стоит в ячейке. Не отмечайте 8, если принесли меньше.',
        'Wybierz, ile kół stoi w komórce.',
      ));
  String get markPlace =>
      _t(const L('Вказати, де лежать', 'Mark on the stand', 'Указать, где лежат', 'Oznacz miejsce'));
  String wheelsN(int n) {
    if (lang == AppLang.en) return n == 1 ? '1 wheel' : '$n wheels';
    if (lang == AppLang.pl) {
      if (n == 1) return '1 koło';
      if (n >= 2 && n <= 4) return '$n koła';
      return '$n kół';
    }
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return '$n колесо';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return '$n колеса';
    }
    return lang == AppLang.uk ? '$n коліс' : '$n колёс';
  }

  String cargoLabel(StorageCargo cargo) {
    return switch (cargo) {
      StorageCargo.tires => cargoTires,
      StorageCargo.tiresOnRims => cargoTiresOnRims,
      StorageCargo.rims => cargoRims,
    };
  }

  String seasonLabel(TireSeason season) {
    return switch (season) {
      TireSeason.winter => winter,
      TireSeason.summer => summer,
      TireSeason.allSeason => allSeason,
    };
  }

  String daysCount(int n) {
    final abs = n.abs();
    final mod100 = abs % 100;
    final mod10 = abs % 10;
    if (lang == AppLang.en) {
      return n == 1 ? '1 day' : '$n days';
    }
    if (lang == AppLang.pl) {
      if (n == 1) return '1 dzień';
      if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
        return '$n dni';
      }
      return '$n dni';
    }
    String word;
    if (mod10 == 1 && mod100 != 11) {
      word = lang == AppLang.uk ? 'день' : 'день';
    } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      word = lang == AppLang.uk ? 'дні' : 'дня';
    } else {
      word = lang == AppLang.uk ? 'днів' : 'дней';
    }
    return '$n $word';
  }

  String spanLabel(StorageSpan span) {
    final bits = <String>[];
    if (span.years > 0) {
      bits.add(lang == AppLang.en
          ? '${span.years} y'
          : lang == AppLang.pl
              ? '${span.years} r.'
              : lang == AppLang.uk
                  ? '${span.years} р.'
                  : '${span.years} г.');
    }
    if (span.months > 0) {
      bits.add(lang == AppLang.en
          ? '${span.months} mo'
          : lang == AppLang.pl
              ? '${span.months} mies.'
              : lang == AppLang.uk
                  ? '${span.months} міс.'
                  : '${span.months} мес.');
    }
    if (span.restDays > 0 || bits.isEmpty) {
      bits.add(daysCount(span.restDays));
    }
    return '${daysCount(span.days)}  ·  ${bits.join(' ')}';
  }

  String weStored(int days) {
    final d = daysCount(days);
    return _t(L(
      'Ми зберігали вашу гуму $d.',
      'We stored your tires for $d.',
      'Мы хранили вашу резину $d.',
      'Przechowywaliśmy Państwa opony $d.',
    ));
  }

  String youOwe(String money) {
    return _t(L(
      'До сплати $money.',
      'Amount due $money.',
      'К оплате $money.',
      'Do zapłaty $money.',
    ));
  }

  String lotsOnHand(int n) {
    return _t(L(
      'На складі $n',
      '$n in storage',
      'На складе $n',
      'Na magazynie $n',
    ));
  }

  String formatDate(DateTime date) {
    const weekdays = [
      L('понеділок', 'Monday', 'понедельник', 'poniedziałek'),
      L('вівторок', 'Tuesday', 'вторник', 'wtorek'),
      L('середа', 'Wednesday', 'среда', 'środa'),
      L('четвер', 'Thursday', 'четверг', 'czwartek'),
      L('пʼятниця', 'Friday', 'пятница', 'piątek'),
      L('субота', 'Saturday', 'суббота', 'sobota'),
      L('неділя', 'Sunday', 'воскресенье', 'niedziela'),
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final weekday = weekdays[date.weekday - 1].of(lang);
    return '$day.$month.${date.year}, $weekday';
  }

  String formatIntake(DateTime? date) => date == null ? dateUncertain : formatDate(date);

  String get plannedPeriod => _t(const L(
        'На скільки ставлять',
        'How long they store',
        'На сколько ставят',
        'Na jak długo oddają',
      ));
  String get month1 => _t(const L('1 місяць', '1 month', '1 месяц', '1 miesiąc'));
  String get months3 => _t(const L('3 місяці', '3 months', '3 месяца', '3 miesiące'));
  String get months6 => _t(const L('6 місяців', '6 months', '6 месяцев', '6 miesięcy'));
  String get year1 => _t(const L('1 рік', '1 year', '1 год', '1 rok'));
  String get customDays => _t(const L('Свої дні', 'Custom days', 'Свои дни', 'Własne dni'));
  String get needPeriod => _t(const L(
        'Вкажіть, на який строк приймаєте комплект.',
        'Set how long the set will stay.',
        'Укажите, на какой срок принимаете комплект.',
        'Podaj, na jak długo przyjmujesz komplet.',
      ));
  String get until => _t(const L('До', 'Until', 'До', 'Do'));
  String get signed => _t(const L('Підпис', 'Signature', 'Подпись', 'Podpis'));
  String get policyTitle => _t(const L(
        'Договір зберігання',
        'Storage agreement',
        'Договор хранения',
        'Umowa przechowania',
      ));
  String get policyBody => _t(const L(
        'Якщо клієнт не забере комплект вчасно: два тижні штрафу за подвійною денною ціною, потім утилізація. Клієнт зобовʼязаний сплатити 1000 zł.\n\nПідпис на планшеті обовʼязковий. Без підпису і згоди комплект не приймаємо.',
        'If the customer does not collect on time: two weeks of penalty at 2× the daily price, then disposal. The customer must pay 1000 zł.\n\nA tablet signature is required. We cannot save the lot without a signature and agreement.',
        'Если клиент не заберёт комплект вовремя: две недели штрафа по двойной дневной цене, затем утилизация. Клиент обязан оплатить 1000 zł.\n\nПодпись на планшете обязательна. Без подписи и согласия комплект не принимаем.',
        'Jeśli klient nie odbierze kompletu na czas: dwa tygodnie kary w podwójnej cenie dziennej, potem utylizacja. Klient musi zapłacić 1000 zł.\n\nPodpis na tablecie jest obowiązkowy. Bez podpisu i zgody nie przyjmujemy kompletu.',
      ));
  String get contractDocTitle => _t(const L(
        'ДОГОВІР ЗБЕРІГАННЯ ШИН І ДИСКІВ',
        'TIRE AND WHEEL STORAGE AGREEMENT',
        'ДОГОВОР ХРАНЕНИЯ ШИН И ДИСКОВ',
        'UMOWA PRZECHOWYWANIA OPON I FELG',
      ));
  String get contractKeeper => _t(const L(
        'Зберігач',
        'Keeper',
        'Хранитель',
        'Przechowawca',
      ));
  String get contractClient => _t(const L(
        'Поклажодавець (клієнт)',
        'Depositor (customer)',
        'Поклажедатель (клиент)',
        'Składający (klient)',
      ));
  String get contractPrint => _t(const L('Друкувати', 'Print', 'Печатать', 'Drukuj'));
  String get contractSave => _t(const L('Зберегти', 'Save', 'Сохранить', 'Zapisz'));
  String get contractDone => _t(const L('Готово', 'Done', 'Готово', 'Gotowe'));
  String get contractReadFirst => _t(const L(
        'Прочитайте договір і поставте підпис у блоці нижче.',
        'Read the agreement and sign in the block below.',
        'Прочитайте договор и поставьте подпись в блоке ниже.',
        'Przeczytaj umowę i złóż podpis w bloku poniżej.',
      ));
  String get signedAt => _t(const L('Дата підпису', 'Signed on', 'Дата подписи', 'Data podpisu'));
  String get contractVersionLabel => _t(const L('Редакція', 'Version', 'Редакция', 'Wersja'));

  List<({String title, String body})> contractClauses({
    required String keeper,
    required String client,
    required String plate,
    required String vehicle,
    required String period,
    required String dailyFee,
    required String until,
    String periodTotal = '',
    int billedDays = 0,
  }) {
    final who = client.trim().isEmpty ? '—' : client.trim();
    final car = [
      if (vehicle.trim().isNotEmpty) vehicle.trim(),
      if (plate.trim().isNotEmpty) plate.trim(),
    ].join(', ');
    return [
      (
        title: _t(const L('1. Сторони', '1. Parties', '1. Стороны', '1. Strony')),
        body: _t(L(
          '$keeper («Зберігач») приймає на зберігання майно $who («Клієнт»). Підпис на цьому документі є акцептом оферти.',
          '$keeper (“Keeper”) accepts property from $who (“Customer”) for storage. A signature on this document is acceptance of the offer.',
          '$keeper («Хранитель») принимает на хранение имущество $who («Клиент»). Подпись на этом документе является акцептом оферты.',
          '$keeper («Przechowawca») przyjmuje na przechowanie mienie $who («Klient»). Podpis na tym dokumencie jest przyjęciem oferty.',
        )),
      ),
      (
        title: _t(const L('2. Предмет', '2. Subject', '2. Предмет', '2. Przedmiot')),
        body: _t(L(
          'Предмет договору — комплект шин і/або дисків${car.isEmpty ? '' : ' ($car)'} для сезонного зберігання на складі Зберігача у Варшаві.',
          'The subject is a set of tires and/or wheels${car.isEmpty ? '' : ' ($car)'} for seasonal storage at the Keeper’s warehouse in Warsaw.',
          'Предмет договора — комплект шин и/или дисков${car.isEmpty ? '' : ' ($car)'} для сезонного хранения на складе Хранителя в Варшаве.',
          'Przedmiotem umowy jest komplet opon i/lub felg${car.isEmpty ? '' : ' ($car)'} do sezonowego przechowywania w magazynie Przechowawcy w Warszawie.',
        )),
      ),
      (
        title: _t(const L('3. Строк і сума', '3. Period and amount', '3. Срок и сумма', '3. Okres i kwota')),
        body: _clause3Body(
          period: period,
          until: until,
          periodTotal: periodTotal,
          billedDays: billedDays,
        ),
      ),
      (
        title: _t(const L('4. Оплата', '4. Fees', '4. Оплата', '4. Opłaty')),
        body: _t(L(
          'Плата за зберігання: $dailyFee за кожну календарну добу від дати приймання до дати видачі включно, якщо дата приймання відома.',
          'Storage fee: $dailyFee for each calendar day from intake to handover inclusive, if the intake date is known.',
          'Плата за хранение: $dailyFee за каждые календарные сутки от даты приёмки до даты выдачи включительно, если дата приёмки известна.',
          'Opłata za przechowanie: $dailyFee za każdą dobę kalendarzową od przyjęcia do wydania włącznie, jeśli data przyjęcia jest znana.',
        )),
      ),
      (
        title: _t(const L('5. Прострочення', '5. Delay', '5. Просрочка', '5. Opóźnienie')),
        body: _t(const L(
          'Якщо Клієнт не забирає комплект після закінчення строку, протягом 14 днів нараховується штраф у розмірі подвійної денної плати за кожну добу прострочення.',
          'If the Customer does not collect the set after the period ends, for 14 days a penalty of twice the daily fee is charged for each day of delay.',
          'Если Клиент не забирает комплект после окончания срока, в течение 14 дней начисляется штраф в размере двойной дневной платы за каждые сутки просрочки.',
          'Jeśli Klient nie odbierze kompletu po upływie okresu, przez 14 dni naliczana jest kara w podwójnej stawce dziennej za każdą dobę opóźnienia.',
        )),
      ),
      (
        title: _t(const L('6. Утилізація', '6. Disposal', '6. Утилизация', '6. Utylizacja')),
        body: _t(const L(
          'Після цих 14 днів Зберігач має право утилізувати або реалізувати комплект. Клієнт зобовʼязаний сплатити 1000 zł витрат на утилізацію та розрахунок.',
          'After those 14 days the Keeper may dispose of or sell the set. The Customer must pay PLN 1000 for disposal and settlement.',
          'После этих 14 дней Хранитель вправе утилизировать или реализовать комплект. Клиент обязан оплатить 1000 zł расходов на утилизацию и расчёт.',
          'Po tych 14 dniach Przechowawca może zutylizować lub sprzedać komplet. Klient musi zapłacić 1000 zł kosztów utylizacji i rozliczenia.',
        )),
      ),
      (
        title: _t(const L('7. Підпис = згода', '7. Signature = acceptance', '7. Подпись = согласие', '7. Podpis = zgoda')),
        body: _t(const L(
          'Власноручний підпис на планшеті має силу простого електронного підпису. Без прочитання договору і підпису комплект на зберігання не приймається.',
          'A handwritten tablet signature has the effect of a simple electronic signature. The set is not accepted without reading and signing this agreement.',
          'Собственноручная подпись на планшете имеет силу простой электронной подписи. Без прочтения договора и подписи комплект на хранение не принимается.',
          'Własnoręczny podpis na tablecie ma moc zwykłego podpisu elektronicznego. Bez przeczytania umowy i podpisu kompletu nie przyjmujemy.',
        )),
      ),
    ];
  }
  String get policyAgree => _t(const L(
        'Клієнт прочитав і згоден',
        'Customer has read and agrees',
        'Клиент прочитал и согласен',
        'Klient przeczytał i zgadza się',
      ));
  String get policySign => _t(const L(
        'Підпис клієнта на планшеті',
        'Customer signature on the tablet',
        'Подпись клиента на планшете',
        'Podpis klienta na tablecie',
      ));
  String get needSignature => _t(const L(
        'Потрібен підпис на планшеті.',
        'A tablet signature is required.',
        'Нужна подпись на планшете.',
        'Wymagany jest podpis na tablecie.',
      ));
  String get needAgree => _t(const L(
        'Потрібно підтвердити згоду з умовами.',
        'Confirm agreement with the terms.',
        'Нужно подтвердить согласие с условиями.',
        'Potwierdź zgodę na warunki.',
      ));
  String get clearSign => _t(const L('Стерти', 'Clear', 'Стереть', 'Wyczyść'));
  String get confirmPolicy => _t(const L(
        'Підписати і прийняти',
        'Sign and accept',
        'Подписать и принять',
        'Podpisz i przyjmij',
      ));
  String get deskLoginTitle => _t(const L(
        'Вхід на склад',
        'Storage sign-in',
        'Вход на склад',
        'Logowanie do magazynu',
      ));
  String get deskLoginLead => _t(const L(
        'Пошта і пароль. Листа-підтвердження немає.',
        'Email and password. No confirmation letter.',
        'Почта и пароль. Письма-подтверждения нет.',
        'E-mail i hasło. Bez listu potwierdzenia.',
      ));
  String get registerNoticeTitle => _t(const L(
        'Перевірте пошту',
        'Check the email',
        'Проверьте почту',
        'Sprawdź e-mail',
      ));
  String get registerNoticeBody => _t(const L(
        'Перевірте, що електронна пошта написана правильно.\n\nSMS на пошту не надсилається.\n\nВажливо не втратити логін і пароль — листа для відновлення немає.',
        'Check that the email is spelled correctly.\n\nSMS is NOT sent to email.\n\nDo not lose your login and password — there is no recovery letter.',
        'Проверьте, что электронная почта написана правильно.\n\nSMS на почту не приходит.\n\nВажно не потерять логин и пароль — письма для восстановления нет.',
        'Sprawdź, czy adres e-mail jest wpisany poprawnie.\n\nSMS nie jest wysyłany na e-mail.\n\nNie zgub loginu i hasła — nie ma listu odzyskiwania.',
      ));
  String get registerNoticeContinue =>
      _t(const L('Зрозуміло', 'Got it', 'Понятно', 'Rozumiem'));
  String get email => _t(const L('Електронна пошта', 'Email', 'Электронная почта', 'E-mail'));
  String get password => _t(const L('Пароль', 'Password', 'Пароль', 'Hasło'));
  String get passwordAgain => _t(const L('Пароль ще раз', 'Password again', 'Пароль ещё раз', 'Hasło ponownie'));
  String get signIn => _t(const L('Увійти', 'Sign in', 'Войти', 'Zaloguj się'));
  String get register => _t(const L('Реєстрація', 'Register', 'Регистрация', 'Rejestracja'));
  String get profile => _t(const L('Профіль', 'Profile', 'Профиль', 'Profil'));
  String get logout => _t(const L('Вийти', 'Log out', 'Выйти', 'Wyloguj'));
  String get changePassword =>
      _t(const L('Змінити пароль', 'Change password', 'Сменить пароль', 'Zmień hasło'));
  String get currentPassword =>
      _t(const L('Поточний пароль', 'Current password', 'Текущий пароль', 'Aktualne hasło'));
  String get newPassword =>
      _t(const L('Новий пароль', 'New password', 'Новый пароль', 'Nowe hasło'));
  String get passwordChanged => _t(const L(
        'Пароль змінено',
        'Password changed',
        'Пароль изменён',
        'Hasło zmienione',
      ));
  String get wrongPassword => _t(const L(
        'Невірний поточний пароль',
        'Wrong current password',
        'Неверный текущий пароль',
        'Błędne aktualne hasło',
      ));
  String get needPassword => _t(const L(
        'Введіть поточний і новий пароль',
        'Enter the current and new password',
        'Введите текущий и новый пароль',
        'Wpisz aktualne i nowe hasło',
      ));
  String get passwordShort => _t(const L(
        'Пароль має містити щонайменше 8 символів',
        'Password must be at least 8 characters',
        'Пароль должен содержать минимум 8 символов',
        'Hasło musi mieć co najmniej 8 znaków',
      ));
  String get passwordMismatch => _t(const L(
        'Паролі не збігаються',
        'Passwords do not match',
        'Пароли не совпадают',
        'Hasła nie są takie same',
      ));
  String get passwordFailed => _t(const L(
        'Не вдалося змінити пароль. Спробуйте ще раз.',
        'Could not change the password. Try again.',
        'Не удалось сменить пароль. Попробуйте ещё раз.',
        'Nie udało się zmienić hasła. Spróbuj ponownie.',
      ));
  String plannedLabel(int days) {
    return switch (days) {
      30 => month1,
      90 => months3,
      180 => months6,
      365 => year1,
      _ => daysCount(days),
    };
  }

  String _clause3Body({
    required String period,
    required String until,
    required String periodTotal,
    required int billedDays,
  }) {
    final untilBit = until.isEmpty ? '' : _t(L(
      ' Планова дата закінчення: $until.',
      ' Planned end date: $until.',
      ' Плановая дата окончания: $until.',
      ' Planowana data zakończenia: $until.',
    ));
    final daysBit = billedDays > 0 ? ' (${daysCount(billedDays)})' : '';
    final money = periodTotal.trim().isEmpty ? '—' : periodTotal.trim();
    return _t(L(
      'Строк зберігання: $period$daysBit.$untilBit За цей строк зберігання до сплати $money. Якщо заберете раніше — плата перераховується за фактичні дні (невикористані не тарифікуються).',
      'Storage period: $period$daysBit.$untilBit For this storage period you owe $money. If you collect earlier, the charge is recalculated by actual days (unused days are not billed).',
      'Срок хранения: $period$daysBit.$untilBit За этот срок хранения к оплате $money. Если заберёте раньше — плата пересчитывается по фактическим дням (неиспользованные не тарифицируются).',
      'Okres przechowania: $period$daysBit.$untilBit Za ten okres przechowania do zapłaty $money. Przy wcześniejszym odbiorze opłata jest przeliczana według faktycznych dni (niewykorzystane nie są naliczane).',
    ));
  }

  String get extendStorage => _t(const L(
        'Продовжити зберігання',
        'Extend storage',
        'Продлить хранение',
        'Przedłuż przechowanie',
      ));
  String get extraDays => _t(const L(
        'Додаткові дні',
        'Extra days',
        'Дополнительные дни',
        'Dodatkowe dni',
      ));
  String get newEndDate => _t(const L(
        'Нова дата закінчення',
        'New end date',
        'Новая дата окончания',
        'Nowa data zakończenia',
      ));
  String get payPaid => _t(const L('Оплачено', 'Paid', 'Оплачено', 'Opłacono'));
  String get payAccrue => _t(const L(
        'Продовжити рахувати',
        'Keep accruing',
        'Продолжить считать',
        'Liczyć dalej',
      ));
  String get payPartial => _t(const L(
        'Частково оплачено',
        'Partially paid',
        'Частично оплачено',
        'Częściowo opłacono',
      ));
  String get paidAmount => _t(const L('Сплачено', 'Paid', 'Оплачено', 'Wpłacono'));
  String get remainingDue => _t(const L('Залишок', 'Remaining', 'Остаток', 'Pozostało'));
  String get paymentStatus => _t(const L('Оплата', 'Payment', 'Оплата', 'Płatność'));
  String get enterPartial => _t(const L(
        'Сума часткової оплати',
        'Partial payment amount',
        'Сумма частичной оплаты',
        'Kwota częściowej wpłaty',
      ));
  String get splashHud => _t(const L(
        'СХОВИЩЕ · ШИНИ · ДИСКИ',
        'STORAGE · TIRES · WHEELS',
        'СКЛАД · ШИНЫ · ДИСКИ',
        'MAGAZYN · OPONY · FELGI',
      ));
  String get dragRack => _t(const L(
        'Потягніть шторку, щоб відкрити стелаж',
        'Pull the shutter to open the rack',
        'Потяните шторку, чтобы открыть стеллаж',
        'Pociągnij żaluzję, aby otworzyć regał',
      ));

  String payStatusLabel(StoragePayStatus status) {
    return switch (status) {
      StoragePayStatus.paid => payPaid,
      StoragePayStatus.partial => payPartial,
      StoragePayStatus.accruing => payAccrue,
    };
  }
}

/// Header / rack / receipt lockup. AutoShift only for staff `admin` without a shop.
String resolveStorageShopName({
  required String displayName,
  required String login,
  String shopName = '',
}) {
  final shop = shopName.trim();
  if (shop.isNotEmpty) return shop;
  final shown = displayName.trim();
  if (shown.isNotEmpty && !shown.contains('@')) return shown;
  if (login.trim().toLowerCase() == 'admin') return StorageL10n.fallbackBrand;
  return '';
}

String formatZloty(int grosze) {
  final zloty = grosze / 100;
  final raw = zloty.toStringAsFixed(2).replaceAll('.', ',');
  final parts = raw.split(',');
  final whole = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final fromEnd = whole.length - i;
    buf.write(whole[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buf.write(' ');
    }
  }
  return '${buf.toString()},${parts[1]} zł';
}

int parseZlotyToGrosze(String raw) {
  final cleaned = raw.trim().replaceAll('zł', '').replaceAll(' ', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return 0;
  final value = double.tryParse(cleaned);
  if (value == null) return 0;
  return (value * 100).round();
}
