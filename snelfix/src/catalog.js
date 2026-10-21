const t = (nl, en, ru, uk) => ({ nl, en, ru, uk });

export const GARAGES = [
  {
    id: "waddinxveen",
    name: "SnelFix Auto Waddinxveen",
    street: "Kromme Esse 4e",
    postal: "2741 KP",
    city: "Waddinxveen",
    lat: 52.04131806,
    lng: 4.66285419,
    phone: "+31613044422",
    note: t(
      "Werkplaats aan de Kromme Esse. Parkeren kan voor de deur. Bel of app even als u er bent.",
      "Workshop on Kromme Esse. You can park in front. Call or message when you arrive.",
      "Мастерская на Kromme Esse. Парковка перед входом. Позвоните или напишите, когда будете на месте.",
      "Майстерня на Kromme Esse. Паркування перед входом. Подзвоніть або напишіть, коли будете на місці."
    ),
  },
  {
    id: "de-bilt",
    name: "SnelFix Auto De Bilt",
    street: "Groenekanseweg 66A",
    postal: "3732 AG",
    city: "De Bilt",
    lat: 52.11416066,
    lng: 5.18662524,
    phone: "+31613044422",
    note: t(
      "Werkplaats aan de Groenekanseweg. Bel bij aankomst als de poort dicht is.",
      "Workshop on Groenekanseweg. Call on arrival if the gate is closed.",
      "Мастерская на Groenekanseweg. Если ворота закрыты, позвоните по прибытии.",
      "Майстерня на Groenekanseweg. Якщо ворота зачинені, подзвоніть, коли приїдете."
    ),
  },
];

export const WEEKLY_HOURS = [
  [0, null, null],
  [1, 8 * 60, 18 * 60],
  [2, 8 * 60, 18 * 60],
  [3, 8 * 60, 18 * 60],
  [4, 8 * 60, 18 * 60],
  [5, 8 * 60, 18 * 60],
  [6, 9 * 60, 14 * 60],
];

function svc(partial) {
  return {
    bookable: 1,
    kind: "workshop",
    price: null,
    ...partial,
  };
}

export const SERVICES = [
  svc({
    id: "computerdiagnose",
    duration: 60,
    price: 6900,
    sort: 10,
    image: "/photos/cabin.jpg",
    title: t("Computerdiagnose", "Computer diagnostics", "Компьютерная диагностика", "Комп'ютерна діагностика"),
    summary: t(
      "Uitlezen, live data en een oordeel over de echte oorzaak. Een foutcode is een begin, geen rekening.",
      "Fault codes, live data and a judgement on the real cause. A code is a start, not an invoice.",
      "Считывание ошибок, живые данные и вывод о настоящей причине. Код — это начало, а не счёт.",
      "Зчитування помилок, живі дані й висновок про справжню причину. Код — це початок, а не рахунок."
    ),
    body: t(
      "We sluiten professionele diagnose-apparatuur aan en kijken verder dan de opgeslagen foutcode. Sensoren, bedrading en het onderdeel zelf worden gecontroleerd voordat we iets vervangen. U krijgt een heldere uitleg en een voorstel, zonder verplichting om meteen de hele lijst te laten doen.\n\nNeem het kenteken mee en vertel wanneer het lampje ging branden, of de storing koud of warm optreedt en of de auto nog normaal rijdt.",
      "We connect professional diagnostic equipment and look past the stored fault code. Sensors, wiring and the part itself are checked before anything is replaced. You get a clear explanation and a proposal, with no obligation to approve the whole list at once.\n\nBring the registration document and tell us when the light came on, whether the fault appears hot or cold, and whether the car still drives normally.",
      "Подключаем профессиональное оборудование и смотрим дальше сохранённого кода. Датчики, проводка и сама деталь проверяются до замены. Вы получаете понятное объяснение и предложение, без обязанности сразу одобрять весь список.\n\nВозьмите свидетельство о регистрации и расскажите, когда загорелась лампа, проявляется ли ошибка на холодную или на горячую и едет ли машина нормально.",
      "Підключаємо професійне обладнання й дивимось далі за збережений код. Датчики, проводка й сама деталь перевіряються до заміни. Ви отримуєте зрозуміле пояснення і пропозицію, без обов'язку одразу погоджувати весь список.\n\nВізьміть свідоцтво про реєстрацію і розкажіть, коли загорілась лампа, чи з'являється помилка на холодну чи на гарячу і чи їде авто нормально."
    ),
  }),
  svc({
    id: "visuele-diagnose",
    duration: 45,
    price: 4500,
    sort: 20,
    image: "/photos/mechanic.jpg",
    title: t("Visuele diagnose", "Visual diagnostics", "Визуальная диагностика", "Візуальна діагностика"),
    summary: t(
      "Onder de auto, in de motorruimte en langs het onderstel: kijken, meten en vastleggen wat versleten is.",
      "Under the car, in the bay and along the suspension: look, measure and record what is worn.",
      "Под машиной, в моторном отсеке и по подвеске: смотрим, измеряем и фиксируем износ.",
      "Під машиною, у моторному відсіку й по підвісці: дивимось, міряємо і фіксуємо знос."
    ),
    body: t(
      "Niet elke klacht begint met een storinglampje. Speling, lekkage, een scheur in een hoes of een ongelijk slijtagebeeld zien we op de brug. We fotograferen wat relevant is, zodat u zelf ziet waarom een onderdeel aan de beurt is.\n\nHandig vóór een aankoop, na een melding bij de keuring of als de auto trekt, bonkt of een kant op staat.",
      "Not every complaint starts with a warning light. Play, a leak, a torn boot or uneven wear shows up on the lift. We photograph what matters so you can see why a part is due.\n\nUseful before a purchase, after an inspection note, or when the car pulls, knocks or sits to one side.",
      "Не каждая жалоба начинается с лампы. Люфт, течь, порванный пыльник или неравномерный износ видно на подъёмнике. Важное фотографируем, чтобы было видно, почему деталь пора менять.\n\nПолезно перед покупкой, после замечания на техосмотре или если машину тянет, стучит или она стоит криво.",
      "Не кожна скарга починається з лампи. Люфт, теча, порваний пильник або нерівномірний знос видно на підйомнику. Важливе фотографуємо, щоб було видно, чому деталь час міняти.\n\nКорисно перед покупкою, після зауваження на огляді або якщо авто тягне, стукає чи стоїть криво."
    ),
  }),
  svc({
    id: "motor-versnellingsbak",
    duration: 180,
    price: null,
    sort: 30,
    image: "/photos/belts.jpg",
    title: t("Motor en versnellingsbak", "Engine and gearbox", "Двигатель и коробка", "Двигун і коробка"),
    summary: t(
      "Reparatie van motor en bak na diagnose. Geen gokwerk en geen vaste prijs vóór we de oorzaak kennen.",
      "Engine and gearbox repair after diagnosis. No guesswork and no fixed price before the cause is known.",
      "Ремонт двигателя и коробки после диагностики. Без угадывания и без твёрдой цены, пока причина не ясна.",
      "Ремонт двигуна й коробки після діагностики. Без вгадування і без твердої ціни, поки причина не зрозуміла."
    ),
    body: t(
      "Distributie, lekkage, onregelmatig lopen, een slippende koppeling of een bak die slecht schakelt: we beginnen met meten. Daarna spreken we de reparatie af, inclusief onderdelen en tijd. Grote ingrepen plannen we zodat de auto niet langer stilstaat dan nodig.\n\nDe prijs op deze pagina ontbreekt bewust. Een motor of bak citeren zonder de auto gezien te hebben is een schatting, geen afspraak.",
      "Timing drive, a leak, uneven running, a slipping clutch or a gearbox that will not shift: we start by measuring. Then we agree the repair, including parts and time. Larger jobs are planned so the car is not off the road longer than it needs to be.\n\nThere is no price on this page on purpose. Quoting an engine or gearbox without seeing the car is a guess, not an appointment.",
      "ГРМ, течь, неровная работа, буксующее сцепление или коробка, которая плохо включается: начинаем с измерений. Потом согласуем ремонт, включая запчасти и время. Крупные работы планируем так, чтобы машина не стояла дольше нужного.\n\nЦены здесь нет специально. Называть стоимость двигателя или коробки, не видя авто, — это догадка, а не договорённость.",
      "ГРМ, теча, нерівна робота, буксуюче зчеплення або коробка, яка погано вмикається: починаємо з вимірів. Потім погоджуємо ремонт, включно з запчастинами й часом. Великі роботи плануємо так, щоб авто не стояло довше, ніж треба.\n\nЦіни тут немає навмисно. Називати вартість двигуна чи коробки, не бачачи авто, — це здогад, а не домовленість."
    ),
  }),
  svc({
    id: "olie-filter",
    duration: 45,
    price: 9500,
    sort: 40,
    image: "/photos/oil.jpg",
    title: t("Olie en filter", "Oil and filter", "Масло и фильтр", "Олива і фільтр"),
    summary: t(
      "Motorolie en filter volgens de specificatie van de fabrikant, met controle van niveaus en zichtbare lekkage.",
      "Engine oil and filter to the maker's specification, plus a check of levels and visible leaks.",
      "Моторное масло и фильтр по спецификации производителя, плюс проверка уровней и видимых течей.",
      "Моторна олива і фільтр за специфікацією виробника, плюс перевірка рівнів і видимих теч."
    ),
    body: t(
      "We verversen olie en oliefilter met de viscositeit en specificatie die bij uw motor hoort. Het oude filter gaat eraf, de plug en pakking worden gecontroleerd en het peil wordt na het vullen nog eens nagekeken. Ziet u een lek of een laag koelvloeistofniveau, dan zeggen we dat erbij.\n\nDe prijs is een vanaf-prijs voor een gewone personenauto. Een groot carter of een speciale specificatie kan afwijken. Dat hoort u vóór we beginnen.",
      "We change the oil and oil filter to the viscosity and specification your engine needs. The old filter comes off, the plug and washer are checked, and the level is checked again after filling. If we see a leak or a low coolant level, we tell you.\n\nThe price is a from-price for an ordinary passenger car. A large sump or a special specification can differ. You hear that before we start.",
      "Меняем масло и масляный фильтр с вязкостью и допуском, которые нужны вашему мотору. Старый фильтр снимаем, пробку и шайбу проверяем, уровень после заливки контролируем ещё раз. Если видим течь или низкий уровень антифриза — говорим.\n\nЦена «от» для обычного легкового авто. Большой поддон или особый допуск могут изменить сумму. Об этом скажем до начала работ.",
      "Міняємо оливу й оливний фільтр із в'язкістю і допуском, які потрібні вашому мотору. Старий фільтр знімаємо, пробку й шайбу перевіряємо, рівень після заливки контролюємо ще раз. Якщо бачимо течу або низький рівень антифризу — кажемо.\n\nЦіна «від» для звичайного легкового авто. Великий піддон або особливий допуск можуть змінити суму. Про це скажемо до початку робіт."
    ),
  }),
  svc({
    id: "onderstel",
    duration: 120,
    price: 14900,
    sort: 50,
    image: "/photos/hands.jpg",
    title: t("Onderstel", "Suspension", "Подвеска", "Підвіска"),
    summary: t(
      "Draagarmen, bussen, schokdempers, veren en speling. Eerst meten, daarna vervangen wat echt spel heeft.",
      "Arms, bushes, dampers, springs and play. Measure first, then replace what is actually loose.",
      "Рычаги, сайлентблоки, амортизаторы, пружины и люфт. Сначала замер, потом замена того, что действительно люфтит.",
      "Важелі, сайлентблоки, амортизатори, пружини й люфт. Спочатку вимір, потім заміна того, що справді люфтить."
    ),
    body: t(
      "Een klap over dwarsrichels, een auto die zoekt in de bocht of een scheve stand komt vaak uit het onderstel. Op de brug controleren we speling en hoe de rubbers en dempers eraan toe zijn. We vervangen niet een hele as omdat één bus moe is, tenzij de rest meekomt.\n\nUitlijnen na werk aan het onderstel plannen we als de geometrie is veranderd. De vanaf-prijs dekt een gerichte reparatie, niet een compleet nieuw onderstel.",
      "A knock over ridges, a car that wanders in a bend or a lean usually comes from the suspension. On the lift we check play and the condition of bushes and dampers. We do not replace a whole axle because one bush is tired, unless the rest is going with it.\n\nAlignment after suspension work is planned when the geometry has changed. The from-price covers a focused repair, not a complete new suspension.",
      "Стук на стыках, машину уводит в повороте или она стоит криво — чаще всего это подвеска. На подъёмнике проверяем люфты и состояние сайлентблоков и амортизаторов. Не меняем всю ось из-за одной уставшей втулки, если остальное ещё держит.\n\nРазвал после работ планируем, если геометрия изменилась. Цена «от» — это точечный ремонт, а не новая подвеска целиком.",
      "Стук на стиках, авто веде в повороті або воно стоїть криво — найчастіше це підвіска. На підйомнику перевіряємо люфти і стан сайлентблоків та амортизаторів. Не міняємо всю вісь через одну втомлену втулку, якщо решта ще тримає.\n\nРозвал після робіт плануємо, якщо геометрія змінилась. Ціна «від» — це точковий ремонт, а не нова підвіска цілком."
    ),
  }),
  svc({
    id: "remmen",
    duration: 90,
    price: 12900,
    sort: 60,
    image: "/photos/amg.jpg",
    title: t("Remmen", "Brakes", "Тормоза", "Гальма"),
    summary: t(
      "Schijven, blokken, remklauwen en vloeistof. Een rem die piept, trekt of te diep gaat lossen we niet met een gok.",
      "Discs, pads, calipers and fluid. A brake that squeals, pulls or sinks is not fixed by guessing.",
      "Диски, колодки, суппорты и жидкость. Тормоз, который пищит, тянет или проваливается, наугад не чиним.",
      "Диски, колодки, супорти й рідина. Гальмо, яке пищить, тягне або провалюється, навмання не ремонтуємо."
    ),
    body: t(
      "We meten schijfdikte en kijken naar de klauwen, geleidepennen en slangen. Blokken vervangen op een scheve schijf lost het piepen zelden op. Als de vloeistof oud is of het pedaal zakt, hoort ontluchten of vervangen van de vloeistof bij het werk.\n\nDe vanaf-prijs geldt voor een as met gangbare delen op een personenauto. Sportremmen, elektronische parkeerremmen en vastzittende klauwen spreken we apart af.",
      "We measure disc thickness and look at the calipers, slide pins and hoses. Pads on a warped disc rarely stop the squeal. If the fluid is old or the pedal sinks, bleeding or replacing the fluid is part of the job.\n\nThe from-price is for one axle with common parts on a passenger car. Performance brakes, an electronic parking brake and seized calipers are agreed separately.",
      "Меряем толщину дисков и смотрим суппорты, направляющие и шланги. Колодки на кривом диске редко убирают писк. Если жидкость старая или педаль проваливается, прокачка или замена жидкости входят в работу.\n\nЦена «от» — одна ось с обычными деталями на легковом авто. Спортивные тормоза, электрический ручник и закисшие суппорты согласуем отдельно.",
      "Міряємо товщину дисків і дивимось супорти, напрямні та шланги. Колодки на кривому диску рідко прибирають писк. Якщо рідина стара або педаль провалюється, прокачування чи заміна рідини входять у роботу.\n\nЦіна «від» — одна вісь зі звичайними деталями на легковому авто. Спортивні гальма, електричне ручне гальмо й закислі супорти погоджуємо окремо."
    ),
  }),
  svc({
    id: "banden",
    duration: 60,
    price: 7900,
    sort: 70,
    image: "/photos/tyres.jpg",
    title: t("Banden monteren en balanceren", "Tyre fitting and balancing", "Шиномонтаж и балансировка", "Шиномонтаж і балансування"),
    summary: t(
      "Monteren, balanceren en de spanning nalopen. Een set die staat te shaken boven de 90 lossen we bij de velg op.",
      "Fit, balance and check pressures. A shake above 90 is traced at the wheel, not ignored.",
      "Монтаж, балансировка и давление. Биение после 90 ищем на колесе, а не отмахиваемся.",
      "Монтаж, балансування й тиск. Биття після 90 шукаємо на колесі, а не відмахуємось."
    ),
    body: t(
      "We monteren banden op de velg, balanceren ze en zetten de spanning volgens de sticker in de deuropening of het instructieboekje. Bij een klacht over trillen controleren we of het gewicht houdt en of de velg niet krom is.\n\nDe vanaf-prijs is een indicatie voor montage en balanceren, niet voor de banden zelf. Neem de maat mee of een foto van de wang. Seizoenswissel in drukke weken plannen we op afspraak.",
      "We mount tyres on the rim, balance them and set the pressure from the door sticker or the handbook. If the complaint is a vibration, we check that the weights hold and that the rim is not bent.\n\nThe from-price is a guide for fitting and balancing, not for the tyres themselves. Bring the size or a photo of the sidewall. Seasonal swaps in busy weeks are by appointment.",
      "Монтируем шины на диск, балансируем и ставим давление по наклейке в проёме двери или по инструкции. Если жалоба на вибрацию, проверяем, держатся ли грузы и не погнут ли диск.\n\nЦена «от» — за монтаж и балансировку, не за сами шины. Возьмите размер или фото боковины. Сезонную переобувку в загруженные недели делаем по записи.",
      "Монтуємо шини на диск, балансуємо і ставимо тиск за наклейкою в отворі дверей або за інструкцією. Якщо скарга на вібрацію, перевіряємо, чи тримаються вантажі і чи не погнутий диск.\n\nЦіна «від» — за монтаж і балансування, не за самі шини. Візьміть розмір або фото боковини. Сезонну перевзувку в завантажені тижні робимо за записом."
    ),
  }),
  svc({
    id: "apk-voorbereiding",
    duration: 60,
    price: 4900,
    sort: 80,
    image: "/photos/workshop.jpg",
    title: t("APK-voorbereiding", "APK preparation", "Подготовка к APK", "Підготовка до APK"),
    summary: t(
      "We maken de auto keuringsklaar. De officiële APK zelf doet een RDW-erkend station, niet deze werkplaats als keuringsinstantie.",
      "We prepare the car for the test. The official APK is done at an RDW-approved station, not by this workshop acting as the test authority.",
      "Готовим машину к техосмотру. Официальный APK делает станция с допуском RDW, а не эта мастерская как пункт осмотра.",
      "Готуємо авто до техогляду. Офіційний APK робить станція з допуском RDW, а не ця майстерня як пункт огляду."
    ),
    body: t(
      "Verlichting, banden, remmen, spelingen, lekkage en de uitlezing: we lopen na wat een keuring meestal afkeurt en herstellen wat u laat doen. Zo komt u niet voor een verrassing bij het station te staan.\n\nSnelFix Auto presenteert zich niet als RDW-keuringsstation. De voorbereiding is werkplaatswerk. De afmeldbeurt plant u bij een erkend keuringsbedrijf, of we wijzen u de weg als u dat vraagt.",
      "Lights, tyres, brakes, play, leaks and a scan: we go through what a test usually rejects and repair what you approve. That way the station is not a surprise.\n\nSnelFix Auto does not present itself as an RDW test station. Preparation is workshop work. You book the official test at an approved centre, or we point you there if you ask.",
      "Свет, шины, тормоза, люфты, течи и считывание: проходим то, из-за чего осмотр обычно не проходит, и чиним то, что вы одобрите. Так на станции не будет сюрприза.\n\nSnelFix Auto не выдаёт себя за пункт RDW. Подготовка — это работа мастерской. Официальный осмотр вы записываете на допущенной станции, или мы подскажем, если спросите.",
      "Світло, шини, гальма, люфти, течі й зчитування: проходимо те, через що огляд зазвичай не проходять, і ремонтуємо те, що ви погодите. Так на станції не буде несподіванки.\n\nSnelFix Auto не видає себе за пункт RDW. Підготовка — це робота майстерні. Офіційний огляд ви записуєте на допущеній станції, або ми підкажемо, якщо запитаєте."
    ),
  }),
  svc({
    id: "auto-elektra",
    duration: 90,
    price: null,
    sort: 90,
    image: "/photos/cabin.jpg",
    title: t("Auto-elektra en elektronica", "Auto electrics and electronics", "Автоэлектрика и электроника", "Автоелектрика й електроніка"),
    summary: t(
      "Startproblemen, laadcircuit, verlichting, modules en bedrading. Meten vóór er een computer wordt vervangen.",
      "Starting, charging, lighting, modules and wiring. Measure before a computer is replaced.",
      "Запуск, зарядка, свет, блоки и проводка. Сначала замер, потом мысль о замене блока.",
      "Запуск, зарядка, світло, блоки й проводка. Спочатку вимір, потім думка про заміну блока."
    ),
    body: t(
      "Een lege accu is niet altijd de accu. We meten laadspanning, massa's en of een module echt stuk is of alleen geen voeding krijgt. Ramen, sloten, verlichting en fouten die terugkomen na wissen horen hierbij.\n\nElektronicaschade door water of een aftakas-accessoire dat ergens tussen is gezet, bekijken we eerst. De reparatie spreken we af nadat de meting er ligt.",
      "A flat battery is not always the battery. We measure charge voltage, earths and whether a module is actually dead or simply has no supply. Windows, locks, lights and faults that return after a clear belong here.\n\nWater damage, or an accessory spliced into the loom, is looked at first. The repair is agreed once the measurement is on the table.",
      "Села батарея — не всегда батарея. Меряем заряд, массы и жив ли блок или ему просто нет питания. Стеклоподъёмники, замки, свет и ошибки, которые возвращаются после стирания, тоже сюда.\n\nВоду и врезанные аксессуары смотрим в первую очередь. Ремонт согласуем, когда измерение уже есть.",
      "Сіла батарея — не завжди батарея. Міряємо заряд, маси і чи живий блок, чи йому просто немає живлення. Склопідйомники, замки, світло й помилки, які повертаються після стирання, теж сюди.\n\nВоду й врізані аксесуари дивимось насамперед. Ремонт погоджуємо, коли вимір уже є."
    ),
  }),
  svc({
    id: "accessoires",
    duration: 60,
    price: null,
    sort: 100,
    image: "/photos/cabin.jpg",
    title: t("Accessoires monteren en herstellen", "Accessory fitting and repair", "Установка и ремонт аксессуаров", "Встановлення і ремонт аксесуарів"),
    summary: t(
      "Trekhaakstekker, dashcam, sensoren en andere extra's, netjes in de bestaande bedrading.",
      "Tow electrics, a dashcam, sensors and other extras, finished into the existing loom.",
      "Электрика фаркопа, регистратор, датчики и другие допы — аккуратно в штатную проводку.",
      "Електрика фаркопа, реєстратор, датчики й інші допи — акуратно в штатну проводку."
    ),
    body: t(
      "Een accessoire dat piept, leegtrekt of een fout zet, halen we uit elkaar tot de oorzaak duidelijk is. Nieuwe montage doen we zo dat de kabel niet over een scherpe rand loopt en de zekering klopt.\n\nNeem het onderdeel mee als u het al heeft, of stuur een foto mee met de afspraak. We zeggen vooraf of het bij deze auto past.",
      "An accessory that beeps, drains the battery or sets a fault is taken apart until the cause is clear. New fitting is done so the cable does not cross a sharp edge and the fuse is the right one.\n\nBring the part if you already have it, or attach a photo to the booking. We say beforehand whether it suits this car.",
      "Аксессуар, который пищит, сажает аккумулятор или ставит ошибку, разбираем, пока причина не ясна. Новый монтаж делаем так, чтобы провод не тёрся о кромку и предохранитель был верным.\n\nЕсли деталь уже есть — привезите её или приложите фото к записи. Заранее скажем, подходит ли это этой машине.",
      "Аксесуар, який пищить, садить акумулятор або ставить помилку, розбираємо, поки причина не зрозуміла. Новий монтаж робимо так, щоб провід не терся об край і запобіжник був правильним.\n\nЯкщо деталь уже є — привезіть її або додайте фото до запису. Заздалегідь скажемо, чи підходить це цьому авто."
    ),
  }),
  svc({
    id: "spoedreparatie",
    duration: 60,
    price: null,
    sort: 110,
    image: "/photos/night.jpg",
    title: t("Spoedreparatie op afspraak", "Urgent repair by arrangement", "Срочный ремонт по договорённости", "Терміновий ремонт за домовленістю"),
    summary: t(
      "Staat de auto niet veilig of moet u vandaag nog weg, dan zoeken we een gaatje. Buiten openingstijd bellen of appen.",
      "If the car is not safe or you have to move today, we look for a gap. Outside opening hours, call or message.",
      "Если ехать небезопасно или выехать нужно сегодня, ищем окно. Вне часов работы — звоните или пишите.",
      "Якщо їхати небезпечно або виїхати треба сьогодні, шукаємо вікно. Поза годинами роботи — телефонуйте або пишіть."
    ),
    body: t(
      "Spoed in de werkplaats loopt via de agenda van de gekozen garage, binnen de openingstijden. Is er die dag geen vrij blok, dan bellen we terug met het eerstvolgende moment of een andere vestiging.\n\n's Nachts, in het weekend of op een feestdag is de sleep- en transportdienst bereikbaar. Een reparatie buiten de brug om spreken we apart af. Zet in het formulier wat er mis is en of de auto nog rijdt.",
      "Urgent workshop work uses the diary of the garage you choose, inside opening hours. If that day has no free block, we call back with the next slot or the other branch.\n\nAt night, on weekends and on public holidays the recovery and transport service is reachable. A repair outside the lift is agreed separately. Write what is wrong and whether the car still drives.",
      "Срочная работа в цехе идёт по записи выбранной мастерской, в часы работы. Если в этот день нет свободного окна, перезвоним со следующим временем или второй площадкой.\n\nНочью, в выходные и праздники доступна эвакуация и перевозка. Ремонт вне подъёмника согласуем отдельно. Напишите, что случилось и едет ли машина.",
      "Термінова робота в цеху йде за записом обраної майстерні, в години роботи. Якщо цього дня немає вільного вікна, передзвонимо з наступним часом або другою точкою.\n\nУночі, у вихідні й свята доступна евакуація і перевезення. Ремонт поза підйомником погоджуємо окремо. Напишіть, що сталося і чи їде авто."
    ),
  }),
  svc({
    id: "personen-bedrijf",
    duration: 60,
    price: null,
    sort: 120,
    image: "/photos/workshop.jpg",
    title: t("Personenauto's en lichte bedrijfsauto's", "Passenger cars and light commercial vehicles", "Легковые и лёгкие коммерческие", "Легкові й легкі комерційні"),
    summary: t(
      "We werken aan personenauto's en lichte bedrijfswagens. Zware trucks en landbouwvoertuigen nemen we niet aan.",
      "We work on passenger cars and light commercial vehicles. Heavy trucks and farm vehicles are outside the shop.",
      "Работаем с легковыми и лёгкими коммерческими. Тяжёлые грузовики и сельхозтехнику не берём.",
      "Працюємо з легковими й легкими комерційними. Важкі вантажівки й сільгосптехніку не беремо."
    ),
    body: t(
      "Beide garages zijn ingericht voor personenauto's en lichte bedrijfsauto's: bestelwagens die op een normale brug passen. Twijfelt u over de hoogte of het gewicht, vermeld merk, model en of het een gesloten bestelbus is.\n\nDeze pagina is de algemene intake. Kies bij het boeken gerust een specifiekere dienst als u die al weet. We koppelen de auto aan uw telefoonnummer, zodat een volgend bezoek niet opnieuw alle gegevens vraagt.",
      "Both garages are set up for passenger cars and light commercials: vans that fit a normal lift. If you are unsure about height or weight, state the make, model and whether it is a closed van.\n\nThis page is the general intake. When booking, pick a more specific service if you already know it. We attach the vehicle to your phone number so the next visit does not ask for everything again.",
      "Обе мастерские рассчитаны на легковые и лёгкие коммерческие: фургоны, которые встают на обычный подъёмник. Если сомневаетесь в высоте или массе, укажите марку, модель и закрытый ли это фургон.\n\nЭто общая запись. Если услуга уже ясна, выберите её точнее. Авто привязываем к номеру телефона, чтобы в следующий раз не спрашивать всё заново.",
      "Обидві майстерні розраховані на легкові й легкі комерційні: фургони, які стають на звичайний підйомник. Якщо сумніваєтесь у висоті чи масі, вкажіть марку, модель і чи це закритий фургон.\n\nЦе загальний запис. Якщо послуга вже зрозуміла, оберіть її точніше. Авто прив'язуємо до номера телефону, щоб наступного разу не питати все спочатку."
    ),
  }),
  svc({
    id: "transport",
    duration: 60,
    price: null,
    sort: 130,
    bookable: 0,
    kind: "tow",
    image: "/photos/tow.jpg",
    title: t("Berging en transport op afspraak, 24/7", "Recovery and transport by arrangement, 24/7", "Эвакуация и перевозка по договорённости, 24/7", "Евакуація і перевезення за домовленістю, 24/7"),
    summary: t(
      "Nederland en de rest van Europa, ook 's nachts, in het weekend en op feestdagen. De route openen we, de prijs volgt.",
      "The Netherlands and the rest of Europe, including nights, weekends and public holidays. Open the route; the price follows.",
      "Нидерланды и вся Европа, включая ночь, выходные и праздники. Маршрут открываем, цена следом.",
      "Нідерланди і вся Європа, включно з ніччю, вихідними й святами. Маршрут відкриваємо, ціна слідом."
    ),
    body: t(
      "Een auto die niet rijdt, een aankoop die opgehaald moet worden of een rit naar een andere werkplaats: we plannen berging en transport door Nederland en Europa. Dat staat los van de brugagenda. U geeft ophaaladres, afleveradres, merk en model, of de auto rijdt, en of het spoed is.\n\nOp het scherm tonen we beide adressen en een route via kaarten, zonder een betaalde kilometer-API. De afstand is daarmee te bekijken. De prijs bevestigen we daarna. We factureren niet automatisch een live tarief.",
      "A car that will not drive, a purchase that has to be collected, or a run to another workshop: we arrange recovery and transport across the Netherlands and Europe. It is separate from the lift diary. You give pickup, delivery, make and model, whether it runs, and whether it is urgent.\n\nThe screen shows both addresses and a map route, without a paid distance API. You can look at the distance. We confirm the price after that. We do not bill a live tariff automatically.",
      "Машина не едет, покупку нужно забрать или отвезти в другую мастерскую: организуем эвакуацию и перевозку по Нидерландам и Европе. Это отдельно от записи на подъёмник. Нужны адреса, марка и модель, едет ли авто и срочно ли.\n\nНа экране оба адреса и маршрут на карте, без платного API расстояния. Дистанцию можно посмотреть. Цену подтверждаем следом. Живой тариф сами не выставляем.",
      "Авто не їде, покупку треба забрати або відвезти в іншу майстерню: організуємо евакуацію і перевезення Нідерландами й Європою. Це окремо від запису на підйомник. Потрібні адреси, марка і модель, чи їде авто і чи терміново.\n\nНа екрані обидві адреси і маршрут на карті, без платного API відстані. Дистанцію можна подивитись. Ціну підтверджуємо слідом. Живий тариф самі не виставляємо."
    ),
  }),
];

export const POSTS = [
  {
    kind: "photo",
    image: "/photos/workshop.jpg",
    sort: 10,
    title: t("Op de brug", "On the lift", "На подъёмнике", "На підйомнику"),
    body: t("Werkplaats, niet een showroom.", "A workshop, not a showroom.", "Мастерская, не шоурум.", "Майстерня, не шоурум."),
  },
  {
    kind: "photo",
    image: "/photos/tools.jpg",
    sort: 20,
    title: t("Gereedschap bij de hand", "Tools within reach", "Инструмент под рукой", "Інструмент під рукою"),
    body: t("De wand waar het werk begint.", "The wall where the job starts.", "Стенка, с которой начинается работа.", "Стінка, з якої починається робота."),
  },
  {
    kind: "photo",
    image: "/photos/oil.jpg",
    sort: 30,
    title: t("Olie verversen", "Oil service", "Замена масла", "Заміна оливи"),
    body: t("Specificatie eerst, dan pas de kan.", "Specification first, then the can.", "Сначала допуск, потом канистра.", "Спочатку допуск, потім каністра."),
  },
  {
    kind: "photo",
    image: "/photos/night.jpg",
    sort: 40,
    title: t("Na sluitingstijd", "After hours", "После закрытия", "Після закриття"),
    body: t("De brug slaapt. De sleepdienst niet.", "The lift sleeps. Recovery does not.", "Подъёмник спит. Эвакуатор — нет.", "Підйомник спить. Евакуатор — ні."),
  },
  {
    kind: "news",
    image: "/photos/tow.jpg",
    sort: 50,
    title: t(
      "Transport door Nederland en Europa",
      "Transport across the Netherlands and Europe",
      "Перевозка по Нидерландам и Европе",
      "Перевезення Нідерландами й Європою"
    ),
    body: t(
      "Berging en transport plannen we op afspraak, ook 's nachts, in het weekend en op feestdagen. De route opent u zelf op de kaart. De prijs bevestigen we daarna, zonder een automatisch kilometertarief.",
      "Recovery and transport are arranged in advance, including nights, weekends and public holidays. You open the route on the map yourself. We confirm the price afterwards, with no automatic per-kilometre tariff.",
      "Эвакуацию и перевозку планируем по договорённости, включая ночь, выходные и праздники. Маршрут вы открываете на карте сами. Цену подтверждаем следом, без автоматического тарифа за километр.",
      "Евакуацію і перевезення плануємо за домовленістю, включно з ніччю, вихідними й святами. Маршрут ви відкриваєте на карті самі. Ціну підтверджуємо слідом, без автоматичного тарифу за кілометр."
    ),
  },
];
