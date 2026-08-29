# -*- coding: utf-8 -*-
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def esc(value: str) -> str:
    return value.replace('\\', '\\\\').replace("'", "\\'")


def dart_l(uk: str, en: str, ru: str, indent: str = '      ') -> str:
    return (
        f"L(\n{indent}'{esc(uk)}',\n{indent}'{esc(en)}',\n{indent}'{esc(ru)}',\n"
        f"{indent[:-2]})"
    )


CORE_TIPS = {
    "diag-comp": (
        "Знімаємо логи на холодну і на гарячу: так видно плаваючі збої. Коди не стираємо, поки не підтверджена причина.",
        "We scan cold and hot so intermittent faults show. Codes stay until the cause is confirmed.",
        "Снимаем логи на холодную и на горячую: так видны плавающие сбои. Коды не стираем, пока не подтверждена причина.",
    ),
    "diag-chassis": (
        "На підйомнику перевіряємо люфти і пильовики. Клієнт бачить люфт сам — без «на слух з ями».",
        "On the lift we check joint play and torn boots. You see the play yourself — not “by ear from the pit”.",
        "На подъёмнике проверяем люфты и пыльники. Клиент видит люфт сам — без «на слух из ямы».",
    ),
    "pads": (
        "Разом із колодками міряємо товщину дисків. Борозни або край мінімуму — проточка чи заміна в цей же заїзд.",
        "We measure disc thickness with the pads. Grooves or a min-thickness edge means machining or replacement in the same visit.",
        "Вместе с колодками меряем толщину дисков. Борозды или край минимума — проточка или замена в этот же заезд.",
    ),
    "discs": (
        "Диски міняємо комплектом на вісь. Різна товщина ліворуч/праворуч веде авто при гальмуванні.",
        "Discs go on as an axle set. Uneven thickness left-to-right makes the car pull under braking.",
        "Диски меняем комплектом на ось. Разная толщина слева/справа ведёт авто при торможении.",
    ),
    "align": (
        "Спочатку тяги і сайлентблоки, потім стенд. Гнутий важіль зʼїдає нову гуму за тиждень.",
        "Arms and bushes first, then the alignment rack. A bent arm will wear new tyres in a week.",
        "Сначала тяги и сайлентблоки, потом стенд. Гнутый рычаг съедает новую резину за неделю.",
    ),
    "battery": (
        "Після відʼєднання АКБ багато авто просять адаптацію вікон і дроселя. Попереджаємо до зняття клеми.",
        "After a battery disconnect many cars need window and throttle adaptations. We warn you before the terminal comes off.",
        "После отключения АКБ многие авто просят адаптацию окон и дросселя. Предупреждаем до снятия клеммы.",
    ),
    "coding": (
        "Перед записом міряємо напругу мережі і зарядку. Слабкий генератор обриває прошивку ЕБУ на середині запису.",
        "Before a write we measure system voltage and charging. A weak alternator bricks the ECU mid-flash.",
        "Перед записью меряем напряжение сети и зарядку. Слабый генератор обрывает прошивку ЭБУ на середине записи.",
    ),
    "oil": (
        "Допуск оливи беремо по VIN, не «як у сусіда». Зливний болт із шайбою міняємо, якщо так у мануалі.",
        "Oil spec comes from the VIN, not a neighbour’s grade. Crush-washer drain bolts are replaced when the book says so.",
        "Допуск масла берём по VIN, не «как у соседа». Сливной болт с шайбой меняем, если так в мануале.",
    ),
    "coolant": (
        "G11, G12 і G13 не змішуємо. Промивання — якщо в бачку емульсія або іржа.",
        "G11, G12 and G13 are never mixed. We flush if the tank shows emulsion or rust.",
        "G11, G12 и G13 не смешиваем. Промывка — если в бачке эмульсия или ржавчина.",
    ),
    "timing": (
        "Разом із ГРМ міняємо помпу і ролики. Економія на помпі означає друге розкриття мотора.",
        "Water pump and rollers go on with the timing kit. Skipping the pump means opening the engine twice.",
        "Вместе с ГРМ меняем помпу и ролики. Экономия на помпе — повторное вскрытие мотора.",
    ),
    "plugs": (
        "Момент затяжки — тільки по мануалу. На алюмінієвій ГБЦ «від руки» зриває різьбу.",
        "Torque to the workshop spec. On an aluminium head, “hand tight” strips the thread.",
        "Момент затяжки — только по мануалу. На алюминиевой ГБЦ «от руки» срывает резьбу.",
    ),
    "insurance": (
        "Франшиза, виключення і правила «тотальної» важливіші за низьку премію в рекламі. Рахуємо по VIN і пробігу.",
        "Deductible, exclusions and write-off rules matter more than a cheap advertised premium. We quote by VIN and mileage.",
        "Франшиза, исключения и правила «тотальной» важнее низкой премии в рекламе. Считаем по VIN и пробегу.",
    ),
    "paint": (
        "Локальний ремонт — якщо скол до ґрунту малий. Велика площа — фарбуємо елемент у камері, щоб не було плями.",
        "Spot repair if the chip to primer is small. A large area is a full panel in booth so it does not halo.",
        "Локальный ремонт — если скол до грунта малый. Большая площадь — красим элемент в камере, чтобы не было пятна.",
    ),
    "wash": (
        "Без двох фаз пісок на лаку шліфує покриття. Контакт — лише після безконтактного змиву бруду.",
        "Without two stages, grit on clear coat is sandpaper. Contact wash only after a pre-rinse of the dirt.",
        "Без двух фаз песок на лаке шлифует покрытие. Контакт — только после бесконтактного смыва грязи.",
    ),
    "tires": (
        "Прокол латаємо зсередини камери. Джгут — щоб доїхати, не на сезон.",
        "Punctures are patched from inside the carcass. A plug is only to get you home, not for a season.",
        "Прокол латаем изнутри. Жгут — чтобы доехать, не на сезон.",
    ),
    "tuning": (
        "Stage 2 ставимо лише з даунпайпом і паливом 98. Інакше страждає турбіна і кат.",
        "Stage 2 only with a downpipe and 98 octane. Otherwise the turbo and cat pay for it.",
        "Stage 2 ставим только с даунпайпом и топливом 98. Иначе страдает турбина и кат.",
    ),
    "stage3": (
        "Спочатку дефектування блоку і заміри, потім замовлення кованого комплекту. Не навпаки.",
        "Block survey and measurements first, then the forged kit is ordered. Not the other way round.",
        "Сначала дефектовка блока и замеры, потом заказ кованого комплекта. Не наоборот.",
    ),
    "exhaust": (
        "Після даунпайпа потрібна прошивка. Без неї чек і бідна суміш — питання пробігу.",
        "A downpipe needs a remap. Skip it and a check light plus a lean mix is a matter of miles.",
        "После даунпайпа нужна прошивка. Без неё чек и бедная смесь — вопрос пробега.",
    ),
    "hydro": (
        "Деталь має бути сухою і без пилу. Пил у ванні друкується крапками на плівці.",
        "The part must be dry and dust-free. Dust in the tank prints as dots on the film.",
        "Деталь должна быть сухой и без пыли. Пыль в ванне печатается точками на пленке.",
    ),
    "carbon": (
        "Уточнюємо до замовлення: real carbon чи плівка. Ціна, вага і догляд різні.",
        "We confirm before the order: real carbon or film. Price, weight and care are not the same.",
        "Уточняем до заказа: real carbon или пленка. Цена, вес и уход разные.",
    ),
    "wrap": (
        "Плівка не лягає на бітум і пісок. Спочатку мийка, глина і знежирення.",
        "Wrap will not stick to tar and grit. Wash, clay and degrease first.",
        "Пленка не ложится на битум и песок. Сначала мойка, глина и обезжиривание.",
    ),
    "glass": (
        "Після лобового з камерою обовʼязкове калібрування ADAS. Інакше асистенти брешуть.",
        "A camera windshield needs ADAS calibration. Skip it and the assists lie.",
        "После лобового с камерой обязательна калибровка ADAS. Иначе ассистенты врут.",
    ),
    "interior": (
        "Беремо шкіру, яка тримає зиму. Краще менша площа якісного матеріалу, ніж дешева шкура на весь салон.",
        "We use hide that survives winter. Less area of good leather beats cheap hide on the whole cabin.",
        "Берём кожу, которая держит зиму. Лучше меньшая площадь качественного материала, чем дешёвая шкура на весь салон.",
    ),
    "ac": (
        "Спочатку вакуум і пошук витоку. Заправка без цього — холодагент у повітря.",
        "Vacuum and a leak hunt first. A refill without that is refrigerant into the air.",
        "Сначала вакуум и поиск утечки. Заправка без этого — хладагент в воздух.",
    ),
    "tow": (
        "Скажіть, чи крутяться колеса і який привід. Повний привід і АКПП веземо лише на платформі.",
        "Tell us if the wheels roll and which drivetrain. AWD and automatics travel on a flatbed only.",
        "Скажите, крутятся ли колёса и какой привод. Полный привод и АКПП везём только на платформе.",
    ),
    "engine-repair": (
        "Кошторис після розбору і дефектування, не «на око з парковки». Фото вузлів — до збірки.",
        "The quote comes after teardown and survey, not by ear from the yard. Photos of parts before assembly.",
        "Смета после разбора и дефектовки, не «на глаз с парковки». Фото узлов — до сборки.",
    ),
}

EXTRA_TIPS = {
    "body-dent": (
        "Рихтовка йде після заміру зазорів. Фарбуємо вже виведену площину, не «по шпаклівці на око».",
        "Panel beating follows a gap check. We paint a true surface, not filler guessed by eye.",
        "Рихтовка идёт после замера зазоров. Красим уже выведенную плоскость.",
    ),
    "body-pdr": (
        "PDR працює, якщо лак не тріснув. Тріщина емалі — це вже малярка, не гачки.",
        "PDR only if the clear coat is intact. Cracked paint is a respray, not hooks.",
        "PDR работает, если лак не треснул. Трещина эмали — уже малярка.",
    ),
    "body-weld": (
        "Гниль вирізаємо до живого металу, латка з проваром і антикор шва. На холодну сітку не ставимо.",
        "Rust is cut to sound metal, the patch is fully welded and the seam undersealed. No cold mesh.",
        "Гниль вырезаем до живого металла, латка с проваром и антикор шва.",
    ),
    "body-geometry": (
        "На стапелі спочатку контрольні точки з карти заводу, потім витяжка. Без карти «на око» лонжерон не ставимо.",
        "On the jig we pull to the factory control points. We do not guess a rail by eye.",
        "На стапеле сначала контрольные точки с карты завода, потом вытяжка.",
    ),
    "body-bumper": (
        "Пластик паяємо з армуванням шва. Відірвану скобу відновлюємо під штатне кріплення, не на стяжки.",
        "Bumper plastic is welded with a reinforced seam. Torn brackets go back to factory mounts, not cable ties.",
        "Пластик паяем с армированием шва. Скобу восстанавливаем под штатное крепление.",
    ),
    "paint-panel": (
        "Елемент фарбуємо в камері з підбором по VIN і спектрофотометру. Стик поліруємо, щоб не було плями.",
        "The panel is painted in booth, colour-matched by VIN and spectrophotometer. The blend is polished so it does not halo.",
        "Элемент красим в камере с подбором по VIN и спектрофотометру. Стык полируем.",
    ),
    "paint-spot": (
        "Скол до ґрунту закриваємо локально, якщо діаметр малий. Інакше пляма вилізе на сонці.",
        "A chip to primer is spotted if the diameter is small. Otherwise it will halo in sunlight.",
        "Скол до грунта закрываем локально, если диаметр малый. Иначе пятно вылезет на солнце.",
    ),
    "paint-polish": (
        "Після малярки знімаємо шагрень і пил лаку. Без цього елемент матовий поруч із заводським.",
        "After paint we cut orange peel and dust nibs. Skip it and the panel looks dull next to factory paint.",
        "После малярки снимаем шагрень и пыль лака. Без этого элемент матовый рядом с заводским.",
    ),
    "anticor": (
        "Іржу зачищаємо до покриття. Мастика по іржі лише консервує її на роки.",
        "Rust is dressed before coating. Mastic over rust just seals it in for years.",
        "Ржавчину зачищаем до покрытия. Мастика по ржавчине только консервирует её.",
    ),
    "detail-chem": (
        "Екстракція і повна сушка. Салон не віддаємо вологим — інакше запах повернеться за добу.",
        "Extraction and a full dry-out. We do not hand back a damp cabin or the smell returns in a day.",
        "Экстракция и полная сушка. Салон не отдаём влажным — иначе запах вернётся за сутки.",
    ),
    "detail-polish": (
        "Кілька ступенів абразиву під риску. Кераміка — лише на виведену поверхню.",
        "Several cut stages matched to the holograms. Ceramic only goes on a finished surface.",
        "Несколько ступеней абразива под риску. Керамика — только на выведенную поверхность.",
    ),
    "detail-ceramic": (
        "Шар кладемо на знежирений лак. Перші дні — без мийки і дощу, якщо можна поставити в бокс.",
        "The coat goes on degreased clear. The first days: no wash, and under cover if rain is coming.",
        "Слой кладём на обезжиренный лак. Первые дни — без мойки и дождя, если можно поставить в бокс.",
    ),
    "detail-engine": (
        "Клеми знімаємо, розʼєми і генератор закриваємо. Струмінь не бʼємо в блок керування.",
        "Terminals off, connectors and the alternator masked. We do not blast the ECU with a lance.",
        "Клеммы снимаем, разъёмы и генератор закрываем. Струю не бьём в блок управления.",
    ),
    "ppf": (
        "Плівка на капот і бампер тримає сколи траси. Після удару це не заміна малярки.",
        "Film on the hood and bumper stops motorway chips. After a hit it is not a substitute for paint.",
        "Пленка на капот и бампер держит сколы трассы. После удара это не замена малярке.",
    ),
    "hydro-wheel": (
        "Диски знімаємо, миємо, ґрунт, друк, лак. Баланс після збірки — обовʼязково.",
        "Wheels come off, washed, primed, dipped, cleared. Rebalance after assembly is mandatory.",
        "Диски снимаем, моем, грунт, печать, лак. Баланс после сборки обязателен.",
    ),
    "hydro-trim": (
        "Панелі салону знімаємо. Друкуємо на столі, не «плівкою по місцю» на торпедо.",
        "Cabin trims come out. We dip on the bench, not film-in-place on the dash.",
        "Панели салона снимаем. Печатаем на столе, не «пленкой по месту» на торпедо.",
    ),
    "hydro-cover": (
        "Кришки двигуна і пластик — знежирення і ґрунт, інакше плівка злізе після мийки мотора.",
        "Engine covers and plastic: degrease and primer, or the film peels after the next bay wash.",
        "Крышки двигателя и пластик — обезжиривание и грунт, иначе пленка слезет после мойки мотора.",
    ),
    "wrap-partial": (
        "Капот, дах і дзеркала — зони зі сколами. Краї заводимо в зазори, не ріжемо по ребру лаку.",
        "Hood, roof and mirrors take the stone chips. Edges tuck into gaps, not cut on the clear-coat edge.",
        "Капот, крыша и зеркала — зоны сколов. Края заводим в зазоры, не режем по ребру лака.",
    ),
    "wrap-roof": (
        "Дах гріємо і тягнемо від центру. Люк і рейлінги обходимо, не клеїмо насипом.",
        "The roof is heated and stretched from the centre. Sunroof and rails are wrapped around, not buried.",
        "Крышу греем и тянем от центра. Люк и рейлинги обходим, не клеим насыпью.",
    ),
    "carbon-hood": (
        "Капот і спойлер: кріплення і петлі підганяємо, щоб зазори лишились заводськими.",
        "Hood and spoiler: hinges and catches are refitted so the gaps stay factory.",
        "Капот и спойлер: крепления и петли подгоняем, чтобы зазоры остались заводскими.",
    ),
    "tire-repair": (
        "Латка зсередини по розмітці пошкодження. Якщо нитка корду порвана — шина в заміну, не в ремонт.",
        "An inside patch mapped to the injury. If the cord is cut, the tyre is replaced, not repaired.",
        "Заплата изнутри по разметке повреждения. Если нить корда порвана — шина в замену.",
    ),
    "tire-storage": (
        "Комплект на стелажі, тиск і маркування осі. Не складаємо стопкою «в кутку двору».",
        "The set sits on a rack, pressure set, axle marked. Not stacked in a yard corner.",
        "Комплект на стеллаже, давление и маркировка оси. Не складываем стопкой во дворе.",
    ),
    "rim-straighten": (
        "Правка на стенді з контролем биття. Тріщину литва варимо аргоном, не «холодним зварюванням».",
        "Straightened on a rack with run-out check. Cast cracks are TIG-welded, not cold-filled.",
        "Правка на стенде с контролем биения. Трещину литья варим аргоном.",
    ),
    "rim-paint": (
        "Порошок після піскоструменя і ґрунту. Лаком «з балона» диск не фарбуємо — злізе на мийці.",
        "Powder after blast and primer. We do not rattle-can a wheel — it peels at the next wash.",
        "Порошок после пескоструя и грунта. Лаком из баллона диск не красим.",
    ),
    "brake-lathe": (
        "Проточка лише якщо залишається запас по товщині. Інакше диск у заміну — інакше він поведеться від нагріву.",
        "Machining only with enough thickness left. Otherwise the disc is replaced or it will warp on heat.",
        "Проточка только если остаётся запас по толщине. Иначе диск в замену.",
    ),
    "steering": (
        "Рейку не «підтягуємо» по живій втулці. Після ремонту — розвал, інакше руль стоїть криво.",
        "We do not nip up a worn rack bush. Alignment after the job or the wheel sits off-centre.",
        "Рейку не «подтягиваем» по живой втулке. После ремонта — развал.",
    ),
    "cv-joint": (
        "Пильовик міняємо, поки мастило чисте. Пісок у шарнірі — вже граната, не хомут.",
        "The boot is replaced while the grease is still clean. Grit in the joint means a new CV, not a clamp.",
        "Пыльник меняем, пока смазка чистая. Песок в шарнире — уже граната, не хомут.",
    ),
    "air-suspension": (
        "Спочатку компресор і осушувач, потім подушка. Тече подушка при живому компресорі вбʼє новий агрегат.",
        "Compressor and dryer first, then the bag. A leaking bag with a live compressor will kill the new unit.",
        "Сначала компрессор и осушитель, потом подушка. Течь подушки при живом компрессоре убьёт новый агрегат.",
    ),
    "cabin-filter": (
        "Ставимо вугільний, якщо в мануалі так для клімату міста. Паперовий у пробках швидко забивається.",
        "A carbon filter if the book specs it for city air. Paper clogs fast in traffic.",
        "Ставим угольный, если так в мануале для городского климата. Бумажный в пробках быстро забивается.",
    ),
    "wiring": (
        "CAN не скручуємо «скруткою». Пайка, термоусадка, екранування, якщо так у джгуті.",
        "CAN is not twisted with a dry joint. Solder, heat-shrink, and screen if the loom has it.",
        "CAN не скручиваем скруткой. Пайка, термоусадка, экранирование, если так в жгуте.",
    ),
    "turbo": (
        "Оливу в інтеркулері шукаємо і в картері: вентиляція і кільця. Нова турбіна на забитій вентиляції знову потече.",
        "Oil in the intercooler often starts in the crankcase: breathers and rings. A new turbo on a blocked breather will leak again.",
        "Масло в интеркулере ищем и в картере: вентиляция и кольца. Новая турбина на забитой вентиляции снова потечёт.",
    ),
    "injectors": (
        "Дизельні форсунки — на стенд, не присадка в бак. Бензинові — промивка з контролем факела.",
        "Diesel injectors go on the bench, not an additive in the tank. Petrol: a clean with spray pattern check.",
        "Дизельные форсунки — на стенд, не присадка в бак. Бензиновые — промывка с контролем факела.",
    ),
    "radiator": (
        "Систему тиснемо до розбору. Антифриз — той самий тип, промивання при емульсії.",
        "We pressure-test before teardown. Coolant stays the same spec; we flush if there is emulsion.",
        "Систему давим до разбора. Антифриз — тот же тип, промывка при эмульсии.",
    ),
    "clutch": (
        "Двомасовий міряємо люфт. Якщо він їсть — кошик і диск самі не врятують.",
        "Dual-mass flywheel play is measured. If it is gone, a cover and disc alone will not save it.",
        "Двухмассовый меряем люфт. Если он съеден — корзина и диск сами не спасут.",
    ),
    "gearbox": (
        "Олива АКПП/DSG — допуск виробника і рівень на гарячу. «Універсал з ринку» вбиває мехатронік.",
        "AT/DSG fluid is OEM spec, level checked hot. A market “universal” oil kills the mechatronic.",
        "Масло АКПП/DSG — допуск завода и уровень на горячую. «Универсал с рынка» убивает мехатроник.",
    ),
    "gearbox-flush": (
        "Піддон знімаємо, фільтр і магніти чистимо. Апаратна «заміна без зняття» залишає стружку в гідроблоці.",
        "The pan comes off; filter and magnets are cleaned. A machine flush with the pan on leaves swarf in the valve body.",
        "Поддон снимаем, фильтр и магниты чистим. Аппаратная замена без снятия оставляет стружку в гидроблоке.",
    ),
    "dpf": (
        "Регенерація і промивка — якщо сажовий ще живий. Вимкнення систем під норми не робимо.",
        "Regen and clean if the DPF is still serviceable. We do not delete emissions equipment.",
        "Регенерация и промывка — если сажевый ещё живой. Отключение систем под нормы не делаем.",
    ),
    "starter-alt": (
        "Спочатку струм старту і напруга зарядки під навантаженням. Знімати «на всяк випадок» не будемо.",
        "Cranking current and loaded charging voltage first. We do not pull units “just in case”.",
        "Сначала ток старта и напряжение зарядки под нагрузкой. Снимать «на всякий случай» не будем.",
    ),
    "alarm": (
        "Обхідчик і CAN-модуль ставимо під штатний іммобілайзер. Інакше авто не заведеться після постановки.",
        "Bypass and CAN module are fitted around the factory immobiliser. Otherwise the car will not start after arming.",
        "Обходчик и CAN-модуль ставим под штатный иммобилайзер. Иначе авто не заведётся после постановки.",
    ),
    "keys": (
        "Прописка ключа — в іммобілайзер і блок комфорту, не «обнулити все». Інакше зникнуть штатні ключі.",
        "The key is paired to the immobiliser and comfort module, not a full wipe. A wipe drops the factory keys.",
        "Прописка ключа — в иммо и блок комфорта, не «обнулить всё». Иначе пропадут штатные ключи.",
    ),
    "lights-led": (
        "Лінзи з правильним світлорозподілом, не «яскраві лампи в відбивач». Після заміни — привʼязка і корекція.",
        "Projectors with a legal beam, not bright bulbs in a reflector. Pairing and aim after the swap.",
        "Линзы с правильным светораспределением, не «яркие лампы в отражатель». После замены — привязка и коррекция.",
    ),
    "lights-restore": (
        "Після полірування — лак або бронеплівка на скло. Без цього фара пожовтіє за сезон.",
        "After polish: lacquer or PPF on the lens. Skip it and the lamp yellows in a season.",
        "После полировки — лак или бронепленка на стекло. Без этого фара пожелтеет за сезон.",
    ),
    "sound-system": (
        "Переріз силового кабелю рахуємо по струму підсилювача. Тонкий дріт гріється і садить АКБ.",
        "Power cable cross-section is sized to amp current. Thin wire heats and flattens the battery.",
        "Сечение силового кабеля считаем по току усилителя. Тонкий провод греется и сажает АКБ.",
    ),
    "soundproof": (
        "Кілька шарів з прокаткою, не один лист у двері. Інакше ефекту майже немає, а двері важкі.",
        "Several rolled layers, not one sheet in the door. Otherwise there is almost no effect and a heavy door.",
        "Несколько слоёв с прокаткой, не один лист в дверь. Иначе эффекта почти нет, а дверь тяжёлая.",
    ),
    "prebuy": (
        "Пробіг звіряємо по блоках, не лише по одометру. Товщиномір — по елементах, не «одна точка на крилі».",
        "Mileage is checked in modules, not only the odometer. Paint meter on every panel, not one spot on a wing.",
        "Пробег сверяем по блокам, не только по одометру. Толщиномер — по элементам, не одна точка на крыле.",
    ),
    "glass-chip": (
        "Скол заливаємо, поки тріщина не пішла від удару каменя. Якщо вже пішла по полю — лише заміна скла.",
        "The chip is filled before a crack runs from the stone. If it has already run, the glass is replaced.",
        "Скол заливаем, пока трещина не ушла от удара камня. Если уже ушла по полю — только замена стекла.",
    ),
    "tint": (
        "Світлопропускання задньої півсфери — за нормами PL. Передні стекла не тонуємо «в нуль».",
        "Rear-side tint stays within PL limits. We do not black out the fronts.",
        "Светопропускание задней полусферы — по нормам PL. Передние стёкла не тонируем «в ноль».",
    ),
    "headliner": (
        "Стелю знімаємо, клеїмо новий матеріал по каркасу. Люк і ручки обходимо, не мажемо насипом.",
        "The headliner comes out; new cloth is glued on the board. Sunroof and handles are wrapped, not smeared.",
        "Потолок снимаем, клеим новый материал по каркасу. Люк и ручки обходим.",
    ),
    "lpg": (
        "Балон із сертифікатом, герметичність і реєстрація. Регулювання по MAP після встановлення.",
        "Certified tank, leak-down and paperwork. MAP tune after the install.",
        "Баллон с сертификатом, герметичность и регистрация. Регулировка по MAP после установки.",
    ),
    "mobile": (
        "На місці — запуск, запаска, зчитування помилок. Складний ремонт веземо в бокс, не «на узбіччі в дощ».",
        "On site: start, spare, a scan. Heavy work goes to the bay, not in the rain on the verge.",
        "На месте — запуск, запаска, считывание ошибок. Сложный ремонт везём в бокс.",
    ),
    "adas": (
        "Статичні мішені і/або калібрувальний заїзд після скла чи ходової. Без цього асистенти брешуть у смузі.",
        "Static targets and/or a calibration drive after glass or chassis work. Skip it and lane assist lies.",
        "Статические мишени и/или калибровочный заезд после стекла или ходовой. Без этого ассистенты врут в полосе.",
    ),
    "android": (
        "Кермові кнопки і камера — через CAN/адаптер під модель. «Китайська магнітола без проводки» не ставимо.",
        "Steering keys and camera go through a model CAN/adapter. We do not fit a random head unit with no loom.",
        "Кнопки на руле и камера — через CAN/адаптер под модель. «Китайскую магнитолу без проводки» не ставим.",
    ),
    "srs": (
        "Діагностика до розбору торпедо. Штатний блок і шлейф, не резистор у колодку подушки.",
        "Diagnose before the dash comes out. Factory module and clock spring, not a resistor in the airbag plug.",
        "Диагностика до разбора торпедо. Штатный блок и шлейф, не резистор в колодку подушки.",
    ),
}


def steps_for(wid: str, title_hint: str) -> list[tuple[str, str, str]]:
    return [
        (
            "Узгоджуємо обсяг, ціну роботи і чи входять запчастини — до старту.",
            "We agree scope, labour price and whether parts are included — before we start.",
            "Согласуем объём, цену работы и входят ли запчасти — до старта.",
        ),
        (
            f"Виконуємо {title_hint} за технологією виробника, з фото вузлів у процесі.",
            f"We carry out the job to the maker’s procedure, with photos of the parts as we go.",
            f"Выполняем работу по технологии производителя, с фото узлов в процессе.",
        ),
        (
            "Перевіряємо результат на авто: зазори, коди помилок, тестова поїздка за потреби.",
            "We check the result on the car: gaps, fault codes, a road test when it applies.",
            "Проверяем результат на авто: зазоры, коды ошибок, тестовая поездка при необходимости.",
        ),
        (
            "На руки: гарантія на роботу, що входило в ціну і що варто зробити наступним візитом.",
            "You leave with labour warranty, what the price covered and what to plan next visit.",
            "На руки: гарантия на работу, что входило в цену и что сделать следующим визитом.",
        ),
    ]


# Unique second-step per extra id for quality
STEP2 = {
    "body-dent": ("Рихтуємо елемент по зазорах, шпаклюємо тонким шаром лише ями.", "We true the panel to the gaps; filler only in hollows, thin.", "Рихтуем элемент по зазорам, шпаклюем тонким слоем только ямы."),
    "body-pdr": ("Витягуємо вмʼятину гачками/клеєм зі світлового кабінету.", "The dent comes out with hooks/glue under a light board.", "Вытягиваем вмятину крючками/клеем из светового кабинета."),
    "body-weld": ("Вирізаємо гниль, ставимо латку з проваром, зачищаємо шов.", "Rust is cut out, a fully welded patch goes in, the seam is dressed.", "Вырезаем гниль, ставим латку с проваром, зачищаем шов."),
    "body-geometry": ("Ставимо авто на стапель і тягнемо до контрольних точок карти.", "The car goes on the jig and is pulled to the data-sheet points.", "Ставим авто на стапель и тянем до контрольных точек карты."),
    "body-bumper": ("Паяємо тріщину, відновлюємо скоби і кріплення під фарбу.", "The crack is welded, brackets restored, then prepped for paint.", "Паяем трещину, восстанавливаем скобы и крепления под краску."),
    "paint-panel": ("Ґрунт, емаль по VIN, лак у камері, сушка за регламентом.", "Primer, VIN-matched enamel, booth clear, bake to spec.", "Грунт, эмаль по VIN, лак в камере, сушка по регламенту."),
    "paint-spot": ("Ізолюємо зону, кладемо емаль і лак локально, поліруємо стик.", "Mask the zone, spot colour and clear, polish the blend.", "Изолируем зону, кладём эмаль и лак локально, полируем стык."),
    "paint-polish": ("Знімаємо шагрень і пил, поліруємо до блиску заводського сусіда.", "Cut peel and nibs, polish to the neighbouring factory gloss.", "Снимаем шагрень и пыль, полируем до блеска заводского соседа."),
    "anticor": ("Миємо днище, сушимо, мастика швів, антигравій арок.", "Wash and dry the floor, seam mastic, stone-chip in the arches.", "Моем днище, сушим, мастика швов, антигравий арок."),
    "detail-chem": ("Екстракція сидінь і килимів, стеля, сушка теплим повітрям.", "Extract seats and carpets, headliner, warm-air dry.", "Экстракция сидений и ковров, потолок, сушка тёплым воздухом."),
    "detail-polish": ("Кілька ступенів пасти під риску, фініш без голограм.", "Compound stages matched to the scratches, hologram-free finish.", "Несколько ступеней пасты под риску, финиш без голограмм."),
    "detail-ceramic": ("Знежирення, шар кераміки, полімеризація в боксі.", "Wipe-down, ceramic layer, cure in the bay.", "Обезжиривание, слой керамики, полимеризация в боксе."),
    "detail-engine": ("Закриваємо розʼєми, миємо відсік, сушимо, клеми назад з моментом.", "Mask connectors, wash the bay, dry, terminals torqued back on.", "Закрываем разъёмы, моем отсек, сушим, клеммы назад с моментом."),
    "ppf": ("Крій плівки, укладка з водою, вигін країв у зазори, сушка.", "Plot the film, wet-lay, tuck edges into gaps, dry.", "Крой пленки, укладка с водой, загиб краёв в зазоры, сушка."),
    "hydro-wheel": ("Знімаємо диски, ґрунт, друк у ванні, лак, баланс після збірки.", "Wheels off, primer, tank dip, clear, balance after assembly.", "Снимаем диски, грунт, печать в ванне, лак, баланс после сборки."),
    "hydro-trim": ("Знімаємо панелі, друкуємо на столі, лак, ставимо назад без скрипів.", "Trims off, bench dip, clear, refit with no squeaks.", "Снимаем панели, печатаем на столе, лак, ставим назад без скрипов."),
    "hydro-cover": ("Знежирення кришки, ґрунт, друк, лак зі стійкістю до мийки мотора.", "Degrease the cover, primer, dip, clear that survives an engine wash.", "Обезжиривание крышки, грунт, печать, лак со стойкостью к мойке мотора."),
    "wrap-partial": ("Мийка і глина зони, розкрій, укладка капота/даху/дзеркал.", "Wash and clay the zone, plot, lay hood/roof/mirrors.", "Мойка и глина зоны, раскрой, укладка капота/крыши/зеркал."),
    "wrap-roof": ("Гріємо плівку від центру даху, обходимо люк і рейлінги.", "Heat-stretch from the roof centre, wrap sunroof and rails.", "Греем плёнку от центра крыши, обходим люк и рейлинги."),
    "carbon-hood": ("Підгін капота/спойлера по петлях і зазорах, кріплення на момент.", "Fit the hood/spoiler on the hinges to factory gaps, torque the hardware.", "Подгон капота/спойлера по петлям и зазорам, крепления на момент."),
    "tire-repair": ("Демонтаж, огляд корду, латка зсередини, монтаж і баланс.", "Demount, inspect the cord, inside patch, mount and balance.", "Демонтаж, осмотр корда, заплата изнутри, монтаж и баланс."),
    "tire-storage": ("Маркуємо вісь, спускаємо до складського тиску, ставимо на стелаж.", "Mark the axle, set storage pressure, rack the set.", "Маркируем ось, спускаем до складского давления, ставим на стеллаж."),
    "rim-straighten": ("Биття на стенді, правка, аргон тріщини, контроль площини.", "Run-out on the rack, true, TIG the crack, re-check the plane.", "Биение на стенде, правка, аргон трещины, контроль плоскости."),
    "rim-paint": ("Піскострумінь, ґрунт, порошок, полімеризація, баланс.", "Blast, primer, powder, cure, balance.", "Пескоструй, грунт, порошок, полимеризация, баланс."),
    "brake-lathe": ("Міряємо товщину, проточка комплектом на вісь, збір з моментом.", "Measure thickness, machine the axle set, torque on rebuild.", "Меряем толщину, проточка комплектом на ось, сборка с моментом."),
    "steering": ("Знімаємо рейку/насос, ремонт або заміна, рідина, розвал.", "Rack/pump off, repair or replace, fluid, then alignment.", "Снимаем рейку/насос, ремонт или замена, жидкость, развал."),
    "cv-joint": ("Пильовик або шарнір/піввісь, мастило, хомути, перевірка люфту.", "Boot or joint/shaft, grease, clamps, play check.", "Пыльник или шарнир/полуось, смазка, хомуты, проверка люфта."),
    "air-suspension": ("Діагностика компресора і подушки, заміна винного вузла, тест натікання.", "Diagnose compressor and bag, replace the failed part, leak-down test.", "Диагностика компрессора и подушки, замена виновного узла, тест натекания."),
    "cabin-filter": ("Знімаємо кришку бардачка/решітки, ставимо фільтр за стрілкою потоку.", "Glovebox/cowl cover off, filter in with the airflow arrow.", "Снимаем крышку бардачка/решётки, ставим фильтр по стрелке потока."),
    "wiring": ("Прозвонка, пайка екранованого джгута, ізоляція, тест CAN.", "Trace, solder the screened loom, insulate, CAN test.", "Прозвонка, пайка экранированного жгута, изоляция, тест CAN."),
    "turbo": ("Знімаємо турбіну, картридж або агрегат, маслоподача, обкатка.", "Turbo off, cartridge or unit, oil feed, run-in.", "Снимаем турбину, картридж или агрегат, маслоподача, обкатка."),
    "injectors": ("Знімаємо рамку, стенд або промивка, збір з новими ущільненнями.", "Rail off, bench or flush, rebuild with new seals.", "Снимаем рампу, стенд или промывка, сборка с новыми уплотнениями."),
    "radiator": ("Тиск системи, заміна радіатора/патрубків/помпи, заправка і прокачка.", "Pressure-test, replace radiator/hoses/pump, fill and bleed.", "Давление системы, замена радиатора/патрубков/помпы, заправка и прокачка."),
    "clutch": ("Коробка вниз, диск/кошик/маховик, момент болтів, адаптація точки.", "Gearbox down, disc/cover/flywheel, bolt torque, bite-point adaptation.", "Коробка вниз, диск/корзина/маховик, момент болтов, адаптация точки."),
    "gearbox": ("Діагностика, розбір на стенді, мехатронік/фрикціони, збір і адаптації.", "Diagnose, bench strip, mechatronic/clutches, assemble and adapt.", "Диагностика, разбор на стенде, мехатроник/фрикционы, сборка и адаптации."),
    "gearbox-flush": ("Піддон вниз, фільтр, нова олива до рівня на гарячу, адаптація.", "Pan off, filter, fresh fluid to hot level, adaptation.", "Поддон вниз, фильтр, новое масло до уровня на горячую, адаптация."),
    "dpf": ("Логи сажі, регенерація або зняття на промивку, EGR за потреби.", "Soot logs, regen or off-car clean, EGR if needed.", "Логи сажи, регенерация или снятие на промывку, EGR при необходимости."),
    "starter-alt": ("Замір струму/напруги, зняття, щітки або агрегат, тест зарядки.", "Current/voltage, removal, brushes or unit, charging test.", "Замер тока/напряжения, снятие, щётки или агрегат, тест зарядки."),
    "alarm": ("Розведення по CAN, обхідчик іммо, сирена, навчання брелоків.", "CAN loom, immobiliser bypass, siren, fob learn.", "Разведение по CAN, обходчик иммо, сирена, обучение брелоков."),
    "keys": ("Нарізка/заготовка, прописка в іммо і комфорт, перевірка личинки.", "Cut/blank, pair to immobiliser and comfort, barrel check.", "Нарезка/заготовка, прописка в иммо и комфорт, проверка личинки."),
    "lights-led": ("Розбір фари, лінзи, герметик, привʼязка і корекція пучка.", "Lamp strip, projectors, reseal, pairing and beam aim.", "Разбор фары, линзы, герметик, привязка и коррекция пучка."),
    "lights-restore": ("Шліфування скла, полірування, лак або PPF, сушка.", "Sand the lens, polish, lacquer or PPF, cure.", "Шлифование стекла, полировка, лак или PPF, сушка."),
    "sound-system": ("Силовий кабель, динаміки/саб, налаштування підсилювача без кліпу.", "Power cable, speakers/sub, amp gain without clip.", "Силовой кабель, динамики/саб, настройка усилителя без клипа."),
    "soundproof": ("Розбір салону, вібро в кілька шарів з прокаткою, збір без цвіркунів.", "Cabin strip, several rolled vibration layers, rebuild with no rattles.", "Разбор салона, вибро в несколько слоёв с прокаткой, сборка без сверчков."),
    "prebuy": ("Підйомник, товщиномір по елементах, сканер блоків, тест-драйв.", "Lift, paint meter per panel, module scan, road test.", "Подъёмник, толщиномер по элементам, сканер блоков, тест-драйв."),
    "glass-chip": ("Чистка сколу, полімер під УФ, полірування точки.", "Clean the chip, UV resin, polish the spot.", "Чистка скола, полимер под УФ, полировка точки."),
    "tint": (
        "Мийка скла, крій плівки, укладка без пилу, краї під ущільнювач.",
        "Glass wash, plot, dust-free lay, edges under the seal.",
        "Мойка стёкол, крой плёнки, укладка без пыли, края под уплотнитель.",
    ),
    "headliner": ("Знімаємо стелю, новий матеріал на каркас, люк і ручки на місце.", "Headliner out, new cloth on the board, sunroof and handles refitted.", "Снимаем потолок, новый материал на каркас, люк и ручки на место."),
    "lpg": ("Редуктор, форсунки, балон, герметичність, регулювання MAP.", "Reducer, injectors, tank, leak-down, MAP tune.", "Редуктор, форсунки, баллон, герметичность, регулировка MAP."),
    "mobile": ("Приїзд у вікно слоту, діагностика на місці, запуск або евакуація в бокс.", "Arrive in the slot window, on-site diagnosis, start or truck to the bay.", "Приезд в окно слота, диагностика на месте, запуск или эвакуация в бокс."),
    "adas": ("Мішені / заїзд калібрування, запис у блоки, перевірка асистентів.", "Targets / calibration drive, write to modules, assist check.", "Мишени / заезд калибровки, запись в блоки, проверка ассистентов."),
    "android": ("Рамка під модель, живлення і CAN, камера, кермові кнопки.", "Model fascia, power and CAN, camera, steering keys.", "Рамка под модель, питание и CAN, камера, кнопки на руле."),
    "srs": ("Сканер SRS, шлейф або блок, збір торпедо, індикатор гасне штатно.", "SRS scan, clock spring or module, dash rebuild, lamp off by the book.", "Сканер SRS, шлейф или блок, сборка торпедо, индикатор гаснет штатно."),
}


def patch_catalog_seed() -> None:
    path = ROOT / "lib" / "data" / "catalog_seed.dart"
    text = path.read_text(encoding="utf-8")
    for wid, triple in CORE_TIPS.items():
        pattern = rf"(id: '{wid}',[\s\S]*?olegTip: )L\([\s\S]*?\n    \),"
        def _repl(m, t=triple):
            return m.group(1) + dart_l(*t, indent='      ') + ','

        new, n = re.subn(pattern, _repl, text, count=1)
        if n != 1:
            raise SystemExit(f"catalog_seed: failed {wid} n={n}")
        text = new
    path.write_text(text, encoding="utf-8")
    print("catalog_seed tips ok")


def patch_catalog_extra() -> None:
    path = ROOT / "lib" / "data" / "catalog_extra.dart"
    text = path.read_text(encoding="utf-8")
    text = text.replace(
        """const _tip = L(
  'Олег: спочатку огляд і кошторис, потім робота — без сюрпризів у кінці.',
  'Oleg: inspect and quote first, then the work — no surprise bill at the end.',
  'Олег: сначала осмотр и смета, потом работа — без сюрпризов в конце.',
);

ServiceWork _w({
  required String id,
  required L title,
  required RepairCategory category,
  required MasterSpecialty specialty,
  required int minutes,
  required int price,
}) {
  return ServiceWork(
    id: id,
    category: category,
    title: title,
    specialty: specialty,
    minutes: minutes,
    priceBasic: (price * 0.72).round(),
    priceStandard: price,
    pricePremium: (price * 1.65).round(),
    olegTip: _tip,
  );
}""",
        """ServiceWork _w({
  required String id,
  required L title,
  required RepairCategory category,
  required MasterSpecialty specialty,
  required int minutes,
  required int price,
  required L tip,
}) {
  return ServiceWork(
    id: id,
    category: category,
    title: title,
    specialty: specialty,
    minutes: minutes,
    priceBasic: (price * 0.72).round(),
    priceStandard: price,
    pricePremium: (price * 1.65).round(),
    olegTip: tip,
  );
}""",
    )
    for wid, triple in EXTRA_TIPS.items():
        pattern = rf"(id: '{wid}',[\s\S]*?price: \d+,)(\n  \),)"
        tip_block = f"\n    tip: {dart_l(*triple, indent='      ')},"
        new, n = re.subn(pattern, rf"\1{tip_block}\2", text, count=1)
        if n != 1:
            raise SystemExit(f"catalog_extra: failed {wid} n={n}")
        text = new
    path.write_text(text, encoding="utf-8")
    print("catalog_extra tips ok")


def write_you_get_extra() -> None:
    chunks = ["part of 'you_get_steps.dart';\n", "const youGetExtraSteps = <String, List<L>>{\n"]
    for wid, triple in EXTRA_TIPS.items():
        s2 = STEP2[wid]
        s1, s3, s4 = steps_for(wid, wid)[0], steps_for(wid, wid)[2], steps_for(wid, wid)[3]
        chunks.append(f"  '{wid}': [\n")
        for step in (s1, s2, s3, s4):
            chunks.append(f"    {dart_l(*step, indent='      ')},\n")
        chunks.append("  ],\n")
    chunks.append("};\n")
    path = ROOT / "lib" / "data" / "you_get_extra.dart"
    path.write_text("".join(chunks), encoding="utf-8")
    print("you_get_extra written")


def main() -> None:
    patch_catalog_seed()
    patch_catalog_extra()
    write_you_get_extra()


if __name__ == "__main__":
    main()
