import 'app_lang.dart';
import 'pl_pack.dart';

class AppStrings {
  const AppStrings(this.lang);

  final AppLang lang;

  String _l(L value) {
    if (lang == AppLang.pl) {
      return polishFromEnglish(value.en, value.pl);
    }
    return value.of(lang);
  }

  String get appTitle =>
      _l(const L('Ta4ka', 'Ta4ka', 'Ta4ka'));
  String get appSubtitle => _l(const L(
        'Автономна система замість майстра-приймача',
        'Autonomous system that replaces the service advisor',
        'Автономная система вместо мастера-приемщика',
      ));
  String get kiosk =>
      _l(const L('Клієнтський термінал', 'Customer kiosk', 'Клиентский терминал'));
  String get kioskHint => _l(const L(
        'Самостійний вибір послуг і заказ-наряд',
        'Self-service jobs and work order',
        'Самостоятельный выбор услуг и заказ-наряд',
      ));
  String get clientKiosk =>
      _l(const L('Кіоск клієнта', 'Client Kiosk View', 'Киоск клиента'));
  String get clientKioskHint => _l(const L(
        'Термінал самообслуговування: запис, ціни в ₴ і оцінка візиту',
        'Self-service terminal: booking, UAH prices and visit rating',
        'Терминал самообслуживания: запись, цены в ₴ и оценка визита',
      ));
  String get clientKioskWelcome => _l(const L(
        'Вітаємо в автосервісі',
        'Welcome to the autoservice',
        'Добро пожаловать в автосервис',
      ));
  String get clientKioskLead => _l(const L(
        'Оберіть мову, послуги та тариф у гривнях. Система підкаже, що перевірити до старту робіт.',
        'Choose a language, services and a UAH price tier. The system notes what to check before work starts.',
        'Выберите язык, услуги и тариф в гривнах. Система подскажет, что проверить до старта работ.',
      ));
  String get startBooking =>
      _l(const L('Почати запис', 'Start booking', 'Начать запись'));
  String get pricesInUah => _l(const L(
        'Усі ціни в гривнях: Базовий · Стандарт · Преміум',
        'All prices in hryvnia: Basic · Standard · Premium',
        'Все цены в гривнах: Базовый · Стандарт · Премиум',
      ));
  String get skipRating =>
      _l(const L('Пропустити', 'Skip', 'Пропустить'));
  String get yourOrder =>
      _l(const L('Ваш заказ-наряд', 'Your work order', 'Ваш заказ-наряд'));
  String get howWasVisit => _l(const L(
        'Як минув запис?',
        'How was the booking?',
        'Как прошла запись?',
      ));
  String starLabel(int stars) {
    return switch (stars) {
      1 => _l(const L('Жахливо', 'Terrible', 'Ужасно')),
      2 => _l(const L('Погано', 'Poor', 'Плохо')),
      3 => _l(const L('Нормально', 'Average', 'Нормально')),
      4 => _l(const L('Добре', 'Good', 'Хорошо')),
      _ => _l(const L('Відмінно', 'Excellent', 'Отлично')),
    };
  }
  String get writeReview => _l(const L(
        'Напишіть відгук (необовʼязково)',
        'Write a review (optional)',
        'Напишите отзыв (необязательно)',
      ));
  String get workshop =>
      _l(const L('Панель керування', 'Control panel', 'Панель управления'));
  String get workshopHint => _l(const L(
        'Записи, чат з клієнтом, камера боксу, послуги',
        'Bookings, client chat, bay camera, services',
        'Записи, чат с клиентом, камера бокса, услуги',
      ));
  String get ratings =>
      _l(const L('Лояльність і рейтинг', 'Loyalty & rating', 'Лояльность и рейтинг'));
  String get ratingsHint => _l(const L(
        'Оцінки клієнтів і якість роботи',
        'Customer scores and work quality',
        'Оценки клиентов и качество работы',
      ));
  String get language => _l(const L('Мова', 'Language', 'Язык'));
  String get next => _l(const L('Далі', 'Next', 'Далее'));
  String get back => _l(const L('Назад', 'Back', 'Назад'));
  String get confirm => _l(const L('Підтвердити', 'Confirm', 'Подтвердить'));
  String get home => _l(const L('На головну', 'Home', 'На главную'));
  String get stepOf => _l(const L('Крок {0} з {1}', 'Step {0} of {1}', 'Шаг {0} из {1}'));
  String formatStep(int current, int total) =>
      stepOf.replaceFirst('{0}', '$current').replaceFirst('{1}', '$total');

  String get step1Title => _l(const L(
        'Ідентифікація авто',
        'Vehicle identification',
        'Идентификация авто',
      ));
  String get plate => _l(const L('Держномер', 'License plate', 'Госномер'));
  String get plateHint => _l(const L(
        'АА 1234 ВВ',
        'AA 1234 BB',
        'АА 1234 ВВ',
      ));
  String get plateTitle => _l(const L(
        'Номер телефону і держномер',
        'Phone and license plate',
        'Номер телефона и госномер',
      ));
  String get plateLead => _l(const L(
        'Підтвердіть авто — потім відкриємо реєстрацію',
        'Confirm the car — then we open registration',
        'Подтвердите авто — затем откроем регистрацию',
      ));
  String get registerDetailsTitle => _l(const L(
        'Дані для реєстрації',
        'Registration details',
        'Данные для регистрации',
      ));
  String get registerDetailsLead => _l(const L(
        'Імʼя, логін і пароль — і одразу в кабінет',
        'Name, login and password — then you are in',
        'Имя, логин и пароль — и сразу в кабинет',
      ));
  String get phone => _l(const L('Телефон', 'Phone', 'Телефон'));
  String get brand => _l(const L('Марка', 'Make', 'Марка'));
  String get model => _l(const L('Модель', 'Model', 'Модель'));
  String get mileage => _l(const L('Пробіг', 'Mileage', 'Пробег'));
  String get vin => _l(const L('VIN', 'VIN', 'VIN'));
  String get km => _l(const L('км', 'km', 'км'));
  String get requiredField =>
      _l(const L('Обовʼязкове поле', 'Required field', 'Обязательное поле'));
  String get loginTitle => _l(const L('Вхід', 'Sign in', 'Вход'));
  String get welcome =>
      _l(const L('Ласкаво просимо', 'Welcome', 'Добро пожаловать'));
  String welcomeUser(String name) => _l(const L(
        'Ласкаво просимо, {0}',
        'Welcome, {0}',
        'Добро пожаловать, {0}',
      )).replaceFirst('{0}', name);
  String get login => _l(const L('Логін', 'Login', 'Логин'));
  String get password => _l(const L('Пароль', 'Password', 'Пароль'));
  String get signIn => _l(const L('Увійти', 'Sign in', 'Войти'));
  String get register =>
      _l(const L('Реєстрація', 'Register', 'Регистрация'));
  String get displayName =>
      _l(const L('Імʼя', 'Display name', 'Имя'));
  String get shopName =>
      _l(const L('Назва СТО', 'Shop name', 'Название СТО'));
  String get shopLoginTitle => _l(const L(
        'Кабінет автосервісу',
        'Shop desk',
        'Кабинет автосервиса',
      ));
  String get forAutoservices => _l(const L(
        'Вхід / Реєстрація для автосервісів',
        'Sign in / Register for autoservices',
        'Вход / Регистрация для автосервисов',
      ));
  String get loginError => _l(const L(
        'Введіть логін і пароль',
        'Enter login and password',
        'Введите логин и пароль',
      ));
  String get aiQuickTitle => _l(const L(
        'Що зробити з авто?',
        'What should we do to the car?',
        'Что сделать с авто?',
        'Co zrobić z autem?',
      ));
  String get aiQuickLead => _l(const L(
        'Напишіть словами, що потрібно',
        'Write in your own words what to do',
        'Напишите своими словами, что нужно',
        'Napisz własnymi słowami, co zrobić',
      ));
  String get aiQuickHint => _l(const L(
        'Напишіть словами, що потрібно — підберемо категорію і СТО поруч',
        'Write in your own words what you need — we match a category and a nearby shop',
        'Напишите своими словами, что нужно — подберём категорию и СТО рядом',
      ));
  String get aiQuickFieldHint => _l(const L(
        'Напишіть тут, що зробити…',
        'Type here what to do…',
        'Напишите здесь, что сделать…',
        'Napisz tutaj, co zrobić…',
      ));
  String get aiQuickPhoto => _l(const L('Додати фото', 'Add photo', 'Добавить фото'));
  String get aiQuickPhotoDone => _l(const L('Фото додано', 'Photo added', 'Фото добавлено'));
  String get aiQuickAnalyze => _l(const L(
        'Знайти СТО',
        'Find shops',
        'Найти СТО',
      ));
  List<String> get aiQuickExamples => switch (lang) {
        AppLang.uk => const [
              'ПОМИЛКИ',
              'Check Engine',
              'Стук',
              'Перегрів',
              'Дим з вихлопу',
            ],
        AppLang.en => const [
              'ERRORS',
              'Check Engine',
              'Knock',
              'Overheat',
              'Exhaust smoke',
            ],
        AppLang.ru => const [
              'ОШИБКИ',
              'Check Engine',
              'Стуки',
              'Перегрев',
              'Дым из выхлопа',
            ],
        AppLang.pl => const [
              'BŁĘDY',
              'Check Engine',
              'Stuki',
              'Przegrzanie',
              'Dym z wydechu',
            ],
      };
  String get aiQuickSelect => _l(const L(
        'Оберіть пункт ремонту',
        'Choose repair option',
        'Выберите пункт ремонта',
      ));
  String get aiQuickContinue =>
      _l(const L('Далі на головну', 'Continue to home', 'Далее на главную'));
  String get aiQuickNeedOption => _l(const L(
        'Оберіть варіант зі списку',
        'Pick one option from list',
        'Выберите один вариант из списка',
      ));
  String get aiSpheresHighlight => _l(const L(
        'Рекомендовано',
        'Recommended',
        'Рекомендовано',
      ));
  String get aiSpheresList => _l(const L(
        'Усі категорії',
        'All categories',
        'Все категории',
      ));
  String get aiSpheresResults => _l(const L(
        'Результати пошуку',
        'Search results',
        'Результаты поиска',
      ));
  String get aiBackToAll => _l(const L(
        'Назад до всіх послуг',
        'Back to all services',
        'Назад ко всем услугам',
      ));
  String get aiPhotoAttached => _l(const L(
        'Фото додано. Використаємо для діагностики.',
        'Photo attached. It will be used for diagnostics.',
        'Фото добавлено. Используем для диагностики.',
      ));
  String get aiCarHint => _l(const L(
        'Двома пальцями наблизьте деталь, потім натисніть на неї — з\'явиться підказка.',
        'Pinch to zoom onto a part, then tap it — a hint will appear.',
        'Двумя пальцами приблизьте деталь, затем нажмите на неё — появится подсказка.',
      ));
  String get aiCarZoomHint => _l(const L(
        'Спочатку наблизьте машину, потім натисніть на деталь',
        'Zoom in first, then tap the part',
        'Сначала приблизьте машину, затем нажмите на деталь',
      ));
  String get aiCarOfflineTitle => _l(const L(
        'Немає інтернету',
        'No internet',
        'Нет интернета',
      ));
  String get aiCarOfflineHint => _l(const L(
        'Увімкніть Wi‑Fi або мобільні дані — 3D-машина завантажиться автоматично',
        'Turn on Wi‑Fi or mobile data — the 3D car will load automatically',
        'Включите Wi‑Fi или мобильный интернет — 3D-машина загрузится автоматически',
      ));
  String get aiCarLoading => _l(const L(
        'Завантаження 3D-машини…',
        'Loading 3D car…',
        'Загрузка 3D-машины…',
      ));
  String get aiZoomCabin => _l(const L(
        'Приблизте колесо миші, щоб увійти в салон',
        'Scroll to zoom into the cabin',
        'Приблизьте колесо мыши, чтобы войти в салон',
      ));
  String get aiExitCabin => _l(const L(
        'До кузова',
        'Back to body',
        'К кузову',
      ));
  String get aiRepair => _l(const L('Ремонт', 'Repair', 'Ремонт'));
  String get aiReplace => _l(const L('Заміна', 'Replace', 'Замена'));
  String get aiTune => _l(const L('Тюнінг', 'Tune', 'Тюнинг'));
  String get aiCabinHint => _l(const L(
        'Огляд салону 360°. Натисніть кермо, ГУ або сидіння',
        '360° cabin. Tap the wheel, head unit or a seat',
        'Обзор салона 360°. Нажмите руль, ГУ или сиденье',
      ));
  String get aiBrandTitle => _l(const L(
        'Марка твого авто?',
        'What is your car brand?',
        'Марка твоего авто?',
      ));
  String get aiBrandHint => _l(const L(
        'Почніть писати — зрозуміємо навіть з помилкою',
        'Start typing — we will recognize even a misspell',
        'Начните писать — поймем даже с ошибкой',
      ));
  String get aiBrandNext => _l(const L('Далі', 'Next', 'Далее'));
  String brandPickerCount(int count) => _l(L(
        '$count марок з 3D — гортайте, крутіть, приближайте',
        '$count brands with 3D — swipe, spin, pinch to zoom',
        '$count марок с 3D — листайте, крутите, приближайте',
      ));
  String get aiBrandSpinHint => _l(const L(
        'Пальцем крутіть машину · колесо / pinch приближає',
        'Drag to spin · scroll or pinch to zoom',
        'Пальцем крутите машину · колесо / pinch приближает',
      ));
  String get aiSwitchBrand => _l(const L(
        'Змінити марку',
        'Switch brand',
        'Сменить марку',
      ));
  String get aiSwitchBrandHint => _l(const L(
        'Оберіть іншу модель — 3D-машина оновиться одразу',
        'Pick another brand — the 3D model updates instantly',
        'Выберите другую марку — 3D-машина обновится сразу',
      ));
  String get aiOpenDoor => _l(const L(
        'Відкрити двері',
        'Open door',
        'Открыть дверь',
      ));
  String get aiCloseDoor => _l(const L(
        'Закрити двері',
        'Close door',
        'Закрыть дверь',
      ));
  String get passwordShort => _l(const L(
        'Пароль має містити щонайменше 8 символів',
        'Password must be at least 8 characters',
        'Пароль должен содержать минимум 8 символов',
      ));
  String get themeGuy => _l(const L(
        'Чорна · для хлопця',
        'Dark · for him',
        'Чёрная · для парня',
        'Ciemna · dla chłopaka',
      ));
  String get themeGirl => _l(const L(
        'Світла · для дівчинки',
        'Light · for her',
        'Светлая · для девочки',
        'Jasna · dla dziewczynki',
      ));
  String get profile => _l(const L('Профіль', 'Profile', 'Профиль'));
  String get profileAccount => _l(const L('Акаунт', 'Account', 'Аккаунт'));
  String get profileSecurity => _l(const L('Безпека', 'Security', 'Безопасность'));
  String get profileChangePassword =>
      _l(const L('Змінити пароль', 'Change password', 'Сменить пароль'));
  String get profileCurrentPassword =>
      _l(const L('Поточний пароль', 'Current password', 'Текущий пароль'));
  String get profileNewPassword =>
      _l(const L('Новий пароль', 'New password', 'Новый пароль'));
  String get profileConfirmPassword =>
      _l(const L('Ще раз новий', 'Confirm new', 'Ещё раз новый'));
  String get profilePasswordMismatch => _l(const L(
        'Нові паролі не збігаються',
        'New passwords do not match',
        'Новые пароли не совпадают',
      ));
  String get profilePasswordWrong => _l(const L(
        'Невірний пароль',
        'Wrong password',
        'Неверный пароль',
      ));
  String get profilePasswordChanged => _l(const L(
        'Пароль оновлено',
        'Password updated',
        'Пароль обновлён',
      ));
  String get profileChangePhoto =>
      _l(const L('Змінити фото', 'Change photo', 'Сменить фото'));
  String get profileTakePhoto =>
      _l(const L('Камера', 'Camera', 'Камера'));
  String get profileChoosePhoto =>
      _l(const L('Галерея', 'Gallery', 'Галерея'));
  String get profileRemovePhoto =>
      _l(const L('Прибрати фото', 'Remove photo', 'Убрать фото'));
  String get profileName => _l(const L('Імʼя', 'Name', 'Имя'));
  String get profileNameChanged =>
      _l(const L('Імʼя збережено', 'Name saved', 'Имя сохранено'));
  String get profileGarage => _l(const L('Гараж', 'Garage', 'Гараж'));
  String get profileFindShop =>
      _l(const L('Знайти СТО', 'Find a shop', 'Найти СТО'));
  String get profileSupport => _l(const L('Підтримка', 'Support', 'Поддержка'));
  String get profileCall =>
      _l(const L('Зателефонувати', 'Call us', 'Позвонить'));
  String get profileEmail => _l(const L('Написати', 'Email us', 'Написать'));
  String get profileHelp =>
      _l(const L('Як записатися', 'How to book', 'Как записаться'));
  String get profileHelpBody => _l(const L(
        '1. На вкладці Авто оберіть марку і категорію — там опис робіт і ціна «від».\n2. У СТО відкрийте Ta4ka Варшава під цю категорію: години Пн–Сб 09:00–18:00, слоти щогодини.\n3. Оберіть послуги, майстра і час. Статус, камера боксу і звіт — у Записах.\n4. Запчастини в ціні «від» не входять, якщо не зазначено інакше.',
        '1. On Car, pick your brand and a category — you will see the job description and a “from” price.\n2. In Shops, open Ta4ka Warsaw for that category: Mon–Sat 09:00–18:00, hourly slots.\n3. Choose jobs, a technician and a time. Status, bay camera and the report are in Bookings.\n4. The “from” price is labour unless parts are listed as included.',
        '1. Во вкладке Авто выберите марку и категорию — там описание работ и цена «от».\n2. В СТО откройте Ta4ka Варшава под эту категорию: часы Пн–Сб 09:00–18:00, слоты каждый час.\n3. Выберите услуги, мастера и время. Статус, камера бокса и отчёт — в Записях.\n4. В цене «от» нет запчастей, если не указано иное.',
      ));
  String get profileVersion =>
      _l(const L('Ta4ka · демо 1.0', 'Ta4ka · demo 1.0', 'Ta4ka · демо 1.0'));
  String get profileCancel => _l(const L('Скасувати', 'Cancel', 'Отмена'));
  String get profileSave => _l(const L('Зберегти', 'Save', 'Сохранить'));
  String get profileLook => _l(const L('Вигляд', 'Look', 'Вид'));
  String get profileHours =>
      _l(const L('Години підтримки', 'Support hours', 'Часы поддержки'));
  String get profileHoursValue => _l(const L(
        'Щодня 9:00–21:00 · Варшава',
        'Daily 9:00–21:00 · Warsaw',
        'Ежедневно 9:00–21:00 · Варшава',
      ));
  String get telegramOpen => _l(const L(
        'Відкрити в Telegram',
        'Open in Telegram',
        'Открыть в Telegram',
        'Otwórz w Telegramie',
      ));
  String get telegramOpenLead => _l(const L(
        'Той самий Ta4ka: запис, СТО, США, наряди',
        'The same Ta4ka: booking, shops, USA, work orders',
        'Тот же Ta4ka: запись, СТО, США, наряды',
        'Ten sam Ta4ka: wizyty, warsztaty, USA, zlecenia',
      ));
  String get telegramConnected => _l(const L(
        'Увійти через Telegram',
        'Signed in with Telegram',
        'Вход через Telegram',
        'Zalogowano przez Telegram',
      ));
  String telegramContinueAs(String name) => _l(L(
        'Продовжити як $name',
        'Continue as $name',
        'Продолжить как $name',
        'Kontynuuj jako $name',
      ));
  String get telegramMiniAppBadge =>
      _l(const L('Telegram Mini App', 'Telegram Mini App', 'Telegram Mini App'));
  String get profileCopied =>
      _l(const L('Скопійовано', 'Copied', 'Скопировано'));
  String get profilePhotoError => _l(const L(
        'Не вдалося відкрити фото. Спробуй галерею.',
        'Could not open the photo. Try the gallery.',
        'Не удалось открыть фото. Попробуй галерею.',
      ));
  String profileWalletNext(int left, String payout) => _l(L(
        'Ще $left + до $payout',
        '$left + left to $payout',
        'Ещё $left + до $payout',
      ));
  String get rateQuality =>
      _l(const L('Якість ремонту', 'Repair quality', 'Качество ремонта'));
  String get ratePoliteness =>
      _l(const L('Ввічливість', 'Politeness', 'Вежливость'));
  String get ratePunctuality =>
      _l(const L('Дотримання строків', 'On time', 'Соблюдение сроков'));
  String get rateCleanliness =>
      _l(const L('Чистота', 'Cleanliness', 'Чистота'));
  String get whatsWrong =>
      _l(const L('Що не так?', 'What is wrong?', 'Что не так?'));
  String get whatWant => _l(const L(
        'Що хочете отримати?',
        'What do you want?',
        'Что хотите получить?',
      ));
  String get year => _l(const L('Рік', 'Year', 'Год'));
  String get carShort => _l(const L(
        'Авто: номер, марка, модель, рік',
        'Car: plate, make, model, year',
        'Авто: номер, марка, модель, год',
      ));
  String get symptomNoise =>
      _l(const L('Стуки / шум', 'Knocks / noise', 'Стуки / шум'));
  String get symptomBrakes =>
      _l(const L('Слабкі гальма', 'Weak brakes', 'Слабые тормоза'));
  String get symptomElectrics =>
      _l(const L('Електрика / помилка', 'Electrics / warning', 'Электрика / ошибка'));
  String get symptomEngine =>
      _l(const L('Двигун', 'Engine', 'Двигатель'));
  String get symptomTo =>
      _l(const L('Пора на ТО', 'Due for service', 'Пора на ТО'));
  String get symptomUnknown =>
      _l(const L('Не зрозуміло', 'Not sure', 'Не понятно'));
  String get symptomHeadlight => _l(const L(
        'Привʼязати фару / зняти захист',
        'Pair a headlight / remove cover',
        'Привязать фару / снять защиту',
      ));
  String get symptomEcu =>
      _l(const L('Прошивка ECU', 'ECU flashing', 'Прошивка ECU'));
  String get symptomRoadside => _l(const L(
        'Зламався на трасі',
        'Broke down on the road',
        'Сломался на трассе',
      ));
  String get wantDiag =>
      _l(const L('Знайти причину', 'Find the cause', 'Найти причину'));
  String get wantRepair =>
      _l(const L('Відремонтувати', 'Repair it', 'Отремонтировать'));
  String get wantTo =>
      _l(const L('Пройти ТО', 'Do maintenance', 'Пройти ТО'));
  String get wantCoding =>
      _l(const L('Кодування / прошивка', 'Coding / flashing', 'Кодирование / прошивка'));
  String get pickOptions => _l(const L(
        'Оберіть варіанти нижче',
        'Choose the options below',
        'Выберите варианты ниже',
      ));
  String get logout => _l(const L('Вийти', 'Log out', 'Выйти'));

  String get step2Title => _l(const L(
        'Категорія ремонту',
        'Repair category',
        'Категория ремонта',
      ));
  String get catDiag => _l(const L('Діагностика', 'Diagnostics', 'Диагностика'));
  String get catChassis =>
      _l(const L('Ходова частина', 'Chassis / suspension', 'Ходовая часть'));
  String get catElectrical => _l(const L(
        'Електрика / Кодування',
        'Electrics / coding',
        'Электрика / Кодирование',
      ));
  String get catMaintenance =>
      _l(const L('ТО та заміна рідин', 'Maintenance & fluids', 'ТО и замена жидкостей'));
  String get catEngine => _l(const L('Двигун', 'Engine', 'Двигатель'));

  String get step3Title => _l(const L(
        'Підбір робіт і запчастин',
        'Jobs and parts selection',
        'Подбор работ и запчастей',
      ));
  String get step3Hint => _l(const L(
        'Оберіть тариф. Система запамʼятає актуальну ціну в ₴.',
        'Choose a tier. The system remembers the latest UAH price.',
        'Выберите тариф. Система запомнит актуальную цену в ₴.',
      ));
  String get tierBasic => _l(const L('Базовий', 'Basic', 'Базовый'));
  String get tierStandard => _l(const L('Стандарт', 'Standard', 'Стандарт'));
  String get tierPremium => _l(const L('Преміум', 'Premium', 'Премиум'));
  String get rememberedPrice =>
      _l(const L('Актуальна ціна', 'Latest price', 'Актуальная цена'));

  String get step4Title => _l(const L(
        'Попередній заказ-наряд',
        'Draft work order',
        'Предварительный заказ-наряд',
      ));
  String get total => _l(const L('Разом', 'Total', 'Итого'));
  String get eta =>
      _l(const L('Орієнтовний час', 'Estimated time', 'Ориентировочное время'));
  String get minutesShort => _l(const L('хв', 'min', 'мин'));
  String get submitOrder =>
      _l(const L('Створити заявку', 'Create job', 'Создать заявку'));
  String get inspectBody =>
      _l(const L('Огляд кузова', 'Body inspection', 'Осмотр кузова'));
  String get noWorks => _l(const L(
        'Оберіть хоча б одну роботу',
        'Select at least one job',
        'Выберите хотя бы одну работу',
      ));
  String get orderCreated =>
      _l(const L('Заявку створено', 'Job created', 'Заявка создана'));

  String get olegTitle =>
      _l(const L('Примітка майстра', 'Technician note', 'Примечание мастера'));
  String get olegIntro => _l(const L(
        'Коротко, що перевіряємо разом із роботою: живлення, сумісність запчастин, що не входить у ціну.',
        'A short note on what we check with the job: power supply, parts compatibility, what the price does not cover.',
        'Кратко, что проверяем вместе с работой: питание, совместимость запчастей, что не входит в цену.',
      ));

  String get inspectionTitle => _l(const L(
        'Огляд автомобіля (чекіст)',
        'Vehicle inspection checklist',
        'Осмотр автомобиля (чеклист)',
      ));
  String get inspectionHint => _l(const L(
        'Позначте пошкодження на схемі та додайте фото.',
        'Mark damage on the diagram and attach photos.',
        'Отметьте повреждения на схеме и добавьте фото.',
      ));
  String get attachPhoto =>
      _l(const L('Прикріпити фото', 'Attach photos', 'Прикрепить фото'));
  String get camera => _l(const L('Камера', 'Camera', 'Камера'));
  String get gallery => _l(const L('Галерея', 'Gallery', 'Галерея', 'Galeria'));
  String get files => _l(const L('Файли', 'Files', 'Файлы'));
  String get fuel => _l(const L('Рівень пального', 'Fuel level', 'Уровень топлива'));
  String get resetInspection =>
      _l(const L('Скинути огляд', 'Reset inspection', 'Сбросить осмотр'));
  String get saveInspection =>
      _l(const L('Зберегти огляд', 'Save inspection', 'Сохранить осмотр'));
  String get scratch => _l(const L('Подряпина', 'Scratch', 'Царапина'));
  String get dent => _l(const L('Вмʼятина', 'Dent', 'Вмятина'));
  String get defect => _l(const L('Дефект', 'Defect', 'Дефект'));
  String get tapZone => _l(const L(
        'Натисніть зону на схемі, потім тип пошкодження.',
        'Tap a body zone, then choose the damage type.',
        'Нажмите зону на схеме, затем тип повреждения.',
      ));

  String get zoneFrontBumper =>
      _l(const L('Передній бампер', 'Front bumper', 'Передний бампер'));
  String get zoneHood => _l(const L('Капот', 'Hood', 'Капот'));
  String get zoneLeftFender =>
      _l(const L('Ліве крило', 'Left fender', 'Левое крыло'));
  String get zoneRightFender =>
      _l(const L('Праве крило', 'Right fender', 'Правое крыло'));
  String get zoneLeftDoor =>
      _l(const L('Ліві двері', 'Left door', 'Левая дверь'));
  String get zoneRightDoor =>
      _l(const L('Праві двері', 'Right door', 'Правая дверь'));
  String get zoneRoof => _l(const L('Дах', 'Roof', 'Крыша'));
  String get zoneGlass => _l(const L('Скло', 'Glass', 'Стекла'));
  String get zoneRearBumper =>
      _l(const L('Задній бампер', 'Rear bumper', 'Задний бампер'));

  String get emptyTank => _l(const L('Порожній бак', 'Empty tank', 'Пустой бак'));
  String get fullTank => _l(const L('Повний бак', 'Full tank', 'Полный бак'));
  String fuelEighths(int value) {
    if (value <= 0) return emptyTank;
    if (value >= 8) return fullTank;
    return _l(const L('{0}/8 бака', '{0}/8 tank', '{0}/8 бака'))
        .replaceFirst('{0}', '$value');
  }

  String get boxes => _l(const L('Бокси', 'Bays', 'Боксы'));
  String get masters => _l(const L('Майстри', 'Technicians', 'Мастера'));
  String get unassigned =>
      _l(const L('Нові заявки', 'New jobs', 'Новые заявки'));
  String get assign => _l(const L('Призначити', 'Assign', 'Назначить'));
  String get status => _l(const L('Статус', 'Status', 'Статус'));
  String get statusNew => _l(const L('Нова заявка', 'New', 'Новая заявка'));
  String get statusWork => _l(const L('У роботі', 'In progress', 'В работе'));
  String get statusApproval =>
      _l(const L('Погодження з клієнтом', 'Customer approval', 'Согласование с клиентом'));
  String get statusReady =>
      _l(const L('Готово до видачі', 'Ready for pickup', 'Готово к выдаче'));
  String get specElectrician =>
      _l(const L('Автоелектрик', 'Auto electrician', 'Автоэлектрик'));
  String get specMotorist => _l(const L('Моторист', 'Engine tech', 'Моторист'));
  String get specChassis => _l(const L('Ходовик', 'Chassis tech', 'Ходовик'));
  String get specMaintenance =>
      _l(const L('Майстер ТО', 'Maintenance tech', 'Мастер ТО'));
  String get loadHours =>
      _l(const L('Завантаження, год', 'Load, h', 'Загрузка, ч'));
  String get emptyBay => _l(const L('Вільний бокс', 'Empty bay', 'Свободный бокс'));

  String get rateTitle => _l(const L(
        'Оцініть візит',
        'Rate your visit',
        'Оцените визит',
      ));
  String get rateHint => _l(const L(
        'Як у Google Maps: зірки та короткий відгук.',
        'Like Google Maps: stars and a short review.',
        'Как в Google Maps: звезды и короткий отзыв',
      ));
  String get comment => _l(const L('Відгук', 'Review', 'Отзыв'));
  String get sendRating =>
      _l(const L('Надіслати оцінку', 'Submit rating', 'Отправить оценку'));
  String get thankYou => _l(const L(
        'Дякуємо! Ваша думка допомагає тримати якість.',
        'Thank you! Your feedback keeps quality high.',
        'Спасибо! Ваше мнение помогает держать качество.',
      ));
  String get completedJobs =>
      _l(const L('Готові до оцінки', 'Ready to rate', 'Готовые к оценке'));
  String get noCompleted => _l(const L(
        'Немає завершених візитів для оцінки',
        'No completed visits to rate',
        'Нет завершенных визитов для оценки',
      ));
  String get avgRating =>
      _l(const L('Середній рейтинг', 'Average rating', 'Средний рейтинг'));
  String get noRatings =>
      _l(const L('Відгуків ще немає', 'No reviews yet', 'Отзывов пока нет'));
  String get qualityControl => _l(const L(
        'Контроль якості майстрів',
        'Technician quality control',
        'Контроль качества мастеров',
      ));
  String get photoError => _l(const L(
        'Не вдалося додати фото. Спробуйте обрати файл.',
        'Could not add the photo. Try picking a file.',
        'Не удалось добавить фото. Попробуйте выбрать файл.',
      ));
  String get vpsReady => _l(const L(
        'Локальна SQLite + API-клієнт Dio готові до VPS',
        'Local SQLite + Dio API client are VPS-ready',
        'Локальная SQLite + API-клиент Dio готовы к VPS',
      ));

  String get tabFeed => _l(const L('Стрічка', 'Feed', 'Лента', 'Aktualności'));
  String get tabShops => _l(const L('СТО', 'Shops', 'СТО', 'Warsztaty'));
  String get tabCar => _l(const L('Авто', 'Car', 'Авто', 'Auto'));
  String get tabCategories => _l(const L('Категорії', 'Categories', 'Категории'));
  String get tabHelp => _l(const L('Допомога', 'Help', 'Помощь', 'Pomoc'));
  String get tabServices => _l(const L('Сервіси', 'Services', 'Сервисы', 'Usługi'));
  String get categoriesLead => _l(const L(
        'Оберіть категорію або зробіть фото — підкажемо, куди йти.',
        'Pick a category or take a photo — we’ll point you to the right section.',
        'Выберите категорию или сделайте фото — подскажем, куда идти.',
        'Wybierz kategorię albo zrób zdjęcie — wskażemy właściwy dział.',
      ));
  String get searchCategories => _l(const L(
        'Діагностика, ТО, кузов… або фото',
        'Diagnostics, service, body… or a photo',
        'Диагностика, ТО, кузов… или фото',
        'Diagnostyka, przegląd, karoseria… albo zdjęcie',
      ));
  String get categoriesPhotoHint => _l(const L(
        'Не знаєте, як називається? Зробіть фото — підкажемо розділ.',
        'Not sure what it’s called? Take a photo — we’ll suggest the section.',
        'Не знаете, как называется? Сделайте фото — подскажем раздел.',
        'Nie wiesz, jak to się nazywa? Zrób zdjęcie — podpowiemy dział.',
      ));
  String get categoriesLooking => _l(const L(
        'Дивимось фото…',
        'Looking at the photo…',
        'Смотрим фото…',
        'Oglądamy zdjęcie…',
      ));
  String get categoriesSuggested => _l(const L(
        'Для вас',
        'For you',
        'Для вас',
        'Dla ciebie',
      ));
  String get categoriesClearPhoto => _l(const L(
        'Прибрати фото',
        'Remove photo',
        'Убрать фото',
        'Usuń zdjęcie',
      ));
  String get categoryFindShops => _l(const L(
        'Знайти СТО під категорію',
        'Find shops for this category',
        'Найти СТО под категорию',
      ));
  String get tabBookings => _l(const L('Записи', 'Bookings', 'Записи', 'Rezerwacje'));
  String get tabRequests => _l(const L('Заявки', 'Requests', 'Заявки', 'Zgłoszenia'));
  String get tabServiceBook => _l(const L('Журнал', 'Logbook', 'Журнал'));
  String get serviceBookTitle =>
      _l(const L('Сервісна книжка', 'Service book', 'Сервисная книжка'));
  String get serviceBookCoverLead => _l(const L(
        'Електронний бортжурнал вашого авто',
        'Digital service log for your car',
        'Электронный бортжурнал вашего авто',
      ));
  String get serviceBookStamp =>
      _l(const L('Офіційно', 'Official', 'Официально'));
  String serviceBookEntries(int count) => _l(L(
        '$count записів',
        '$count entries',
        '$count записей',
      ));
  String get serviceBookApps =>
      _l(const L('Додатки', 'Apps', 'Приложения'));
  String get serviceBookHistory =>
      _l(const L('Історія робіт', 'Work history', 'История работ'));
  String get serviceBookEmpty => _l(const L(
        'Тут зʼявиться історія ТО, ремонтів і замін — як у дилерській сервісній книжці. Запишіться на СТО, і перший запис додасться автоматично.',
        'Maintenance, repairs and part swaps will show here — like a dealer service book. Book a visit and the first entry appears automatically.',
        'Здесь появится история ТО, ремонтов и замен — как в дилерской сервисной книжке. Запишитесь на СТО, и первая запись добавится автоматически.',
      ));
  String get serviceBookTuning =>
      _l(const L('Тюнінг', 'Tuning', 'Тюнинг'));
  String get serviceBookParts =>
      _l(const L('Запчастини', 'Parts', 'Запчасти'));
  String get serviceBookDocs =>
      _l(const L('Документи', 'Documents', 'Документы'));
  String get serviceBookStats =>
      _l(const L('Аналітика', 'Analytics', 'Аналитика'));
  String get serviceBookSoon => _l(const L('Скоро', 'Soon', 'Скоро'));
  String get serviceBookDone => _l(const L('Виконано', 'Done', 'Выполнено'));
  String serviceBookMoreWorks(int count) => _l(L(
        '+ ще $count робіт',
        '+ $count more jobs',
        '+ ещё $count работ',
      ));
  String get shopsTitle =>
      _l(const L('Сервіси поруч', 'Shops nearby', 'Сервисы рядом'));
  String get shopsLead => _l(const L(
        'Оберіть місто — усі СТО мережі Ta4ka з камерою боксу і записом. Зірка — MAPA: візьмуть трубку і виїдуть навіть вночі.',
        'Pick a city — every Ta4ka shop has a bay camera and booking. A star is MAPA: they pick up and go out even at night.',
        'Выберите город — у всех СТО сети Ta4ka камера бокса и запись. Звезда — MAPA: возьмут трубку и выедут даже ночью.',
        'Wybierz miasto — każde warsztat Ta4ka ma kamerę i rezerwację. Gwiazdka to MAPA: odbiorą i wyjadą nawet w nocy.',
      ));
  String get shopsForCategory => _l(const L(
        'СТО під категорію:',
        'Shops for:',
        'СТО под категорию:',
      ));
  String get specialistShops => _l(const L(
        'Спеціалісти з цієї роботи',
        'Specialists for this job',
        'Специалисты по этой работе',
      ));
  String get noShopsInCategory => _l(const L(
        'У цьому місті ще немає двору саме під цю категорію. Змініть місто або «Біля мене».',
        'No yard in this city for that category yet. Change city or tap Near me.',
        'В этом городе ещё нет двора именно под эту категорию. Смените город или «Возле меня».',
      ));
  String get searchShops => _l(const L(
        'Назва, послуга, тег',
        'Name, service, tag',
        'Название, услуга, тег',
      ));
  String get cityFieldHint => _l(const L(
        'Місто',
        'City',
        'Город',
      ));
  String get findNearMe => _l(const L(
        'Біля мене',
        'Near me',
        'Возле меня',
      ));
  String get locating => _l(const L(
        'Шукаємо найближчі СТО…',
        'Finding the nearest shops…',
        'Ищем ближайшие СТО…',
      ));
  String get locateError => _l(const L(
        'Не вдалося визначити місце.',
        'Could not get location.',
        'Не удалось определить место.',
        'Nie udało się pobrać lokalizacji.',
      ));
  String get locateDenied => _l(const L(
        'Дозвольте доступ до геолокації, щоб знайти СТО поруч.',
        'Allow location access to find shops near you.',
        'Разрешите доступ к геолокации, чтобы найти СТО рядом.',
        'Zezwól na lokalizację, aby znaleźć warsztat w pobliżu.',
      ));
  String get locateOff => _l(const L(
        'Увімкніть Служби геолокації в системі.',
        'Turn on Location Services on this device.',
        'Включите Службы геолокации в системе.',
        'Włącz usługi lokalizacji w systemie.',
      ));
  String get locateOpenSettings => _l(const L(
        'Налаштування',
        'Settings',
        'Настройки',
        'Ustawienia',
      ));
  String get locateYouAreHere => _l(const L(
        'Ви тут',
        'You are here',
        'Вы здесь',
        'Jesteś tutaj',
      ));
  String get nearestShops => _l(const L(
        'Найближчі сервіси',
        'Nearest shops',
        'Ближайшие сервисы',
      ));
  String get cityKyiv => _l(const L('Київ', 'Kyiv', 'Киев'));
  String get cityWarsaw => _l(const L('Варшава', 'Warsaw', 'Варшава'));
  String get cityLviv => _l(const L('Львів', 'Lviv', 'Львов'));
  String get sortRating => _l(const L('Рейтинг', 'Rating', 'Рейтинг'));
  String get sortNear => _l(const L('Ближче', 'Nearest', 'Ближе'));
  String get sortSlots =>
      _l(const L('Є вікна', 'Open slots', 'Есть окна'));
  String get badgeSlotsToday => _l(const L(
        'Є вільні місця на сьогодні',
        'Open slots today',
        'Есть свободные места сегодня',
      ));
  String todayFreeAt(String times) => _l(L(
        'Сьогодні $times',
        'Today $times',
        'Сегодня $times',
      ));
  String get todayBusy => _l(const L(
        'Зайнято на сьогодні',
        'Fully booked today',
        'Занято на сегодня',
      ));
  String get badgeLive => _l(const L(
        'Камера боксу онлайн',
        'Bay camera online',
        'Камера бокса онлайн',
        'Kamera boksu online',
      ));
  String get badgeOffline => _l(const L(
        'Камера боксу офлайн',
        'Bay camera offline',
        'Камера бокса офлайн',
        'Kamera boksu offline',
      ));
  String get bayCamSoonLead => _l(const L(
        'Сервіс не підключив камеру.',
        'This shop hasn\'t plugged in a camera yet.',
        'Сервис не подключил камеру.',
        'Serwis jeszcze nie podłączył kamery.',
      ));
  String get bayCamSoonHope => _l(const L(
        'Скоро він це зробить.',
        'They\'ll get to it soon.',
        'Скоро он это сделает.',
        'Niedługo to zrobi.',
      ));
  String get kmAway => _l(const L('км', 'km', 'км'));
  String get reviewsCount =>
      _l(const L('відгуків', 'reviews', 'отзывов'));
  String get shopReviews =>
      _l(const L('Відгуки', 'Reviews', 'Отзывы', 'Opinie'));
  String get noShops => _l(const L(
        'Нічого не знайшли. Зніміть фільтр або змініть місто.',
        'Nothing found. Clear filters or change city.',
        'Ничего не нашли. Снимите фильтр или смените город.',
      ));
  String get services => _l(const L('Послуги', 'Services', 'Услуги'));
  String get shopWorks => _l(const L('Роботи', 'Work', 'Работы'));
  String get pickServices => _l(const L(
        'Оберіть одну чи кілька послуг',
        'Pick one or more services',
        'Выберите одну или несколько услуг',
      ));
  String get continueBooking =>
      _l(const L('Далі до вікна', 'Continue to a slot', 'Дальше к окну'));
  String get pickDateTime =>
      _l(const L('Дата, час, майстер', 'Date, time, tech', 'Дата, время, мастер'));
  String get today => _l(const L('Сьогодні', 'Today', 'Сегодня'));
  String get tomorrow => _l(const L('Завтра', 'Tomorrow', 'Завтра'));
  String get anyMaster =>
      _l(const L('Будь-який вільний', 'Any free tech', 'Любой свободный'));
  String get slotBusy => _l(const L('Зайнято', 'Booked', 'Занято'));
  String get pickSlot => _l(const L(
        'Оберіть вільне вікно',
        'Pick an open slot',
        'Выберите свободное окно',
      ));
  String get pickDate => _l(const L('Оберіть дату', 'Pick a date', 'Выберите дату'));
  String get freeWindows => _l(const L('Вільні вікна', 'Open slots', 'Свободные окна'));
  String get dayOff => _l(const L('Вихідний', 'Closed', 'Выходной'));
  String get noFreeWindows => _l(const L(
        'Немає вільних вікон',
        'No open slots',
        'Нет свободных окон',
      ));
  String get toSummary =>
      _l(const L('До підтвердження', 'To confirmation', 'К подтверждению'));
  String get bookingSummary =>
      _l(const L('Підтвердження запису', 'Booking summary', 'Подтверждение записи'));
  String get confirmBooking =>
      _l(const L('Підтвердити запис', 'Confirm booking', 'Подтвердить запись'));
  String get awaitingVisit =>
      _l(const L('Очікує візиту', 'Awaiting visit', 'Ожидает визита'));
  String get bookingDone => _l(const L(
        'Вас чекають. Запис у кабінеті.',
        'They are expecting you. The booking is in your cabinet.',
        'Вас ждут. Запись в кабинете.',
      ));
  String get openLive => _l(const L(
        'Ефір / фотозвіт',
        'Live / photo report',
        'Эфир / фотоотчёт',
      ));
  String get bookHere =>
      _l(const L('Записатися сюди', 'Book here', 'Записаться сюда'));
  String get bookAgain => _l(const L(
        'Записатися повторно',
        'Book again',
        'Записаться повторно',
        'Zapisz się ponownie',
      ));
  String get hoursShort => _l(const L('год', 'h', 'ч'));
  String get etaAbout =>
      _l(const L('орієнтовно', 'about', 'ориентировочно'));
  String get noBookings => _l(const L(
        'Ще немає записів. Оберіть СТО у каталозі.',
        'No bookings yet. Pick a shop in the catalog.',
        'Ещё нет записей. Выберите СТО в каталоге.',
      ));
  String get cancelBooking => _l(const L(
        'Скасувати запис',
        'Cancel booking',
        'Отменить запись',
      ));
  String get cancelBookingLead => _l(const L(
        'Запис зникне зі списку, слот звільниться. Скасувати можна, поки візит ще не почався.',
        'The booking leaves your list and the slot opens up. You can cancel before the visit starts.',
        'Запись исчезнет из списка, слот освободится. Отменить можно, пока визит ещё не начался.',
      ));
  String get cancelBookingAction => _l(const L(
        'Видалити',
        'Delete',
        'Удалить',
      ));
  String get bookingCancelled => _l(const L(
        'Запис скасовано',
        'Booking cancelled',
        'Запись отменена',
      ));
  String get getThere => _l(const L(
        'Маршрут',
        'Route',
        'Маршрут',
        'Trasa',
      ));
  String get callShop => _l(const L(
        'Дзвінок',
        'Call',
        'Звонок',
        'Dzwonek',
      ));
  String get extraWorks => _l(const L(
        'Додаткові роботи',
        'Extra work',
        'Доп. работы',
      ));
  String get extraWorksHint => _l(const L(
        'Запис уже підтверджено і не змінюється. Дод. роботи — лише з прайса СТО, і сервіс має їх підтвердити.',
        'The booking is locked. Extra jobs come from this shop’s list and need the shop to approve them.',
        'Запись уже подтверждена и не меняется. Доп. работы — только из прайса СТО, сервис должен их подтвердить.',
      ));
  String get sendExtras => _l(const L(
        'Надіслати на підтвердження СТО',
        'Send to the shop for approval',
        'Отправить на подтверждение СТО',
      ));
  String get extrasPending => _l(const L(
        'Очікує СТО',
        'Awaiting shop',
        'Ждёт СТО',
      ));
  String get extrasWaiting => _l(const L(
        'Чекає підтвердження сервісу',
        'Waiting for the shop to approve',
        'Ждёт подтверждения сервиса',
      ));
  String get extrasSent => _l(const L(
        'Запит надіслано. Дод. роботи з’являться в записі після апруву СТО.',
        'Request sent. Extra jobs appear on the booking after the shop approves.',
        'Запрос отправлен. Доп. работы появятся в записи после апрува СТО.',
      ));
  String get extrasNone => _l(const L(
        'Немає інших робіт у прайсі цього СТО.',
        'This shop has no other jobs on its list.',
        'Нет других работ в прайсе этого СТО.',
      ));
  String get bookingLocked => _l(const L(
        'Запис зафіксовано',
        'Booking is locked',
        'Запись зафиксирована',
      ));
  String get confirmedWorks => _l(const L(
        'Підтверджені роботи',
        'Confirmed jobs',
        'Подтверждённые работы',
      ));
  String get approveExtra => _l(const L('Підтвердити', 'Approve', 'Подтвердить', 'Zatwierdź'));
  String get rejectExtra => _l(const L('Відхилити', 'Decline', 'Отклонить', 'Odrzuć'));
  String get extrasForShop => _l(const L(
        'Дод. роботи на апрув',
        'Extra jobs to approve',
        'Доп. работы на апрув',
      ));
  String get watchBay =>
      _l(const L('Дивитись ремзону', 'Watch the bay', 'Смотреть ремзону'));
  String get serviceReport =>
      _l(const L('Звіт сервісу', 'Service report', 'Отчёт сервиса'));
  String get bayCamera =>
      _l(const L('Камера боксу', 'Bay camera', 'Камера бокса'));
  String get bayLive => _l(const L('LIVE', 'LIVE', 'LIVE'));
  String get jobProcess => _l(const L(
        'Процес вашого авто зараз',
        'Where your car is right now',
        'Процесс вашего авто сейчас',
      ));
  String get reportGallery => _l(const L(
        'Вхідні фото і відео',
        'Incoming photos and video',
        'Входящие фото и видео',
      ));
  String get reportClip => _l(const L('Відео', 'Video', 'Видео'));
  String get reportStill => _l(const L('Фото', 'Photo', 'Фото'));
  String get chatWithShop =>
      _l(const L('Чат із СТО', 'Chat with the shop', 'Чат с СТО'));
  String get chatHint => _l(const L(
        'Написати сервісу…',
        'Message the shop…',
        'Написать сервису…',
      ));
  String get chatSend => _l(const L('Надіслати', 'Send', 'Отправить'));
  String get feedEmpty => _l(const L(
        'Немає кліпів по цьому СТО',
        'No clips for this shop',
        'Нет клипов по этому СТО'));
  String get allFeed =>
      _l(const L('Уся стрічка', 'Full feed', 'Вся лента'));
  String feedViews(String count) =>
      _l(L('$count переглядів', '$count views', '$count просмотров'));
  String get needService => _l(const L(
        'Оберіть хоча б одну послугу',
        'Pick at least one service',
        'Выберите хотя бы одну услугу',
      ));
  String get needSlot => _l(const L(
        'Оберіть дату і вільний час',
        'Pick a date and an open time',
        'Выберите дату и свободное время',
      ));
  String get preTotal =>
      _l(const L('Попередня сума', 'Estimate', 'Предварительная сумма'));
  String get mastersOnSite =>
      _l(const L('Майстри', 'Technicians', 'Мастера'));
  String get youGetCta => _l(const L(
        'Що входить',
        'What’s included',
        'Что входит',
      ));
  String get youGetTitle => _l(const L(
        'Як проходить робота',
        'How the job runs',
        'Как проходит работа',
      ));
  String get shopHoursLabel => _l(const L(
        'Години роботи',
        'Opening hours',
        'Часы работы',
        'Godziny pracy',
      ));
  String get categoryAbout =>
      _l(const L('Про категорію', 'About this category', 'О категории'));
  String get partsNotIncluded => _l(const L(
        'Ціна «від» — робота. Запчастини й матеріали — за кошторисом, якщо не вказано інакше.',
        'The “from” price is labour. Parts and materials are quoted unless listed as included.',
        'Цена «от» — работа. Запчасти и материалы — по смете, если не указано иное.',
      ));
  String farmPluses(int done, int need) => _l(L(
        '$done / $need плюсиків',
        '$done / $need pluses',
        '$done / $need плюсиков',
      ));
  String tapWalletNext(int left, String dollars) => left <= 0
      ? _l(L(
          'Зараховано $dollars',
          '$dollars credited',
          'Зачислено $dollars',
        ))
      : _l(L(
          'Ще $left до $dollars',
          '$left left for $dollars',
          'Ещё $left до $dollars',
        ));
  String get tapWalletFarm => _l(const L(
        'Поламай машинку і тисни плюсики. Закрив усі — вони з’являться знову. 100 плюсиків = +\$5, 1000 = +\$10, далі більше.',
        'Smash the car and tap the pluses. Clear them all and they come back. 100 pluses = +\$5, 1000 = +\$10, then more.',
        'Сломай машинку и жми плюсики. Закрыл все — они появятся снова. 100 плюсиков = +\$5, 1000 = +\$10, дальше больше.',
      ));
  String get smashCar => _l(const L('Поламати', 'Smash', 'Сломать'));
  String get smashAgain => _l(const L('Ще раз', 'Again', 'Ещё раз'));
  String smashRepair(int percent) => _l(L(
        'Лагодження $percent%',
        'Repair $percent%',
        'Ремонт $percent%',
      ));
  String get smashFixed => _l(const L(
        'Усі плюсики закриті — зараз з’являться знову.',
        'All pluses cleared — they come back now.',
        'Все плюсики закрыты — сейчас появятся снова.',
      ));
  String tapWalletPayout(String dollars) => _l(L(
        '$dollars на баланс. Можна оплатити послугу.',
        '$dollars on your balance. You can pay for a service.',
        '$dollars на баланс. Можно оплатить услугу.',
      ));
  String get tapWalletPay => _l(const L(
        'Списати з балансу',
        'Pay from balance',
        'Списать с баланса',
      ));
  String tapWalletCover(String dollars, String uah) => _l(L(
        'З балансу $dollars ≈ $uah',
        'From balance $dollars ≈ $uah',
        'С баланса $dollars ≈ $uah',
      ));
  String get tapWalletToPay => _l(const L(
        'До сплати',
        'Due',
        'К оплате',
      ));

  String get shopTabToday => _l(const L('Сьогодні', 'Today', 'Сегодня', 'Dziś'));
  String get shopTabChat => _l(const L('Чат', 'Chat', 'Чат', 'Czat'));
  String get shopTabCamera => _l(const L('Камера', 'Camera', 'Камера', 'Kamera'));
  String get shopTabRequests => _l(const L('Заявки', 'Requests', 'Заявки', 'Zgłoszenia'));
  String get shopTabDesk => _l(const L('СТО', 'Shop', 'СТО', 'Warsztat'));
  String get guideTitle => _l(const L('Як працює Ta4ka', 'How Ta4ka works', 'Как работает Ta4ka'));
  String get guideSkip => _l(const L('Натисніть, щоб пропустити', 'Tap to skip', 'Нажмите, чтобы пропустить'));
  String get guideBrand => _l(const L('Марка авто', 'Pick a brand', 'Марка авто'));
  String get guideIssue => _l(const L('Що треба', 'What you need', 'Что нужно'));
  String get guideShop => _l(const L('Оберіть СТО', 'Pick a shop', 'Выберите СТО'));
  String get guideServices => _l(const L('Послуги', 'Services', 'Услуги'));
  String get guideSlot => _l(const L('Запис у вікно', 'Book a slot', 'Запись в окно'));
  String get guideReplay => _l(const L('Міні-інструкція', 'Mini guide', 'Мини-инструкция'));
  String get opsHubTitle => _l(const L('Цех', 'Shop floor', 'Цех', 'Warsztat'));
  String get opsHubLeadShop => _l(const L(
        'Підбір з/ч, склад, пости, чек-лист, KPI і нагадування ТО — без окремого сайту.',
        'Parts lookup, stock, bays, checklist, KPIs and service reminders — no extra website.',
        'Подбор з/ч, склад, посты, чек-лист, KPI и напоминания ТО — без отдельного сайта.',
      ));
  String get opsHubLeadReception => _l(const L(
        'Прийом: чек-лист огляду, пости, підбір з/ч і нагадування клієнту.',
        'Intake: inspection checklist, bays, parts lookup and client reminders.',
        'Приём: чек-лист осмотра, посты, подбор з/ч и напоминания клиенту.',
      ));
  String get opsPartsTitle => _l(const L('Підбір запчастин', 'Parts lookup', 'Подбор запчастей'));
  String get opsPartsLead => _l(const L(
        'VIN + каталог. Ціни кількох постачальників і націнка по групі — на одному екрані.',
        'VIN + catalog. Several supplier prices and group markup on one screen.',
        'VIN + каталог. Цены нескольких поставщиков и наценка по группе — на одном экране.',
      ));
  String get opsVinLabel => _l(const L('VIN / номер кузова', 'VIN / body no.', 'VIN / номер кузова'));
  String get opsVinWmi => _l(const L('Код платформи', 'Platform code', 'Код платформы'));
  String get opsVinUnknown => _l(const L(
        'VIN не розпізнано. Перевірте 17 символів.',
        'VIN not recognized. Check all 17 characters.',
        'VIN не распознан. Проверьте 17 символов.',
      ));
  String get opsPartsQuery => _l(const L('OEM, назва, бренд', 'OEM, name, brand', 'OEM, название, бренд'));
  String get opsMarkup => _l(const L('Націнка', 'Markup', 'Наценка'));
  String get opsToday => _l(const L('сьогодні', 'today', 'сегодня'));
  String get opsOrderPart => _l(const L('Замовити', 'Order', 'Заказать'));
  String get opsOrdered => _l(const L('Замовлено', 'Ordered', 'Заказано'));
  String get opsStockTitle => _l(const L('Склад', 'Warehouse', 'Склад'));
  String get opsStockLead => _l(const L(
        'Залишки, комірка, резерв і прихід. FIFO по собівартості партії.',
        'Stock, bin, reserve and receiving. FIFO on batch cost.',
        'Остатки, ячейка, резерв и приход. FIFO по себестоимости партии.',
      ));
  String get opsBin => _l(const L('комірка', 'bin', 'ячейка'));
  String get opsFree => _l(const L('вільно', 'free', 'свободно'));
  String get opsReserved => _l(const L('резерв', 'reserved', 'резерв'));
  String get opsReserve => _l(const L('Резерв', 'Reserve', 'Резерв'));
  String get opsReceive => _l(const L('Прихід', 'Receive', 'Приход'));
  String get opsCheckTitle => _l(const L('Чек-лист огляду', 'Inspection checklist', 'Чек-лист осмотра'));
  String get opsCheckLead => _l(const L(
        'Огляд по зонах. Клієнт бачить, що знайшли, і легше погоджує роботи.',
        'Zone inspection. The client sees findings and approves extra work faster.',
        'Осмотр по зонам. Клиент видит находки и быстрее согласует работы.',
      ));
  String get opsCheckOk => _l(const L('норма', 'ok', 'норма'));
  String get opsCheckFail => _l(const L('увага', 'attention', 'внимание'));
  String get opsBaysTitle => _l(const L('Пости / підйомники', 'Bays / lifts', 'Посты / подъёмники'));
  String get opsBaysLead => _l(const L(
        'Хто на якому посту зараз. Без простою між авто.',
        'Who is on which bay now. No idle gaps between cars.',
        'Кто на каком посту сейчас. Без простоя между авто.',
      ));
  String get opsBayFree => _l(const L('Вільно', 'Free', 'Свободно'));
  String get opsKpiTitle => _l(const L('KPI і зарплата', 'KPIs & payroll', 'KPI и зарплата'));
  String get opsKpiLead => _l(const L(
        'Закриті ремонти, н/г, частка з/ч і орієнтир ЗП майстра (32% від робіт).',
        'Closed jobs, labor hours, parts share and a pay estimate (32% of labor).',
        'Закрытые ремонты, н/ч, доля з/ч и ориентир ЗП мастера (32% от работ).',
      ));
  String get opsClosed => _l(const L('Закрито ремонтів', 'Jobs closed', 'Закрыто ремонтов'));
  String get opsLabor => _l(const L('Роботи (н/г)', 'Labor', 'Работы (н/ч)'));
  String get opsPartsShare => _l(const L('Запчастини в чеку', 'Parts in ticket', 'Запчасти в чеке'));
  String get opsPayroll => _l(const L('Орієнтир ЗП', 'Pay estimate', 'Ориентир ЗП'));
  String get opsTimeOnJobs => _l(const L('Час на постах', 'Time on bays', 'Время на постах'));
  String get opsRemindTitle => _l(const L('Нагадування ТО', 'Service reminders', 'Напоминания ТО'));
  String get opsRemindLead => _l(const L(
        'Кого кликати на наступне ТО. Повідомлення йде в чат заявки.',
        'Who to call for the next service. The ping goes to the job chat.',
        'Кого звать на следующее ТО. Сообщение уходит в чат заявки.',
      ));
  String get opsRemindAdd => _l(const L('Додати з останньої заявки', 'Add from last job', 'Добавить из последней заявки'));
  String get opsRemindSend => _l(const L('Написати', 'Message', 'Написать'));
  String get opsRemindSent => _l(const L('надіслано', 'sent', 'отправлено'));
  String get opsRemindPing => _l(const L(
        'Нагадуємо про планове ТО. Можна записатись у додатку.',
        'Reminder: scheduled service is due. You can book in the app.',
        'Напоминаем про плановое ТО. Можно записаться в приложении.',
      ));
  String get opsClock => _l(const L('Нормо-години', 'Labor clock', 'Нормо-часы'));
  String get opsClockStart => _l(const L('Старт', 'Start', 'Старт'));
  String get opsClockStop => _l(const L('Стоп', 'Stop', 'Стоп'));
  String get opsRequestsLead => _l(const L(
        'Заявки майстрів на запчастини.',
        'Technician parts requests.',
        'Заявки мастеров на запчасти.',
      ));
  String get opsNotifyClient => _l(const L('Написати клієнту', 'Message the client', 'Написать клиенту'));
  String get shopRolePickTitle => _l(const L(
        'Хто ви?',
        'Who are you?',
        'Кто вы?',
      ));
  String get shopRoleManager => _l(const L(
        'Менеджер автосервісу',
        'Shop manager',
        'Менеджер автосервиса',
      ));
  String get shopRoleMaster => _l(const L(
        'Майстер на посту',
        'Bay master',
        'Мастер на посту',
      ));
  String get shopRoleMasterHint => _l(const L(
        'Облікку майстра видає лише кабінет СТО (логін і пароль).',
        'Master login is issued only from the shop desk.',
        'Учётку мастера выдаёт только кабинет СТО (логин и пароль).',
      ));
  String get masterIssueLogin => _l(const L(
        'Видати логін / пароль',
        'Issue login / password',
        'Выдать логин / пароль',
      ));
  String get shopTabMasters => _l(const L('Майстри', 'Masters', 'Мастера', 'Mechanicy'));
  String get shopMastersRegisterTitle => _l(const L(
        'Зареєструвати майстра',
        'Register master',
        'Зарегистрировать мастера',
      ));
  String get shopMastersRegisterCta => _l(const L(
        'Створити акаунт майстра',
        'Create master account',
        'Создать аккаунт мастера',
      ));
  String get shopMastersRegisterLead => _l(const L(
        'Сервіс створює логін і пароль. Майстер входить через «Для автосервісів» → Майстер.',
        'The shop creates login and password. Master signs in via “For shops” → Master.',
        'Сервис создаёт логин и пароль. Мастер входит через «Для автосервисов» → Мастер.',
      ));
  String get shopMastersListTitle => _l(const L(
        'Акаунти майстрів',
        'Master accounts',
        'Аккаунты мастеров',
      ));
  String get staffKindMechanic => _l(const L(
        'Механік (бокс)',
        'Bay mechanic',
        'Механик (бокс)',
      ));
  String get staffKindReception => _l(const L(
        'Майстер-приймач',
        'Receptionist',
        'Мастер-приёмщик',
      ));
  String get shopRoleOwner => _l(const L(
        'Власник / директор',
        'Owner / director',
        'Владелец / директор',
      ));
  String get shopRoleReception => _l(const L(
        'Майстер-приймач',
        'Service advisor',
        'Мастер-приёмщик',
      ));
  String get mapaBadge => _l(const L(
        'MAPA · допомога',
        'MAPA · help',
        'MAPA · помощь',
        'MAPA · pomoc',
      ));
  String get mapaClientTitle => _l(const L(
        'Допомога на дорозі',
        'Roadside help',
        'Помощь на дороге',
      ));
  String get mapaClientLead => _l(const L(
        'Якщо ви не можете дістатися до СТО самі — знайдіть сервіс з виїздом (навіть вночі).',
        'If you cannot reach a shop alone — find a service that will come out (even at night).',
        'Если вы не можете доехать до СТО сами — найдите сервис с выездом (даже ночью).',
      ));
  String get mapaClientWhen => _l(const L(
        'Оберіть, що сталося',
        'What happened',
        'Выберите, что случилось',
      ));
  String get mapaCondStuck => _l(const L(
        'Не можу продовжити рух',
        'I cannot keep driving',
        'Не могу продолжать движение',
      ));
  String get mapaCondUrgent => _l(const L(
        'Термінова поломка / небезпека',
        'Urgent failure / unsafe',
        'Срочная поломка / опасно',
      ));
  String get mapaCondTow => _l(const L(
        'Потрібен евакуатор / виїзд',
        'Need tow / on-site help',
        'Нужен эвакуатор / выезд',
      ));
  String get mapaCondNight => _l(const L(
        'Ніч / поза годинами СТО',
        'Night / outside shop hours',
        'Ночь / вне часов СТО',
      ));
  String get mapaFindHelp => _l(const L(
        'Відкрити мапу допомоги',
        'Open help map',
        'Открыть карту помощи',
      ));
  String get mapaNeedCondition => _l(const L(
        'Оберіть хоча б одну умову — кнопка лише для реальних SOS-випадків.',
        'Pick at least one condition — this is only for real SOS cases.',
        'Выберите хотя бы одно условие — кнопка только для реальных SOS.',
      ));
  String get mapaHelpListTitle => _l(const L(
        'Сервіси проєкту Help · оцінка в додатку',
        'Help project shops · in-app rating',
        'Сервисы проекта Help · оценка в приложении',
      ));
  String get mapaHelpGradeTop => _l(const L(
        'Топ спеціалісти',
        'Top specialists',
        'Топ специалисты',
      ));
  String get mapaHelpGradePro => _l(const L(
        'Перевірені',
        'Verified',
        'Проверенные',
      ));
  String get mapaHelpGradeBase => _l(const L(
        'Учасник Help',
        'Help member',
        'Участник Help',
      ));
  String get mapaShopUseMap => _l(const L(
        'Клієнти бачать вас на мапі допомоги',
        'Clients see you on the help map',
        'Клиенты видят вас на карте помощи',
      ));
  String get mapaHelpEmpty => _l(const L(
        'Поруч поки немає активних MAPA-сервісів.',
        'No active MAPA shops nearby yet.',
        'Рядом пока нет активных MAPA-сервисов.',
      ));
  String get mapaReportTitle => _l(const L(
        'Сервіс не відповів',
        'Shop did not answer',
        'Сервис не ответил',
      ));
  String get mapaReportLead => _l(const L(
        'Після 2 дзвінків без відповіді додайте фото доказ і сервіс знімається з MAPA.',
        'After 2 unanswered calls, add a photo — the shop is removed from MAPA help.',
        'После 2 звонков без ответа добавьте фото — сервис снимается с MAPA.',
      ));
  String get mapaReportNote => _l(const L('Коротко що сталося', 'Short note', 'Кратко что случилось'));
  String get mapaReportCta => _l(const L('Не взяли трубку', 'No answer', 'Не взяли трубку'));
  String get mapaReportDone => _l(const L(
        'Скаргу прийнято. Сервіс прибрано з MAPA-допомоги.',
        'Report filed. Shop removed from MAPA help.',
        'Жалоба принята. Сервис убран из MAPA-помощи.',
      ));
  String get mapaShopTitle => _l(const L(
        'MAPA · виїзд на допомогу',
        'MAPA · go-out help',
        'MAPA · выезд на помощь',
      ));
  String get mapaShopLead => _l(const L(
        'Якщо є людина, яка може виїхати в будь-який час (навіть вночі), телефон завжди на звʼязку і майстер компетентний — увімкніть. У списку СТО зʼявиться значок MAPA.',
        'If someone can go out anytime (even at night), the phone stays on, and the tech is competent — turn this on. Your shop gets a MAPA badge in the list.',
        'Если есть человек, который может выехать в любое время (даже ночью), телефон на связи и мастер компетентен — включите. В списке СТО появится значок MAPA.',
      ));
  String get mapaShopAgree => _l(const L(
        'Погоджуюсь: ми в MAPA-допомозі',
        'I agree: we join MAPA help',
        'Согласен: мы в MAPA-помощи',
      ));
  String get ownerDashTitle => _l(const L(
        'Власник · фінанси',
        'Owner · finance',
        'Владелец · финансы',
      ));
  String get copy => _l(const L('Копіювати', 'Copy', 'Копировать', 'Kopiuj'));
  String get copied => _l(const L('Скопійовано', 'Copied', 'Скопировано', 'Skopiowano'));
  String get cancel => _l(const L('Скасувати', 'Cancel', 'Отмена', 'Anuluj'));
  String get masterTabJobs => _l(const L('Замовлення', 'Jobs', 'Заказы'));
  String get masterTabParts => _l(const L('Запчастини', 'Parts', 'Запчасти'));
  String get masterTabMe => _l(const L('Кабінет', 'Cabinet', 'Кабинет'));
  String get masterPartsTitle => _l(const L(
        'Потрібна деталь',
        'Need this part',
        'Нужна эта деталь',
      ));
  String get masterPartsLead => _l(const L(
        'Вкажіть номер кузова — VIN підтягнеться. Напишіть словами (напр. шрус) і оберіть зі списку.',
        'Enter body/VIN — then type the part in words (e.g. CV joint) and pick from the list.',
        'Укажите номер кузова — VIN подтянется. Напишите словами (напр. шрус) и выберите из списка.',
      ));
  String get masterPartsSend => _l(const L(
        'Запросити у партнера / складу',
        'Request from partner / warehouse',
        'Запросить у партнера / склада',
      ));
  String get masterPartsPending => _l(const L(
        'На погодженні СТО',
        'Awaiting shop approval',
        'На согласовании СТО',
      ));
  String get shopPartsApprove => _l(const L(
        'Запити запчастин',
        'Parts requests',
        'Запросы запчастей',
      ));
  String get shopPartsOrder => _l(const L(
        'Замовити у постачальника',
        'Order from supplier',
        'Заказать у поставщика',
      ));
  String get shopPartsReady => _l(const L(
        'Деталь на складі / видати',
        'Part ready / hand out',
        'Деталь на складе / выдать',
      ));
  String get masterPartsReceive => _l(const L(
        'Отримати запчастину',
        'Receive part',
        'Получить запчасть',
      ));
  String get liveEstimateTitle => _l(const L(
        'Чернетка кошторису',
        'Live draft estimate',
        'Черновик сметы',
      ));
  String get naryadTitle => _l(const L(
        'Заказ-наряд',
        'Work order',
        'Заказ-наряд',
      ));
  String get naryadLive => _l(const L('LIVE', 'LIVE', 'LIVE'));
  String get naryadClientLead => _l(const L(
        'Майстер додає роботи й запчастини тут же — сума оновлюється в реальному часі.',
        'The tech adds works and parts here — the total updates live.',
        'Мастер добавляет работы и запчасти прямо здесь — сумма обновляется в реальном времени.',
      ));
  String get naryadShopLead => _l(const L(
        'Єдиний заказ-наряд: роботи, запчастини й сума видно СТО і клієнту одночасно.',
        'One work order: works, parts and total visible to the shop and the client at once.',
        'Единый заказ-наряд: работы, запчасти и сумма видны СТО и клиенту одновременно.',
      ));
  String get naryadConfirmed => _l(const L(
        'Підтверджено',
        'Confirmed',
        'Подтверждено',
      ));
  String get naryadInProgress => _l(const L(
        'У роботі / додається',
        'In progress / adding',
        'В работе / добавляется',
      ));
  String get naryadEmptyDraft => _l(const L(
        'Поки порожньо — додайте роботу або запчастину.',
        'Empty for now — add a job or part.',
        'Пока пусто — добавьте работу или запчасть.',
      ));
  String get naryadAddQuick => _l(const L(
        'Швидко додати',
        'Quick add',
        'Быстро добавить',
      ));
  String get naryadPartsHints => _l(const L(
        'Часті запчастини',
        'Common parts',
        'Частые запчасти',
      ));
  String get naryadPrice => _l(const L('Ціна', 'Price', 'Цена'));
  String get naryadTotal => _l(const L(
        'Сума заказ-наряду',
        'Work order total',
        'Сумма заказ-наряда',
      ));
  String get naryadDraftPart => _l(const L(
        'з них ще не зафіксовано',
        'of which not yet locked',
        'из них ещё не зафиксировано',
      ));
  String get naryadClientConfirm => _l(const L(
        'Прийняти пропозицію',
        'Accept offer',
        'Принять предложение',
      ));
  String get naryadClientDecline => _l(const L(
        'Відмовитись',
        'Decline',
        'Отказаться',
      ));
  String get naryadSheetTitle => _l(const L(
        'Заказ-наряди в роботі',
        'Open work orders',
        'Заказ-наряды в работе',
      ));
  String get naryadSheetNone => _l(const L(
        'Немає активних заказ-нарядів з новими позиціями.',
        'No open work orders with new lines.',
        'Нет активных заказ-нарядов с новыми позициями.',
      ));
  String get naryadOpen => _l(const L(
        'Відкрити заказ-наряд',
        'Open work order',
        'Открыть заказ-наряд',
      ));
  String get liveEstimateLead => _l(const L(
        'Поки авто на підйомнику — набивайте суми. Клієнт бачить їх у реальному часі.',
        'While the car is on the lift — tap items in. The client sees them live.',
        'Пока авто на подъёмнике — набивайте суммы. Клиент видит их в реальном времени.',
      ));
  String get liveEstimateItem => _l(const L('Позиція', 'Line item', 'Позиция'));
  String get liveEstimateLabor => _l(const L('Робота', 'Labor', 'Работа'));
  String get liveEstimateParts => _l(const L('Запчастина', 'Parts', 'Запчасть'));
  String get liveEstimateTotal => _l(const L('Разом (чернетка)', 'Draft total', 'Итого (черновик)'));
  String liveEstimateFeeHint(String fee) => _l(L(
        'Комісія Ta4ka 5% з додробіт після підтвердження: ~$fee',
        'Ta4ka 5% on extras after confirm: ~$fee',
        'Комиссия Ta4ka 5% с допработ после подтверждения: ~$fee',
      ));
  String get liveEstimateConfirm => _l(const L(
        'Оплатити / Підтвердити',
        'Pay / Confirm',
        'Оплатить / Подтвердить',
      ));
  String get liveEstimateClientLead => _l(const L(
        'Майстер набиває кошторис зараз. Можете підтвердити, не чекаючи дзвінка.',
        'The master is building the estimate now. You can confirm without waiting for a call.',
        'Мастер набивает смету сейчас. Можете подтвердить, не дожидаясь звонка.',
      ));
  String get defectPhotoTitle => _l(const L(
        'Фото прихованих дефектів',
        'Hidden defect photos',
        'Фото скрытых дефектов',
      ));
  String get defectPhotoLead => _l(const L(
        'Зніміть деталь і обведіть проблему кругом або стрілкою — клієнт одразу побачить де поломка.',
        'Shoot the part and mark the issue with a circle or arrow — the client sees it instantly.',
        'Снимите деталь и обведите проблему кругом или стрелкой — клиент сразу увидит где поломка.',
      ));
  String get defectPhotoAdd => _l(const L(
        'Фото + розмітка',
        'Photo + markup',
        'Фото + разметка',
      ));
  String get orderCancelled => _l(const L('Скасовано', 'Cancelled', 'Отменено', 'Anulowano'));
  String get taxReportTitle => _l(const L(
        'Звіт для податкової',
        'Tax report',
        'Отчёт для налоговой',
        'Raport podatkowy',
      ));
  String get taxReportLead => _l(const L(
        'Підсумок виконаних робіт за період для звітності.',
        'Summary of completed jobs for the period.',
        'Итог выполненных работ за период для отчётности.',
      ));
  String get vinHistoryTitle => _l(const L(
        'Історія по VIN',
        'VIN history',
        'История по VIN',
        'Historia VIN',
      ));
  String get vinHistoryLead => _l(const L(
        'Усі роботи з цим авто в застосунку — на будь-якому СТО.',
        'All work on this car in the app — at any shop.',
        'Все работы с этим авто в приложении — на любом СТО.',
      ));
  String get blacklistTitle => _l(const L(
        'Чорний список',
        'Blacklist',
        'Чёрный список',
        'Czarna lista',
      ));
  String get blacklistLead => _l(const L(
        'Спільний список для всіх СТО. Причина видно всім.',
        'Shared list for all shops. Reasons are visible to everyone.',
        'Общий список для всех СТО. Причина видна всем.',
      ));
  String get blacklistHit => _l(const L(
        'Клієнт у чорному списку',
        'Client is blacklisted',
        'Клиент в чёрном списке',
      ));
  String get blacklistCancelOk => _l(const L(
        'Скасувати без пояснення',
        'Cancel without reason',
        'Отменить без объяснения',
      ));
  String get openRequestsTitle => _l(const L(
        'Активні заявки',
        'Open requests',
        'Активные заявки',
      ));
  String get openRequestsLead => _l(const L(
        'Надішліть заявку всім СТО у місті з фото/відео — отримаєте найнижчу ціну.',
        'Send a request to every shop in the city with photo/video — get the lowest price.',
        'Отправьте заявку всем СТО в городе с фото/видео — получите самую низкую цену.',
      ));
  String get openRequestsInfoTitle => _l(const L(
        'Заявка всім СТО у вашому місті — найнижча ціна',
        'Request to every shop in your city — lowest price',
        'Заявка всем СТО в вашем городе — самая низкая цена',
      ));
  String get servicesRequestsLead => _l(const L(
        'Заявка всім СТО у вашому місті, щоб отримати найнижчу ціну',
        'Ask every shop in your city to get the lowest price',
        'Заявка всем СТО в вашем городе, чтобы получить самую низкую цену',
      ));
  String get servicesHelpLead => _l(const L(
        'Допомога на дорозі — сервіси проєкту Help, навіть вночі',
        'Roadside help — Help project shops, even at night',
        'Помощь на дороге — сервисы проекта Help, даже ночью',
      ));
  String get openRequestsInfoBody => _l(const L(
        'Тут ви виставляєте нестандартну або термінову роботу: опишіть проблему, додайте фото — і заявку побачать усі сервіси в обраному місті/країні. Перший, з ким ви домовитесь, закріплює угоду; у інших СТО заявка зникає. Стандартні роботи краще шукати в «Категоріях» — цей розділ для специфіки, економії часу й пошуку найближчого готового майстра.',
        'Post a non-standard or urgent job here: describe the issue, add a photo — every shop in your city/country sees it. The first shop you agree with locks the deal; others lose the request. Use Categories for routine work — this tab is for special cases, saving time, and finding the nearest ready shop.',
        'Здесь вы выставляете нестандартную или срочную работу: опишите проблему, добавьте фото — заявку увидят все сервисы в выбранном городе/стране. С кем договоритесь первым — тот закрепляет сделку; у остальных заявка исчезает. Обычные работы лучше искать в «Категориях» — этот раздел для специфики, экономии времени и поиска ближайшего готового мастера.',
      ));
  String get openRequestsCreate => _l(const L(
        'Створити заявку',
        'Create request',
        'Создать заявку',
      ));
  String get openRequestsActiveTitle => _l(const L(
        'Ваші активні заявки',
        'Your active requests',
        'Ваши активные заявки',
      ));
  String get openRequestsEmpty => _l(const L(
        'Поки немає активних заявок.',
        'No active requests yet.',
        'Пока нет активных заявок.',
      ));
  String get openRequestsDoneTitle => _l(const L(
        'Виконані',
        'Completed',
        'Выполненные',
      ));
  String get openRequestsDoneLead => _l(const L(
        'Після виконання заявка йде в сервісний журнал (записи / книжка).',
        'When finished, the request moves to your service logbook.',
        'После выполнения заявка уходит в сервисный журнал.',
      ));
  String get openJobFieldTitle => _l(const L(
        'Що потрібно зробити',
        'What needs doing',
        'Что нужно сделать',
      ));
  String get openJobFieldDetails => _l(const L(
        'Опишіть проблему',
        'Describe the problem',
        'Опишите проблему',
      ));
  String get openJobFieldCity => _l(const L(
        'Місто / країна',
        'City / country',
        'Город / страна',
      ));
  String get openJobFieldMedia => _l(const L(
        'Фото / відео (посилання або опис)',
        'Photo / video (link or note)',
        'Фото / видео (ссылка или описание)',
      ));
  String get openJobStatusOpen => _l(const L('У пулі · чекає пропозицій', 'In pool · waiting offers', 'В пуле · ждёт предложений'));
  String get openJobStatusAwarded => _l(const L('Угода · в роботі', 'Deal · in progress', 'Сделка · в работе'));
  String get openJobStatusClosed => _l(const L('Виконано', 'Done', 'Выполнено'));
  String get openJobAcceptDeal => _l(const L('Погодитись', 'Accept deal', 'Согласиться'));
  String get openJobWaiting => _l(const L(
        'Чекаємо пропозиції від СТО…',
        'Waiting for shop offers…',
        'Ждём предложения от СТО…',
      ));
  String get openJobInProgress => _l(const L(
        'Домовлено — заявка зникла з пулу інших СТО. Триває до виконання.',
        'Agreed — removed from other shops’ pool. Stays until the job is done.',
        'Договорились — заявка исчезла из пула других СТО. Висит до выполнения.',
      ));
  String get openJobPropose => _l(const L(
        'Запропонувати ціну і дату',
        'Propose price & date',
        'Предложить цену и дату',
      ));
  String get openJobBidPrice => _l(const L('Ціна, грн', 'Price, UAH', 'Цена, грн'));
  String get openJobBidNote => _l(const L('Коментар', 'Note', 'Комментарий'));
  String get openJobBidsCount => _l(const L('пропозицій', 'bids', 'предложений'));
  String get shopOpenJobsLead => _l(const L(
        'Заявки з пулу клієнтів у вашому місті. Хто перший домовиться з клієнтом — той забирає роботу; після угоди заявка зникає у інших.',
        'Client pool requests in your city. First shop the client accepts wins; after the deal others lose the request.',
        'Заявки из пула клиентов в вашем городе. Кто первым договорится с клиентом — тот забирает работу; после сделки заявка исчезает у остальных.',
      ));
  String get tabAuction => _l(const L('Аукціон', 'Auction', 'Аукцион', 'Aukcja'));
  String get tabUsa => _l(const L('Авто з США', 'Cars from USA', 'Авто из США', 'Auta z USA'));
  String get usaSphereTitle => _l(const L(
        'Доставка авто зі США',
        'Car delivery from the USA',
        'Доставка авто из США',
        'Dostawa aut ze USA',
      ));
  String get usaSphereSubtitle => _l(const L('Послуги', 'Services', 'Услуги', 'Usługi'));
  String get usaSpherePrice => _l(const L(
        'від 1000 \$ · доставка',
        'from \$1,000 · delivery',
        'от 1000 \$ · доставка',
        'od 1000 \$ · dostawa',
      ));
  String get usaServicesLead => _l(const L(
        'Доставка автомобілів зі США під ключ',
        'Turnkey car delivery from the USA',
        'Доставка автомобилей из США под ключ',
      ));
  String get usaExclusiveBadge => _l(const L('L-TRANS', 'L-TRANS', 'L-TRANS'));
  String get usaTurnkey => _l(const L(
        'Доставка авто з США та Канади',
        'Car delivery from USA and Canada',
        'Доставка авто из США и Канады',
      ));
  String get usaPipelineTitle => _l(const L('Послуги', 'Services', 'Услуги'));
  String get usaLotsTitle => _l(const L('Каталог', 'Catalog', 'Каталог'));
  String get usaLotsLead => _l(const L(
        'Актуальні лоти Copart та IAAI з розрахунком доставки в Україну',
        'Live Copart and IAAI lots with delivery to Ukraine',
        'Актуальные лоты Copart и IAAI с расчётом доставки в Украину',
      ));
  String get usaCalcTitle => _l(const L('Калькулятор', 'Calculator', 'Калькулятор'));
  String get usaCalcLead => _l(const L(
        'Ставка на аукціоні + збір аукціону + доставка по Америці + доставка по океану + мито + акциз + ПДВ + брокер = авто в Україні.',
        'Auction bid + auction fee + US inland + ocean freight + duty + excise + VAT + broker = the car in Ukraine.',
        'Ставка на аукционе + сбор аукциона + доставка по Америке + доставка по океану + пошлина + акциз + НДС + брокер = авто в Украине.',
      ));
  String get usaIncludeTitle => _l(const L('Для дилерів', 'For dealers', 'Для дилеров'));
  String get usaRequestTitle => _l(const L('Консультація', 'Consultation', 'Консультация'));
  String get usaRequestLead => _l(const L(
        'Офіційний представник IAAI в Україні. Менеджер L-Trans напише протягом години.',
        'Official IAAI representative in Ukraine. L-Trans writes within an hour.',
        'Официальный представитель IAAI в Украине. Менеджер L-Trans напишет в течение часа.',
      ));
  String get usaPhone => _l(const L('Телефон Telegram / WhatsApp', 'Telegram / WhatsApp phone', 'Телефон Telegram / WhatsApp'));
  String get usaRequestCta => _l(const L('Отримати консультацію', 'Get a consultation', 'Получить консультацию'));
  String get usaRequestQueued => _l(const L('Заявку прийнято L-Trans', 'Request queued at L-Trans', 'Заявку принял L-Trans'));
  String get usaRequestDone => _l(const L(
        'Менеджер L-Trans напише протягом години.',
        'L-Trans manager will write within an hour.',
        'Менеджер L-Trans напишет в течение часа.',
      ));
  String get usaExclusiveNote => _l(const L(
        'В Ta4ka лише L-TRANS. Інших імпортерів у додатку немає — так і задумано.',
        'Only L-TRANS in Ta4ka. No other importers in the app — by design.',
        'В Ta4ka только L-TRANS. Других импортёров в приложении нет — так и задумано.',
      ));
  String get usaOurSite => _l(const L('Наш сайт', 'Our site', 'Наш сайт'));
  String get usaSiteCta => _l(const L('l-trans.org', 'l-trans.org', 'l-trans.org'));
  String get usaStockTitle => _l(const L(
        'Каталог автомобілів у наявності',
        'Cars in stock',
        'Каталог автомобилей в наличии',
      ));
  String get usaStockLead => _l(const L(
        'Вже на майданчику або в дорозі до України',
        'Already at the yard or on the way to Ukraine',
        'Уже на площадке или в пути в Украину',
      ));
  String get usaPickedTitle => _l(const L(
        'Підібрані менеджером',
        'Picked by our manager',
        'Подобранные менеджером',
      ));
  String get usaPickedLead => _l(const L(
        'Хороші варіанти, які вже перевірив L-Trans',
        'Solid options already checked by L-Trans',
        'Хорошие варианты, которые уже проверил L-Trans',
      ));
  String get usaRouteUsa => _l(const L('США', 'USA', 'США', 'USA'));
  String get usaRouteOcean => _l(const L('Атлантика', 'Atlantic', 'Атлантика', 'Atlantyk'));
  String get usaRouteUa => _l(const L('Україна', 'Ukraine', 'Украина', 'Ukraina'));
  String get usaRouteEu => _l(const L('Європа', 'Europe', 'Европа', 'Europa'));
  String get usaRouteDaysShort => _l(const L('1,5–2,5 міс.', '1.5–2.5 mo', '1,5–2,5 мес.', '1,5–2,5 mies.'));
  String get usaRouteDays => _l(const L(
        'від 1,5 до 2,5 місяців · ключі в Україні',
        '1.5 to 2.5 months · keys in Ukraine',
        'от 1,5 до 2,5 месяцев · ключи в Украине',
        'od 1,5 do 2,5 miesiąca · klucze w Ukrainie',
      ));
  String get usaRouteLead => _l(const L(
        'Аукціон Copart / IAAI → океан → розмитнення → авто у вашому місті.',
        'Copart / IAAI auction → ocean → customs → the car in your city.',
        'Аукцион Copart / IAAI → океан → растаможка → авто в вашем городе.',
        'Aukcja Copart / IAAI → ocean → odprawa → auto w Twoim mieście.',
      ));
  String get usaIntroHeadline => _l(const L(
        'Доставка автомобілів зі США',
        'Car delivery from the USA',
        'Доставка автомобилей из США',
        'Dostawa aut ze USA',
      ));
  String get usaIntroTagline => _l(const L(
        'під ключ',
        'turnkey',
        'под ключ',
      ));
  String get usaIntroPick => _l(const L('Підбір', 'Pick', 'Подбор'));
  String get usaIntroDeliver => _l(const L('Океан', 'Ocean', 'Океан'));
  String get usaIntroDrive => _l(const L('У тебе', 'Keys', 'У тебя'));
  String get usaNavAbout => _l(const L('Про нас', 'About', 'О нас'));
  String get usaNavServices => _l(const L('Послуги', 'Services', 'Услуги'));
  String get usaNavCatalog => _l(const L('Каталог', 'Catalog', 'Каталог'));
  String get usaNavDealers => _l(const L('Для дилерів', 'For dealers', 'Для дилеров'));
  String get usaNavContacts => _l(const L('Контакти', 'Contacts', 'Контакты'));
  String get usaAboutLead => _l(const L(
        'Lion Trans — логістика з 2018. Представництва в Україні, Грузії, Казахстані, Азербайджані, Вірменії та Польщі. Купівля в закритих штатах Alabama, Michigan, Wisconsin.',
        'Lion Trans — logistics since 2018. Offices in Ukraine, Georgia, Kazakhstan, Azerbaijan, Armenia and Poland. Buying in closed states Alabama, Michigan, Wisconsin.',
        'Lion Trans — логистика с 2018. Представительства в Украине, Грузии, Казахстане, Азербайджане, Армении и Польше. Покупка в закрытых штатах Alabama, Michigan, Wisconsin.',
      ));
  String get auctionHeroTitle => _l(const L(
        'Аукціон битих і несправних авто',
        'Auction of wrecked & faulty cars',
        'Аукцион битых и неисправных авто',
      ));
  String get auctionHeroLead => _l(const L(
        'Ремонт дорожчий за сенс? Виставте авто «як є» на 2 години. Перекупники, розбори й відновлювачі ставлять ціну. Ви продаєте, СТО отримує комісію за діагностику і угоду — покупець забирає машину.',
        'Repair too expensive? List the car “as is” for 2 hours. Flippers, dismantlers and restorers bid. You sell, the shop earns a commission for diagnosis & deal — the buyer picks up the car.',
        'Ремонт дороже смысла? Выставьте авто «как есть» на 2 часа. Перекупщики, разборы и восстановители делают ставки. Вы продаёте, СТО получает комиссию за диагностику и сделку — покупатель забирает машину.',
      ));
  String get auctionCreateTitle => _l(const L(
        'Виставити авто на аукціон',
        'List car on auction',
        'Выставить авто на аукцион',
      ));
  String get auctionCreateLead => _l(const L(
        'Вікно ставок — 2 години. Можна прийняти найкращу ставку раніше.',
        'Bidding window — 2 hours. You can accept the best bid sooner.',
        'Окно ставок — 2 часа. Можно принять лучшую ставку раньше.',
      ));
  String get auctionFieldTitle => _l(const L('Заголовок лоту', 'Lot title', 'Заголовок лота'));
  String get auctionFieldDetails => _l(const L('Стан / що «померло»', 'Condition / what failed', 'Состояние / что «умерло»'));
  String get auctionFieldEstimate => _l(const L('Оцінка ремонту, грн', 'Repair estimate, UAH', 'Оценка ремонта, грн'));
  String get auctionFieldPhoto => _l(const L('Фото / посилання', 'Photo / link', 'Фото / ссылка'));
  String get auctionStart => _l(const L(
        'Запустити аукціон (2 год)',
        'Start auction (2h)',
        'Запустить аукцион (2 ч)',
      ));
  String get auctionMyTitle => _l(const L('Мої лоти', 'My lots', 'Мои лоты'));
  String get auctionMyEmpty => _l(const L('Ще немає лотів.', 'No lots yet.', 'Пока нет лотов.'));
  String get auctionLiveTitle => _l(const L('Живі лоти', 'Live lots', 'Живые лоты'));
  String get auctionLiveEmpty => _l(const L(
        'Зараз немає живих аукціонів.',
        'No live auctions right now.',
        'Сейчас нет живых аукционов.',
      ));
  String get auctionNoBids => _l(const L('Ставок ще немає', 'No bids yet', 'Ставок ещё нет'));
  String auctionTopBid(String name, String price) => _l(L(
        'Топ: $name · $price',
        'Top: $name · $price',
        'Топ: $name · $price',
      ));
  String auctionRepairWas(String price) => _l(L(
        'Ремонт оцінено в $price',
        'Repair quoted at $price',
        'Ремонт оценён в $price',
      ));
  String auctionShopCut(String price) => _l(L(
        'Комісія СТО за діагностику/угоду: $price',
        'Shop commission for diagnosis/deal: $price',
        'Комиссия СТО за диагностику/сделку: $price',
      ));
  String get auctionAccept => _l(const L('Прийняти топ-ставку', 'Accept top bid', 'Принять топ-ставку'));
  String get auctionBidAmount => _l(const L('Ваша ставка, грн', 'Your bid, UAH', 'Ваша ставка, грн'));
  String get auctionBidNote => _l(const L('Коментар покупця', 'Buyer note', 'Комментарий покупателя'));
  String get auctionBuyNow => _l(const L('Купити зараз', 'Buy Now', 'Купить сейчас'));
  String get auctionBuyNowPrice => _l(const L(
        'Ціна Buy Now, грн',
        'Buy Now price, UAH',
        'Цена Buy Now, грн',
      ));
  String get auctionMileage => _l(const L('Пробіг, км', 'Mileage, km', 'Пробег, км'));
  String get auctionDamage => _l(const L('Пошкодження', 'Damage', 'Повреждения'));
  String get auctionSellReason => _l(const L(
        'Чому продається',
        'Why it is sold',
        'Почему продаётся',
      ));
  String get auctionPhotosHint => _l(const L(
        'фото в лоті',
        'photos in lot',
        'фото в лоте',
      ));
  String get auctionPlaceBid => _l(const L('Зробити ставку', 'Place bid', 'Сделать ставку'));
  String get auctionOpenLot => _l(const L('Відкрити лот', 'Open lot', 'Открыть лот'));
  String get auctionTabLot => _l(const L('Лот', 'Lot', 'Лот'));
  String get auctionTabParticipants => _l(const L('Учасники', 'Participants', 'Участники'));
  String get auctionLoginToBid => _l(const L(
        'Увійдіть, щоб зробити ставку',
        'Sign in to place a bid',
        'Войдите, чтобы сделать ставку',
      ));
  String get auctionStartsAt => _l(const L('Старт', 'Starts', 'Старт'));
  String get auctionEndsAt => _l(const L('Кінець', 'Ends', 'Конец'));
  String get auctionNotStarted => _l(const L(
        'Аукціон ще не почався — ставки після дати старту.',
        'Auction has not started — bidding opens at the start time.',
        'Аукцион ещё не начался — ставки после даты старта.',
      ));
  String get auctionSoftCloseHint => _l(const L(
        'Ставка в останню хвилину додає +1 хв. Якщо лишилось 1–3 сек — час подовжується на +2 хв.',
        'A bid in the last minute adds +1 min. If 1–3 seconds remain — time extends by +2 min.',
        'Ставка в последнюю минуту даёт +1 мин. Если осталось 1–3 сек — время продлевается на +2 мин.',
      ));
  String get auctionShopLead => _l(const L(
        'Лоти «як є»: робіть ставки як перекуп / розбір / відновлювач. Якщо ви діагностували авто — при продажі нараховується комісія.',
        '“As is” lots: bid as a flipper / dismantler / restorer. If you diagnosed the car — you earn a commission on sale.',
        'Лоты «как есть»: делайте ставки как перекуп / разбор / восстановитель. Если вы диагностировали авто — при продаже начисляется комиссия.',
      ));
  String auctionPrefillDetails(String estimate) => _l(L(
        'Клієнт відмовився від ремонту (оцінка $estimate). Авто на аукціон «як є».',
        'Client refused repair (quote $estimate). Listing car as-is.',
        'Клиент отказался от ремонта (оценка $estimate). Авто на аукцион «как есть».',
      ));
  String get auctionFromEstimate => _l(const L(
        'Ремонт занадто дорогий — на аукціон',
        'Repair too expensive — auction',
        'Ремонт слишком дорогой — на аукцион',
      ));
  String get businessAccountTitle => _l(const L(
        'Бізнес-рахунок',
        'Business account',
        'Бизнес-счёт',
      ));
  String get businessAccountLead => _l(const L(
        'Якщо в управлінні більше 2 авто — один документ і один рахунок на всі.',
        'With more than 2 cars — one document and one invoice for all.',
        'Если в управлении больше 2 авто — один документ и один счёт на все.',
      ));
  String get businessNeedCars => _l(const L(
        'Додайте ще авто (потрібно більше 2), щоб відкрити бізнес-рахунок.',
        'Add more cars (need more than 2) to unlock business billing.',
        'Добавьте ещё авто (нужно больше 2), чтобы открыть бизнес-счёт.',
      ));
  String get shopToolsHub => _l(const L(
        'Звіти та реєстри',
        'Reports & registries',
        'Отчёты и реестры',
      ));
  String get shopDesignTitle => _l(const L(
        'Дизайн вашого сервісу',
        'Your service design',
        'Дизайн вашего сервиса',
        'Wygląd Twojego serwisu',
      ));
  String get shopDesignLead => _l(const L(
        'Так клієнт побачить вас у списку і на вході. Монограма — до 4 літер, форма лого — нижче.',
        'This is how clients see you in the list and on entry. Monogram up to 4 letters; pick a frame below.',
        'Так клиент увидит вас в списке и на входе. Монограмма — до 4 букв, форма лого — ниже.',
        'Tak zobaczą Cię na liście i przy wejściu. Monogram do 4 liter, ramę wybierz niżej.',
      ));
  String get shopDesignLogo => _l(const L('Логотип', 'Logo', 'Логотип', 'Logo'));
  String get shopDesignFont => _l(const L(
        'Шрифт назви',
        'Name typeface',
        'Шрифт названия',
        'Czcionka nazwy',
      ));
  String get shopLogoPick => _l(const L(
        'Логотип — як вас побачать клієнти',
        'Logo — how clients will see you',
        'Логотип — как вас увидят клиенты',
        'Logo — jak zobaczą Cię klienci',
      ));
  String get shopDesignSaved => _l(const L('Дизайн збережено', 'Design saved', 'Дизайн сохранён', 'Zapisano wygląd'));
  String get shopFontClassic => _l(const L('Класика', 'Classic', 'Классика', 'Klasyka'));
  String get shopFontAvenir => _l(const L('Avenir', 'Avenir', 'Avenir', 'Avenir'));
  String get shopFontSerif => _l(const L('Антиква', 'Serif', 'Антиква', 'Antykwa'));
  String get shopFontTech => _l(const L('Техно', 'Tech', 'Техно', 'Techno'));
  String get shopFontFutura => _l(const L('Futura', 'Futura', 'Futura', 'Futura'));
  String get shopLogoCrest => _l(const L('Герб', 'Crest', 'Герб', 'Herb'));
  String get shopLogoSeal => _l(const L('Печатка', 'Seal', 'Печать', 'Pieczęć'));
  String get shopLogoLetter => _l(const L('Літера', 'Letter', 'Буква', 'Litera'));
  String get shopLogoSign => _l(const L('Вивіска', 'Sign', 'Вывеска', 'Szyld'));
  String get shopLogoPulse => _l(const L('Пульс', 'Pulse', 'Пульс', 'Puls'));
  String get shopLogoHex => _l(const L('Гекс', 'Hex', 'Гекс', 'Heks'));
  String get shopLogoDiamond => _l(const L('Ромб', 'Diamond', 'Ромб', 'Romb'));
  String get shopLogoWing => _l(const L('Крила', 'Wings', 'Крылья', 'Skrzydła'));
  String get shopLogoWord => _l(const L(
        'Літери на лого',
        'Letters on the logo',
        'Буквы на лого',
        'Litery na logo',
      ));
  String get shopLogoWordHint => _l(const L(
        'Напр. APX',
        'e.g. APX',
        'Напр. APX',
        'np. APX',
      ));
  String get shopDeskTitle => _l(const L(
        'Кабінет автосервісу',
        'Shop desk',
        'Кабинет автосервиса',
      ));
  String get shopDeskLead => _l(const L(
        'Записи клієнтів, чат, камера боксу і послуги — у тому ж порядку, що й у клієнта.',
        'Client bookings, chat, bay camera and services — the same flow the client already uses.',
        'Записи клиентов, чат, камера бокса и услуги — в том же порядке, что и у клиента.',
      ));
  String get shopSignIn => _l(const L('Увійти в кабінет', 'Open desk', 'Войти в кабинет'));
  String get demoAccountsTitle => _l(const L(
        'Демо-вхід (ПК, Android, iPhone)',
        'Demo login (PC, Android, iPhone)',
        'Демо-вход (ПК, Android, iPhone)',
        'Demo logowanie (PC, Android, iPhone)',
      ));
  String get demoAdminHint => _l(const L(
        'Адмін СТО: admin / admin1234',
        'Shop admin: admin / admin1234',
        'Админ СТО: admin / admin1234',
      ));
  String get demoMasterHint => _l(const L(
        'Майстер: master / master1234',
        'Master: master / master1234',
        'Мастер: master / master1234',
      ));
  String get demoFill => _l(const L('Підставити', 'Fill in', 'Подставить', 'Wpisz'));
  String shopMasterIssued(String login, String password) => _l(L(
        'Кабінет готовий. Майстер: $login / $password — вхід через «Для автосервісів» → Майстер.',
        'Desk is ready. Master: $login / $password — sign in via For shops → Master.',
        'Кабинет готов. Мастер: $login / $password — вход через «Для автосервисов» → Мастер.',
      ));
  String get shopCreate => _l(const L(
        'Створити кабінет',
        'Create shop desk',
        'Создать кабинет',
      ));
  String get shopNeedData => _l(const L(
        'Вкажіть назву СТО, адресу, телефон і хоча б одну послугу',
        'Enter shop name, address, phone and at least one service',
        'Укажите название СТО, адрес, телефон и хотя бы одну услугу',
      ));
  String get shopAddress => _l(const L('Адреса', 'Address', 'Адрес'));
  String get shopPhone => _l(const L('Телефон', 'Phone', 'Телефон'));
  String get shopCity => _l(const L('Місто', 'City', 'Город'));
  String get shopServices => _l(const L(
        'Які послуги приймаєте',
        'Services you take',
        'Какие услуги принимаете',
      ));
  String get shopServicesHint => _l(const L(
        'Клієнт бачить ті самі категорії в СТО',
        'The client sees these same categories in Shops',
        'Клиент видит те же категории в СТО',
      ));
  String get shopTodayEmpty => _l(const L(
        'На сьогодні записів немає. Нові з’являться тут, щойно клієнт обере слот.',
        'No visits today. New ones land here as soon as a client picks a slot.',
        'На сегодня записей нет. Новые появятся здесь, как только клиент выберет слот.',
      ));
  String get shopNextVisit => _l(const L(
        'Наступне авто в черзі на заїзд',
        'Next car in the arrival queue',
        'Следующее авто в очереди на заезд',
        'Następne auto w kolejce na wjazd',
      ));
  String get shopAllToday => _l(const L(
        'Усі авто записані на сьогодні',
        'Cars booked for today',
        'Все авто записанные на сегодня',
        'Auta zapisane na dziś',
      ));
  String get shopExtrasSheetTitle => _l(const L(
        'Додаткові роботи',
        'Extra work requests',
        'Дополнительные работы',
        'Prośby o dodatkowe prace',
      ));
  String get shopExtrasNone => _l(const L(
        'Немає запитів на додаткові роботи',
        'No pending extras',
        'Нет запросов на дополнительные работы',
        'Brak oczekujących dopłat',
      ));
  String get shopMessagesSheetTitle => _l(const L(
        'Нові повідомлення',
        'New messages',
        'Новые сообщения',
        'Nowe wiadomości',
      ));
  String get shopMessagesNone => _l(const L(
        'Немає нових повідомлень',
        'No new messages',
        'Нет новых сообщений',
        'Brak nowych wiadomości',
      ));
  String get shopTakeInBay => _l(const L(
        'Прийняти в бокс',
        'Take into bay',
        'Принять в бокс',
        'Przyjmij na stanowisko',
      ));
  String get shopMarkReady => _l(const L(
        'Готово до видачі',
        'Ready for handover',
        'Готово к выдаче',
        'Gotowe do wydania',
      ));
  String get shopWaitingClient => _l(const L(
        'Чекаємо клієнта',
        'Waiting for client',
        'Ждём клиента',
        'Oczekiwanie na klienta',
      ));
  String get jobSceneWaiting => _l(const L('Чекаємо', 'Waiting', 'Ждём', 'Czekamy'));
  String get jobSceneInBay => _l(const L('У боксі', 'In the bay', 'В боксе', 'Na stanowisku'));
  String get jobSceneReady => _l(const L('Готово', 'Ready', 'Готово', 'Gotowe'));
  String get shopExtrasSent => _l(const L(
        'Дод. роботи надіслано клієнту',
        'Extra work sent to the client',
        'Доп. работы отправлены клиенту',
        'Dod. prace wysłane do klienta',
      ));
  String get shopExtrasPending => _l(const L(
        'Дод. роботи на підтвердження',
        'Extras to approve',
        'Доп. работы на подтверждение',
        'Dod. prace do akceptacji',
      ));
  String get shopOfferExtra => _l(const L(
        'Запропонувати дод. роботу',
        'Offer extra work',
        'Предложить доп. работу',
        'Zaproponuj dod. pracę',
      ));
  String get shopOfferSent => _l(const L(
        'Надіслано клієнту на підтвердження',
        'Sent to the client for approval',
        'Отправлено клиенту на подтверждение',
      ));
  String get shopConnectCam => _l(const L(
        'Підключити вебкам',
        'Connect webcam',
        'Подключить вебкам',
      ));
  String get shopCamConnecting => _l(const L(
        'Підключення…',
        'Connecting…',
        'Подключение…',
      ));
  String get shopCamOn => _l(const L(
        'Камера підключена',
        'Camera connected',
        'Камера подключена',
      ));
  String get shopCamOff => _l(const L(
        'Камера вимкнена',
        'Camera off',
        'Камера выключена',
      ));
  String get shopGoLive => _l(const L('В ефір', 'Go live', 'В эфир'));
  String get shopStopLive => _l(const L('Зняти з ефіру', 'End live', 'Снять с эфира'));
  String get shopLiveHint => _l(const L(
        'Клієнт бачить цей ефір у стрічці, на картці СТО і в записі — як камеру боксу.',
        'The client sees this feed in the timeline, on the shop card and in the booking — as the bay camera.',
        'Клиент видит этот эфир в ленте, на карточке СТО и в записи — как камеру бокса.',
      ));
  String get shopCamFallback => _l(const L(
        'Немає доступу до камери — показуємо ефір боксу, щоб клієнт усе одно бачив LIVE.',
        'No camera access — showing the bay feed so the client still sees LIVE.',
        'Нет доступа к камере — показываем эфир бокса, чтобы клиент всё равно видел LIVE.',
      ));
  String get shopChatHint => _l(const L(
        'Написати клієнту…',
        'Message the client…',
        'Написать клиенту…',
      ));
  String get shopChatEmpty => _l(const L(
        'Чат з’явиться після першого запису',
        'Chat appears after the first booking',
        'Чат появится после первой записи',
      ));
  String get shopUnread => _l(const L('Нове', 'New', 'Новое'));
  String get shopKioskHall => _l(const L(
        'Кіоск у залі',
        'Hall kiosk',
        'Киоск в зале',
      ));
  String get shopOpenChat => _l(const L(
        'Відкрити чат',
        'Open chat',
        'Открыть чат',
        'Otwórz czat',
      ));
  String get shopStatVisits => _l(const L(
        'На сьогодні',
        'Today',
        'На сегодня',
        'Na dziś',
      ));
  String get shopStatExtras => _l(const L(
        'Дод. роботи',
        'Extras',
        'Доп. работы',
        'Dod. prace',
      ));
  String get shopStatChat => _l(const L(
        'Повідомлення',
        'Messages',
        'Сообщения',
        'Wiadomości',
      ));
  String get shopOpenCam => _l(const L('Камера', 'Camera', 'Камера'));
  String get shopNoJobs => _l(const L(
        'Поки немає записів. Клієнт обирає СТО, послугу і слот — картка з’явиться тут.',
        'No bookings yet. When a client picks a shop, a service and a slot, the card lands here.',
        'Пока нет записей. Клиент выбирает СТО, услугу и слот — карточка появится здесь.',
      ));
  String get shopSaveDesk => _l(const L('Зберегти', 'Save', 'Сохранить', 'Zapisz'));
  String get shopSaved => _l(const L('Збережено', 'Saved', 'Сохранено', 'Zapisano'));
  String get shopCommissionTitle => _l(const L(
        'Комісія Ta4ka 5%',
        'Ta4ka commission 5%',
        'Комиссия Ta4ka 5%',
        'Prowizja Ta4ka 5%',
      ));
  String get shopCommissionHint => _l(const L(
        'Після виконаної роботи 5% від суми букінгу нараховується на борг СТО. Оплата за реквізитами — раз на місяць до 1 числа. Без оплати кабінет блокується.',
        'After completed work, 5% of the booking total is added to the shop debt. Pay by bank details once a month by the 1st. Unpaid debt blocks the account.',
        'После выполненной работы 5% от суммы букинга начисляется на долг СТО. Оплата по реквизитам — раз в месяц до 1 числа. Без оплаты кабинет блокируется.',
        'Po wykonanej pracy 5% kwoty rezerwacji trafia na dług warsztatu. Płatność na rachunek raz w miesiącu do 1. dnia. Brak płatności blokuje konto.',
      ));
  String shopCommissionDebt(String amount) => _l(L(
        'Борг: $amount',
        'Debt: $amount',
        'Долг: $amount',
        'Dług: $amount',
      ));
  String get shopCommissionPay => _l(const L(
        'Позначити як оплачено',
        'Mark as paid',
        'Отметить как оплачено',
        'Oznacz jako opłacone',
      ));
  String get shopCommissionRequisites => _l(const L(
        'Реквізити для оплати комісії',
        'Bank details for commission',
        'Реквизиты для оплаты комиссии',
        'Dane do przelewu prowizji',
      ));
  String get shopBlockedTitle => _l(const L(
        'Кабінет заблоковано',
        'Account blocked',
        'Кабинет заблокирован',
        'Konto zablokowane',
      ));
  String get shopBlockedBody => _l(const L(
        'Сплатіть комісію 5% за реквізитами і натисніть «Позначити як оплачено» у кабінеті СТО.',
        'Pay the 5% commission using the bank details, then tap “Mark as paid” in the shop desk.',
        'Оплатите комиссию 5% по реквизитам и нажмите «Отметить как оплачено» в кабинете СТО.',
        'Opłać prowizję 5% na podane konto, potem w panelu warsztatu kliknij „Oznacz jako opłacone”.',
      ));
  String get shopChatClients => _l(const L(
        'Клієнти',
        'Clients',
        'Клиенты',
        'Klienci',
      ));
  String get shopChatMasters => _l(const L(
        'Майстри',
        'Technicians',
        'Мастера',
        'Mechanicy',
      ));
  String get shopMasterChatHint => _l(const L(
        'Повідомлення майстру…',
        'Message the technician…',
        'Сообщение мастеру…',
        'Wiadomość do mechanika…',
      ));
  String get shopCamHowToTitle => _l(const L(
        'Як підключити вебкамеру',
        'How to connect a webcam',
        'Как подключить веб-камеру',
        'Jak podłączyć kamerę',
      ));
  String get shopCamHowToBody => _l(const L(
        '1) Підключіть камеру до ПК або дозвольте доступ у браузері.\n2) Натисніть «Підключити вебкам».\n3) Увімкніть LIVE — клієнт бачить бокс у записі.',
        '1) Plug in the camera or allow browser access.\n2) Tap “Connect webcam”.\n3) Turn LIVE on — the client sees the bay in the booking.',
        '1) Подключите камеру к ПК или разрешите доступ в браузере.\n2) Нажмите «Подключить вебкам».\n3) Включите LIVE — клиент видит бокс в записи.',
        '1) Podłącz kamerę lub zezwól w przeglądarce.\n2) Kliknij „Podłącz kamerę”.\n3) Włącz LIVE — klient widzi stanowisko w rezerwacji.',
      ));
  String get shopMyCameras => _l(const L(
        'Мої камери',
        'My cameras',
        'Мои камеры',
        'Moje kamery',
      ));
  String get shopMyCamerasHint => _l(const L(
        'Камери боксів по авто в роботі — гортайте стрічку.',
        'Bay cameras for cars in the shop — scroll the feed.',
        'Камеры боксов по авто в работе — листайте ленту.',
        'Kamery stanowisk aut w warsztacie — przewiń listę.',
      ));
  String get shopOpenOrder => _l(const L(
        'Відкрити заказ-наряд',
        'Open work order',
        'Открыть заказ-наряд',
        'Otwórz zlecenie',
      ));
  String get shopHoursEdit => _l(const L(
        'Змінити години',
        'Edit hours',
        'Изменить часы',
        'Zmień godziny',
      ));
  String get shopChangeTime => _l(const L(
        'Змінити час',
        'Change time',
        'Изменить время',
        'Zmień czas',
      ));
  String get shopStaffApply => _l(const L(
        'Сформувати майстрів',
        'Build technicians',
        'Сформировать мастеров',
        'Utwórz mechaników',
      ));
  String get shopMasterName => _l(const L('Імʼя майстра', 'Technician name', 'Имя мастера', 'Imię mechanika'));
  String get shopMasterYears => _l(const L('Стаж, років', 'Years of experience', 'Стаж, лет', 'Staż, lat'));
  String get shopMasterPace => _l(const L('Темп роботи', 'Work pace', 'Темп работы', 'Tempo pracy'));
  String get shopMasterPaceIntern => _l(const L('Стажер', 'Intern', 'Стажёр', 'Stażysta'));
  String get shopMasterPaceNormal => _l(const L('Працює', 'Steady', 'Работает', 'Stabilnie'));
  String get shopMasterPaceFast => _l(const L('Швидкий', 'Fast', 'Быстрый', 'Szybki'));
  String get shopMasterPaceCareful => _l(const L('Ретельний', 'Careful', 'Аккуратный', 'Dokładny'));
  String get shopPositioningTitle => _l(const L(
        'Позиціонування вашого СТО',
        'Positioning of your shop',
        'Позиционирование вашего СТО',
        'Pozycjonowanie warsztatu',
      ));
  String get shopPricePositionTitle => _l(const L(
        'Позиціонування ціни',
        'Price positioning',
        'Позиционирование цены',
        'Pozycjonowanie ceny',
      ));
  String get shopLoadTodayTitle => _l(const L(
        'Завантаження на сьогодні',
        'Load today',
        'Загрузка на сегодня',
        'Obciążenie dziś',
      ));
  String get shopHoursOpen => _l(const L('Відкриття', 'Opens', 'Открытие', 'Otwarcie'));
  String get shopHoursClose => _l(const L('Закриття', 'Closes', 'Закрытие', 'Zamknięcie'));
  String get shopHoursOpenNow => _l(const L(
        'Зараз відкрито',
        'Open now',
        'Сейчас открыто',
        'Teraz otwarte',
      ));
  String get shopHoursClosedNow => _l(const L(
        'Зараз зачинено',
        'Closed now',
        'Сейчас закрыто',
        'Teraz zamknięte',
      ));
  String get shopPartsDelivery => _l(const L(
        'Запчастини: є доставка / забезпечення',
        'Parts: delivery / supply available',
        'Запчасти: есть доставка / обеспечение',
        'Części: jest dostawa / zaopatrzenie',
      ));
  String get shopPartsDeliveryHint => _l(const L(
        'Клієнт зможе обрати свої запчастини або замовити у СТО',
        'Client can bring own parts or take them from the shop',
        'Клиент сможет выбрать свои запчасти или заказать у СТО',
        'Klient może dać swoje części albo wziąć od warsztatu',
      ));
  String get shopDeskReadyTitle => _l(const L(
        'Основні дані про ваше СТО внесено',
        'Main shop details are filled in',
        'Основные данные о вашем СТО внесены',
        'Główne dane warsztatu są uzupełnione',
      ));
  String get shopDeskReadyLead => _l(const L(
        'Тепер оберіть роботи, які надає ваше СТО.',
        'Now choose the jobs your shop provides.',
        'Теперь выберите работы, которые предоставляет ваше СТО.',
        'Teraz wybierz prace, które świadczy warsztat.',
      ));
  String get shopPublish => _l(const L('Опублікувати', 'Publish', 'Опубликовать', 'Opublikuj'));
  String get shopClientSees => _l(const L(
        'Клієнтам видно',
        'Clients see',
        'Клиентам видно',
        'Klienci widzą',
      ));
  String get shopPartsYes => _l(const L('є запчастини від СТО', 'shop can supply parts', 'есть запчасти от СТО', 'warsztat daje części'));
  String get shopPartsNo => _l(const L('без забезпечення запчастин', 'no parts supply', 'без обеспечения запчастей', 'bez części od warsztatu'));
  String get shopWorksAiTitle => _l(const L(
        'Роботи сервісу (AI-підбір)',
        'Shop jobs (AI match)',
        'Работы сервиса (AI-подбор)',
        'Prace warsztatu (AI)',
      ));
  String get shopWorksAiHint => _l(const L(
        'Майстер пише своїми словами — система підкидає релевантні види робіт з ваших категорій. Відмітьте, що реально робите.',
        'Write in your words — the system suggests jobs from your categories. Mark what you really do.',
        'Мастер пишет своими словами — система подкидывает работы из ваших категорий. Отметьте, что реально делаете.',
        'Pisz swoimi słowami — system podpowiada prace z Twoich kategorii. Zaznacz, co naprawdę robicie.',
      ));
  String get shopWorksAiPrompt => _l(const L('Запит майстра', 'Technician query', 'Запрос мастера', 'Zapytanie mechanika'));
  String get shopWorksAiPromptHint => _l(const L(
        'Напр: автоелектроніка, блоки комфорту, діагностика CAN…',
        'E.g. auto electrics, comfort modules, CAN diagnostics…',
        'Напр: автоэлектроника, блоки комфорта, диагностика CAN…',
        'Np. elektryka, komfort, diagnostyka CAN…',
      ));
  String get shopWorksAiTips => _l(const L('AI-підказки', 'AI tips', 'AI-подсказки', 'Podpowiedzi AI'));
  String get shopWorksSelected => _l(const L('Обрано робіт', 'Jobs selected', 'Выбрано работ', 'Wybrane prace'));
  String get shopCustomServices => _l(const L(
        'Свої послуги сервісу',
        'Your custom services',
        'Свои услуги сервиса',
        'Własne usługi',
      ));
  String get shopAddService => _l(const L('Додати послугу', 'Add service', 'Добавить услугу', 'Dodaj usługę'));
  String get shopAddServiceHint => _l(const L(
        'Напр: мийка, полірування фар…',
        'E.g. wash, headlight polish…',
        'Напр: мойка, полировка фар…',
        'Np. mycie, polerowanie lamp…',
      ));
  String get shopAdd => _l(const L('Додати', 'Add', 'Добавить', 'Dodaj'));
  String get shopCustomServicesEmpty => _l(const L(
        'Поки немає своїх послуг.',
        'No custom services yet.',
        'Пока нет своих услуг.',
        'Brak własnych usług.',
      ));
  String get partsSourceTitle => _l(const L(
        'Запчастини',
        'Spare parts',
        'Запчасти',
        'Części',
      ));
  String get partsSourceLead => _l(const L(
        'СТО може забезпечити запчастини. Оберіть варіант:',
        'This shop can supply parts. Choose an option:',
        'СТО может обеспечить запчасти. Выберите вариант:',
        'Warsztat może dać części. Wybierz opcję:',
      ));
  String get partsSourceOwn => _l(const L(
        'Мої запчастини',
        'My own parts',
        'Свои запчасти',
        'Moje części',
      ));
  String get partsSourceShop => _l(const L(
        'Запчастини від СТО',
        'Parts from the shop',
        'Запчасти от СТО',
        'Części od warsztatu',
      ));
  String get partsSupplyBadge => _l(const L(
        'Є забезпечення запчастин',
        'Parts supply available',
        'Есть обеспечение запчастей',
        'Jest zaopatrzenie w części',
      ));

  String get loyaltyCashbackLead => _l(const L(
        'Кешбек з оплачених робіт. Піднімайте рівень — рекламуйте Ta4ka.',
        'Cashback on paid jobs. Level up by promoting Ta4ka.',
        'Кешбек с оплаченных работ. Поднимайте уровень — рекламируйте Ta4ka.',
      ));
  String get loyaltyHowTitle => _l(const L(
        'Як підвищити рівень',
        'How to level up',
        'Как повысить уровень',
      ));
  String get loyaltyShareCta => _l(const L(
        'Поділитись',
        'Share',
        'Поделиться',
        'Udostępnij',
      ));
  String get loyaltyShareHint => _l(const L(
        'у чаті або соцмережах',
        'in chat or socials',
        'в чате или соцсетях',
        'w czacie lub socialach',
      ));
  String get loyaltyShareXp => _l(const L('+40 XP', '+40 XP', '+40 XP', '+40 XP'));
  String loyaltyShareCopy(String code) => _l(L(
        'Ta4ka — запис на СТО з камерою боксу. Мій код: $code',
        'Ta4ka — book a shop with a bay camera. My code: $code',
        'Ta4ka — запись на СТО с камерой бокса. Мой код: $code',
        'Ta4ka — rezerwacja warsztatu z kamerą. Mój kod: $code',
      ));
  String get loyaltyShareDone => _l(const L(
        '+40 XP · дякуємо, що рекламуєте Ta4ka!',
        '+40 XP · thanks for promoting Ta4ka!',
        '+40 XP · спасибо, что рекламируете Ta4ka!',
      ));
  String get loyaltyMaxLevel => _l(const L(
        'Максимальний рівень · 10% кешбек',
        'Max level · 10% cashback',
        'Максимальный уровень · 10% кешбек',
      ));
  String loyaltyXpProgress(int have, int need) => _l(L(
        'До наступного рівня: $have / $need XP',
        'To next level: $have / $need XP',
        'До следующего уровня: $have / $need XP',
      ));

  String get referralTitle => _l(const L(
        'Реферальна програма',
        'Referral program',
        'Реферальная программа',
      ));
  String get referralHomeCta => _l(const L(
        'Реферальна програма',
        'Referral program',
        'Реферальная программа',
      ));
  String get referralProfileSubtitle => _l(const L(
        '3% з обороту СТО назавжди',
        '3% of shop turnover forever',
        '3% с оборота СТО навсегда',
        '3% obrotu warsztatu na zawsze',
      ));
  String get referralLevelsBadge => _l(const L(
        'L1 3% · L2 1% · L3 0,5%',
        'L1 3% · L2 1% · L3 0.5%',
        'L1 3% · L2 1% · L3 0,5%',
        'L1 3% · L2 1% · L3 0,5%',
      ));
  String get referralTabCabinet => _l(const L('Кабінет', 'Cabinet', 'Кабинет'));
  String get referralTabTerms => _l(const L('Умови', 'Terms', 'Условия'));
  String get referralTabConnect => _l(const L('Підключити', 'Connect', 'Подключить'));
  String get referralTabAdmin => _l(const L('Адмін', 'Admin', 'Админ'));
  String get referralCabinetLead => _l(const L(
        'Особистий кабінет: скільки СТО ви привели, їх оборот за місяць і ваш %.',
        'Personal cabinet: how many shops you brought, their monthly turnover and your %.',
        'Личный кабинет: сколько СТО вы привели, их оборот за месяц и ваш %.',
      ));
  String get referralYourCode => _l(const L('Ваш реферальний код', 'Your referral code', 'Ваш реферальный код'));
  String get referralCodeCopied => _l(const L('Код скопійовано', 'Code copied', 'Код скопирован'));
  String get referralStatShops => _l(const L('Приведено СТО', 'Shops brought', 'Приведено СТО'));
  String get referralStatTurnover => _l(const L('Оборот СТО / міс', 'Shop turnover / mo', 'Оборот СТО / мес'));
  String get referralStatEarned => _l(const L('Ваш % / міс', 'Your % / mo', 'Ваш % / мес'));
  String get referralStatLevels => _l(const L('Рівні мережі', 'Network levels', 'Уровни сети'));
  String get referralPayoutTitle => _l(const L('Реквізити для виплат', 'Payout details', 'Реквизиты для выплат'));
  String get referralPayoutLead => _l(const L(
        'Вкажіть, куди переказувати винагороду. Виплати — за підсумками місяця.',
        'Tell us where to send rewards. Payouts are monthly.',
        'Укажите, куда переводить вознаграждение. Выплаты — по итогам месяца.',
      ));
  String get referralFullName => _l(const L('ПІБ отримувача', 'Recipient full name', 'ФИО получателя'));
  String get referralIban => _l(const L('IBAN / рахунок', 'IBAN / account', 'IBAN / счёт'));
  String get referralPhone => _l(const L('Телефон', 'Phone', 'Телефон'));
  String get referralRequisitesExtra => _l(const L(
        'Додаткові реквізити (банк, коментар)',
        'Extra details (bank, note)',
        'Доп. реквизиты (банк, комментарий)',
      ));
  String get referralSaveRequisites => _l(const L('Зберегти реквізити', 'Save payout details', 'Сохранить реквизиты'));
  String get referralRequisitesSaved => _l(const L('Реквізити збережено', 'Details saved', 'Реквизиты сохранены'));
  String get referralMyShops => _l(const L('Мої СТО', 'My shops', 'Мои СТО'));
  String get referralNoShops => _l(const L('Ще немає підключених СТО.', 'No connected shops yet.', 'Пока нет подключённых СТО.'));
  String get referralStatusApproved => _l(const L('Підтверджено', 'Approved', 'Подтверждено'));
  String get referralStatusPending => _l(const L('На перевірці', 'Pending review', 'На проверке'));
  String get referralStatusRejected => _l(const L('Відхилено', 'Rejected', 'Отклонено'));
  String get referralMonthEarn => _l(const L('За місяць', 'This month', 'За месяц'));
  String get referralFromTurnover => _l(const L('з обороту', 'of turnover', 'с оборота'));
  String get referralTermsTitle => _l(const L('Умови реферальної програми', 'Referral terms', 'Условия реферальной программы'));
  String get referralTermsLead => _l(const L(
        'Три рівні. Ви приходите на СТО, показуєте додаток Ta4ka і допомагаєте сервісу швидко запуститись.',
        'Three levels. You visit a shop, show Ta4ka, and help them launch quickly.',
        'Три уровня. Вы приходите на СТО, показываете приложение Ta4ka и помогаете сервису быстро запуститься.',
      ));
  String get referralTerm1 => _l(const L(
        'Приходьте особисто на СТО у своєму місті.',
        'Visit a car service in person in your city.',
        'Приходите лично на СТО в своём городе.',
      ));
  String get referralTerm2 => _l(const L(
        'Покажіть додаток Ta4ka менеджеру / власнику.',
        'Show the Ta4ka app to the manager / owner.',
        'Покажите приложение Ta4ka менеджеру / владельцу.',
      ));
  String get referralTerm3 => _l(const L(
        'Допоможіть налаштувати додаток: вхід в admin, швидка реєстрація СТО.',
        'Help set up the app: admin login and quick shop registration.',
        'Помогите настроить приложение: вход в admin, быстрая регистрация СТО.',
      ));
  String get referralTerm4 => _l(const L(
        'Зробіть фото сервісу (фасад / бокс / вивіска).',
        'Take a photo of the shop (front / bay / sign).',
        'Сделайте фото сервиса (фасад / бокс / вывеска).',
      ));
  String get referralTerm5 => _l(const L(
        'Погодьте підключення з менеджером СТО.',
        'Get approval from the shop manager.',
        'Согласуйте подключение с менеджером СТО.',
      ));
  String get referralTerm6 => _l(const L(
        'Завантажте фото в розділі «Підключити» — заявка піде на перевірку.',
        'Upload the photo under Connect — the request goes to review.',
        'Загрузите фото в разделе «Подключить» — заявка уйдёт на проверку.',
      ));
  String get referralTerm7 => _l(const L(
        'Після підтвердження ви отримуєте 3% від доходу цього СТО назавжди (рівень 1).',
        'After approval you earn 3% of that shop’s income forever (level 1).',
        'После подтверждения вы получаете 3% от дохода этого СТО навсегда (уровень 1).',
      ));
  String get referralTerm8 => _l(const L(
        'Можна підключати будь-яку кількість СТО і запрошувати партнерів у свою мережу.',
        'You can connect any number of shops and invite partners into your network.',
        'Можно подключать любое количество СТО и приглашать партнёров в свою сеть.',
      ));
  String get referralLevelsExplain => _l(const L(
        'Рівні: L1 — 3% з СТО, які підключили ви · L2 — 1% з СТО партнерів · L3 — 0,5% з мережі партнерів.',
        'Levels: L1 — 3% from shops you connected · L2 — 1% from partners’ shops · L3 — 0.5% from their network.',
        'Уровни: L1 — 3% с СТО, которые подключили вы · L2 — 1% с СТО партнёров · L3 — 0,5% с сети партнёров.',
      ));
  String get referralConnectTitle => _l(const L('Підключити нове СТО', 'Connect a new shop', 'Подключить новое СТО'));
  String get referralConnectLead => _l(const L(
        'Після візиту заповніть форму: назва, місто, менеджер і фото. Заявка з’явиться в адмін-панелі.',
        'After the visit fill the form: name, city, manager and photo. The request appears in admin.',
        'После визита заполните форму: название, город, менеджер и фото. Заявка появится в админ-панели.',
      ));
  String get referralShopName => _l(const L('Назва СТО', 'Shop name', 'Название СТО'));
  String get referralShopCity => _l(const L('Місто', 'City', 'Город'));
  String get referralManager => _l(const L('Менеджер / власник', 'Manager / owner', 'Менеджер / владелец'));
  String get referralPhotoLink => _l(const L('Посилання на фото', 'Photo link', 'Ссылка на фото'));
  String get referralConnectNote => _l(const L('Короткий коментар', 'Short note', 'Краткий комментарий'));
  String get referralSubmitShop => _l(const L('Надіслати на перевірку', 'Submit for review', 'Отправить на проверку'));
  String get referralSubmitted => _l(const L(
        'Заявку прийнято. Перевірте вкладку «Адмін».',
        'Request submitted. Check the Admin tab.',
        'Заявка принята. Проверьте вкладку «Админ».',
      ));
  String get referralAdminTitle => _l(const L('Адмін-панель реферала', 'Referral admin panel', 'Админ-панель реферала'));
  String get referralAdminLead => _l(const L(
        'Підтверджуйте свої підключення, дивіться мережу і місячний %.',
        'Approve your connections, view the network and monthly %.',
        'Подтверждайте свои подключения, смотрите сеть и месячный %.',
      ));
  String get referralPendingTitle => _l(const L('Очікують підтвердження', 'Awaiting approval', 'Ожидают подтверждения'));
  String get referralPendingEmpty => _l(const L('Немає заявок у черзі.', 'No pending requests.', 'Нет заявок в очереди.'));
  String get referralApprove => _l(const L('Підтвердити', 'Approve', 'Подтвердить'));
  String get referralReject => _l(const L('Відхилити', 'Reject', 'Отклонить'));
  String get referralNetworkTitle => _l(const L('Мережа', 'Network', 'Сеть'));
  String referralNetworkStats(int shops, String turnover, String earned) => _l(L(
        'Активних СТО: $shops · оборот місяця: $turnover · ваш дохід: $earned',
        'Active shops: $shops · month turnover: $turnover · your income: $earned',
        'Активных СТО: $shops · оборот месяца: $turnover · ваш доход: $earned',
      ));
}
