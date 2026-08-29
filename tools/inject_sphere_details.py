# -*- coding: utf-8 -*-
"""Insert AutoSphere.detail after each subtitle block."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

DETAILS = {
    "insurance": (
        "Консультація та оформлення ОСЦПВ і КАСКО за VIN: порівнюємо франшизу, покриття скла, удари тварин і асистанс. Після ДТП допоможемо зібрати фото, схему і заяву страховику. Консультація безкоштовна; премія — за тарифом компанії.",
        "We issue MTPL and CASCO by VIN: deductible, glass, animal strikes and roadside assist. After a crash we help with photos, a sketch and the insurer claim. Advice is free; the premium is the insurer’s tariff.",
        "Консультация и оформление ОСАГО и КАСКО по VIN: франшиза, стекло, животные и ассистанс. После ДТП поможем собрать фото, схему и заявление. Консультация бесплатная; премия — по тарифу страховщика.",
    ),
    "diag": (
        "Повне зчитування всіх блоків дилерським сканером (ODIS, ISTA, Xentry, Autel): коди, живі дані, тести актуаторів. Коди не стираємо, поки не підтверджена причина. 40–60 хв; робота від 1 400 ₴, запчастини окремо.",
        "Full dealer-level scan (ODIS, ISTA, Xentry, Autel): codes, live data, actuator tests. Codes stay until the cause is confirmed. 40–60 min; labour from ₴1,400, parts extra.",
        "Полное считывание всех блоков дилерским сканером (ODIS, ISTA, Xentry, Autel): коды, живые данные, тесты актуаторов. Коды не стираем, пока не подтверждена причина. 40–60 мин; работа от 1 400 ₴, запчасти отдельно.",
    ),
    "engine": (
        "Моторний цех: компресія і leak-down, ендоскоп, ГРМ за регламентом, турбіна, свічки. Кошторис після огляду на підйомнику, не «на слух з парковки». Свічки від 1 000 ₴, комплект ГРМ від 6 800 ₴; капіталка — після дефектування.",
        "Engine bay: compression and leak-down, borescope, timing by mileage, turbo, plugs. Quote after a lift inspection, not by ear in the yard. Plugs from ₴1,000, timing kit labour from ₴6,800; a rebuild is quoted after teardown.",
        "Моторный цех: компрессия и leak-down, эндоскоп, ГРМ по регламенту, турбина, свечи. Смета после осмотра на подъёмнике. Свечи от 1 000 ₴, комплект ГРМ от 6 800 ₴; капиталка — после дефектовки.",
    ),
    "electronics": (
        "Електрика авто: тест АКБ під навантаженням, стартер і генератор, джгути, CAN і блоки. Після заміни акумулятора робимо адаптації вікон і дроселя, якщо цього просить блок. Від 800 ₴ за перевірку/заміну АКБ.",
        "Vehicle electrics: load-test the battery, starter and alternator, looms, CAN and modules. After a battery swap we run window and throttle adaptations if the car asks. From ₴800 for battery test/replace.",
        "Автоэлектрика: тест АКБ под нагрузкой, стартер и генератор, жгуты, CAN и блоки. После замены аккумулятора — адаптации окон и дросселя. От 800 ₴ за проверку/замену АКБ.",
    ),
    "coding": (
        "Кодування опцій і привʼязка блоків VAG / BMW / Mercedes: ODIS, ISTA, Xentry, ENET. Перед записом перевіряємо напругу мережі — слабкий генератор обриває прошивку. Робота від 5 500 ₴; калібрування фар і ADAS — окремі позиції.",
        "Option coding and module pairing for VAG / BMW / Mercedes: ODIS, ISTA, Xentry, ENET. We confirm charging voltage before a write — a weak alternator bricks the flash. Labour from ₴5,500; lamp and ADAS calibration billed separately.",
        "Кодирование опций и привязка блоков VAG / BMW / Mercedes: ODIS, ISTA, Xentry, ENET. Перед записью проверяем зарядку. Работа от 5 500 ₴; калибровка фар и ADAS — отдельно.",
    ),
    "chassis": (
        "Ходова на підйомнику: важелі, сайлентблоки, опори, ШРУС, пневмо. Люфт показуємо клієнту на місці і ділимо на «міняти зараз / ще походить». Діагностика від 1 200 ₴; заміна вузлів — за окремим кошторисом.",
        "Chassis on the lift: arms, bushes, mounts, CV joints, air springs. We show play in person and split “replace now / still serviceable”. Inspection from ₴1,200; parts and labour quoted per item.",
        "Ходовая на подъёмнике: рычаги, сайлентблоки, опоры, ШРУС, пневмо. Люфт показываем на месте. Диагностика от 1 200 ₴; замена узлов — по отдельной смете.",
    ),
    "brakes": (
        "Гальма комплектом на вісь: колодки, диски, супорти, рідина DOT4/DOT5.1. Завжди міряємо товщину дисків — проточка лише якщо залишається запас. Колодки від 1 800 ₴ робота; диски від 3 200 ₴; запчастини окремо.",
        "Brakes as an axle set: pads, discs, calipers, DOT4/DOT5.1 fluid. Disc thickness is measured first — machining only with enough meat left. Pad labour from ₴1,800; discs from ₴3,200; parts extra.",
        "Тормоза комплектом на ось: колодки, диски, суппорта, жидкость DOT4/DOT5.1. Толщину дисков меряем всегда. Колодки от 1 800 ₴ работа; диски от 3 200 ₴; запчасти отдельно.",
    ),
    "paint": (
        "Малярка: підбір емалі за VIN і спектрофотометром, локальний скол або фарбування елемента в камері, лак і полірування стику. Скол від 2 500 ₴, елемент від 6 500 ₴. Термін 1–3 дні залежно від площі.",
        "Paint shop: colour match by VIN and spectrophotometer, chip repair or a full panel in booth, clear coat and blend polish. A chip from ₴2,500, a panel from ₴6,500. 1–3 days depending on area.",
        "Малярка: подбор эмали по VIN и спектрофотометру, скол или покраска элемента в камере. Скол от 2 500 ₴, элемент от 6 500 ₴. Срок 1–3 дня.",
    ),
    "wash": (
        "Двофазна мийка без піску на лаку, хімчистка салону з екстракцією, полірування кузова і кераміка. Моторний відсік — окремо, зі зняттям клем. Контактна мийка від 350 ₴, стандарт від 900 ₴; кераміка від 8 900 ₴.",
        "Two-stage wash that does not grind grit into clear coat, interior extraction, machine polish and ceramic. Engine bay is a separate job with terminals disconnected. Contact wash from ₴350, standard from ₴900; ceramic from ₴8,900.",
        "Двухфазная мойка без песка на лаке, химчистка с экстракцией, полировка и керамика. Моторный отсек — отдельно. Мойка от 350 ₴, стандарт от 900 ₴; керамика от 8 900 ₴.",
    ),
    "tires": (
        "Шиномонтаж R15–R21: демонтаж, монтаж, балансування на стенді, вентилі. Прокол латаємо зсередини; джгут — лише щоб доїхати. Сезонне зберігання комплектом. Прокол від 250 ₴, зміна комплекту від 600 ₴.",
        "Tyre fitting R15–R21: demount, mount, spin-balance, valves. Punctures are patched from inside; a plug is only to get you home. Seasonal storage for a full set. Patch from ₴250, a set change from ₴600.",
        "Шиномонтаж R15–R21: демонтаж, монтаж, балансировка, вентили. Прокол латаем изнутри. Сезонное хранение комплектом. Прокол от 250 ₴, смена комплекта от 600 ₴.",
    ),
    "align": (
        "3D-стенд Hunter після заміни важелів, рульових тяг або шин. Спочатку геометрія підвіски, потім кути. 50–70 хв; робота 1 400 ₴. Якщо важіль гнутий — спочатку заміна, інакше нова гума зʼїдається за тиждень.",
        "Hunter 3D alignment after arms, track rods or tyres. Suspension geometry first, then angles. 50–70 min; labour ₴1,400. A bent arm is replaced first, or new tyres wear in a week.",
        "3D-стенд Hunter после рычагов, тяг или шин. Сначала геометрия подвески, потом углы. 50–70 мин; работа 1 400 ₴. Гнутый рычаг меняем до стенда.",
    ),
    "tuning": (
        "Чіп Stage 1–2 з бекапом стоку і контрольними логами. Stage 2 ставимо лише з даунпайпом і паливом 98; інакше страждає турбіна. Перед записом — діагностика і зарядка. Від 8 900 ₴; залізо вихлопу окремо.",
        "Stage 1–2 remap with a stock backup and verification logs. Stage 2 only with a downpipe and 98 octane; otherwise the turbo pays. Diagnostics and charging voltage first. From ₴8,900; exhaust hardware extra.",
        "Чип Stage 1–2 с бэкапом стока и логами. Stage 2 только с даунпайпом и 98-м. Перед записью — диагностика и зарядка. От 8 900 ₴; железо выхлопа отдельно.",
    ),
    "stage3": (
        "Побудова Stage 3: ковані поршні, шатуни, турбіна, інтеркулер, паливна, збірка з динамометричним контролем. Спочатку дефектування блоку, потім замовлення заліза. Робота від 78 000 ₴; комплектуючі — за специфікацією мотора.",
        "Stage 3 build: forged pistons and rods, turbo, intercooler, fuel system, torque-spec assembly. Block survey first, hardware second. Labour from ₴78,000; parts to the engine spec.",
        "Сборка Stage 3: кованые поршни, шатуны, турбина, интеркулер, топливная. Сначала дефектовка блока. Работа от 78 000 ₴; комплектующие — по спецификации.",
    ),
    "exhaust": (
        "Вихлоп: даунпайп, кат/пламегасник, резонатор, глушник на випуск. Після даунпайпа обовʼязкова прошивка — інакше чек і бідна суміш. Робота від 8 500 ₴; труби і фланці за заміром.",
        "Exhaust: downpipe, cat/test pipe, resonator, tail section. A downpipe needs a remap or you get a check light and a lean mix. Labour from ₴8,500; pipework by measurement.",
        "Выхлоп: даунпайп, кат/пламегаситель, резонатор, глушитель. После даунпайпа нужна прошивка. Работа от 8 500 ₴; трубы по замеру.",
    ),
    "hydro": (
        "Гідродрук пластику, кришок і дисків: знежирення, ґрунт, плівка у ванні, лак. Пил у ванні дає крапки на малюнку — деталь має бути сухою і чистою. Від 2 200 ₴ за кришку, диски від 4 800 ₴ за комплект.",
        "Hydro dip for plastic, covers and wheels: degrease, primer, film in tank, clear. Dust in the tank prints as dots — the part must be dry and clean. Covers from ₴2,200, a wheel set from ₴4,800.",
        "Гидропечать пластика, крышек и дисков: обезжиривание, грунт, пленка, лак. Пыль в ванне даёт точки. Крышка от 2 200 ₴, диски от 4 800 ₴ за комплект.",
    ),
    "carbon": (
        "Карбон: real carbon (препрег, автоклав) або якісна плівка — різницю пояснюємо до замовлення. Капот, спойлер, накладки салону. Від 4 800 ₴ за накладку; капот/спойлер від 8 900 ₴.",
        "Carbon: autoclave real carbon or quality film — we say which before you order. Hood, spoiler, cabin overlays. Overlay from ₴4,800; hood/spoiler from ₴8,900.",
        "Карбон: real carbon (препрег, автоклав) или качественная пленка — говорим до заказа. Капот, спойлер, накладки. От 4 800 ₴ за накладку; капот/спойлер от 8 900 ₴.",
    ),
    "wrap": (
        "Оклейка кузова вінілом: мийка, глина, знежирення, розкрій, сушка швів. Повне авто від 18 000 ₴, дах від 4 200 ₴, капот/дзеркала — часткова зона. Плівка на бруд і бітум не лягає.",
        "Vinyl wrap: wash, clay, degrease, plot, seam heat. Full car from ₴18,000, roof from ₴4,200, hood/mirrors as a zone. Film will not stick to dirt or tar.",
        "Оклейка винилом: мойка, глина, обезжиривание, раскрой. Полное авто от 18 000 ₴, крыша от 4 200 ₴. Пленка на грязь не ложится.",
    ),
    "glass": (
        "Скло: скол лобового (полімер, доки тріщина не пішла), заміна лобового/бокового, тонування за нормами PL. Після лобового з камерою — калібрування ADAS. Скол від 800 ₴, тонування від 2 800 ₴.",
        "Glass: windshield chip (resin before it runs), windscreen/side replacement, tint within PL limits. A camera windshield needs ADAS calibration. Chip from ₴800, tint from ₴2,800.",
        "Стекло: скол лобового (полимер, пока трещина не ушла), замена, тонировка по нормам PL. После лобового с камерой — калибровка ADAS. Скол от 800 ₴, тонировка от 2 800 ₴.",
    ),
    "interior": (
        "Салон: перетяжка шкірою або Alcantara, кермо, стеля, люк. Беремо матеріал, який не тріскає за одну зиму; дешевшу площу краще зменшити, ніж економити на шкурі. Від 8 500 ₴ за зону; стеля від 5 500 ₴.",
        "Interior: leather or Alcantara retrim, wheel, headliner, sunroof. We use hide that survives a winter; less area is better than cheap leather. Zone from ₴8,500; headliner from ₴5,500.",
        "Салон: кожа или Alcantara, руль, потолок, люк. Материал, который не трескается за зиму. От 8 500 ₴ за зону; потолок от 5 500 ₴.",
    ),
    "ac": (
        "Кондиціонер: вакуум, пошук витоку азотом/UV, заправка R134a або R1234yf за вагою з мануалу, антифриз компресора. Заправка «на око» без вакууму — гроші в повітря. Від 1 400 ₴; радіатор і трубки — окремо.",
        "A/C: vacuum, nitrogen/UV leak hunt, R134a or R1234yf by the book weight, PAG oil. A refill without vacuum is money into the air. From ₴1,400; condenser and pipes extra.",
        "Кондиционер: вакуум, поиск утечки азотом/UV, заправка R134a или R1234yf по весу. Заправка без вакуума — деньги в воздух. От 1 400 ₴; радиатор и трубки отдельно.",
    ),
    "tow": (
        "Евакуатор по Варшаві та кільцевій: платформа, часткове навантаження, прикурювання, запасне колесо. Повний привід і АКПП — лише на платформі, без прокрутки кардану. Від 1 200 ₴ у місті; за місто — за км.",
        "Tow in Warsaw and on the ring: flatbed, dollies, jump start, spare wheel. AWD and automatics travel on a flatbed only — no spinning the prop. From ₴1,200 in town; extra km billed.",
        "Эвакуатор по Варшаве и кольцевой: платформа, частичная погрузка, прикуривание. Полный привод и АКПП — только на платформе. От 1 200 ₴ в городе; за город — по км.",
    ),
    "service": (
        "Регламентне ТО: олива за допуском VIN (не «як у сусіда»), масляний, повітряний і салонний фільтри, антифриз, свічки за пробігом. Зливний болт із шайбою міняємо за мануалом. Олива від 1 100 ₴ робота + матеріали.",
        "Scheduled service: oil by VIN spec (not a neighbour’s grade), oil/air/cabin filters, coolant, plugs by mileage. Crush-washer drain bolts are replaced. Oil labour from ₴1,100 plus materials.",
        "Регламентное ТО: масло по допуску VIN, масляный, воздушный и салонный фильтры, антифриз, свечи. Сливной болт с шайбой меняем по мануалу. Масло от 1 100 ₴ работа + материалы.",
    ),
    "body": (
        "Кузовний цех: рихтовка елемента, зварювання порогів і лонжеронів, стапель після удару, геометрія. Спочатку замір, потім витяжка — фарбуємо вже по виведеній площині. Рихтовка від 4 500 ₴; геометрія від 2 800 ₴.",
        "Body shop: panel beating, sill and rail welding, jig after a hit, geometry. Measure first, pull second — paint only on a true panel. Dent repair from ₴4,500; geometry from ₴2,800.",
        "Кузовной цех: рихтовка, сварка порогов и лонжеронов, стапель, геометрия. Сначала замер, потом вытяжка. Рихтовка от 4 500 ₴; геометрия от 2 800 ₴.",
    ),
    "pdr": (
        "PDR — витяжка вмʼятин гачками без фарбування, якщо лак цілий. Град, двері сусіда, паркінг. Якщо фарба тріснула — це вже малярка. Від 1 800 ₴ за точку; град оцінюємо після огляду на світлі.",
        "PDR: glue/hook dent removal with intact clear coat. Hail, neighbour’s door, parking knocks. Cracked paint means a respray, not PDR. From ₴1,800 per dent; hail priced after a light-booth look.",
        "PDR — вытяжка вмятин крючками без покраски, если лак целый. Град, паркинг. Трещина лака — уже малярка. От 1 800 ₴ за точку.",
    ),
    "welding": (
        "Зварювання кузова: MIG пороги й чашки, TIG алюміній і пластик бампера, вирізка гнилі з накладанням латок. Шви зачищаємо і готуємо під антикор. Від 3 200 ₴ за зону; метал — за фактом.",
        "Body welding: MIG on sills and strut towers, TIG on aluminium and bumper plastic, rust cut-out and patches. Seams are dressed for underseal. From ₴3,200 per zone; steel billed as used.",
        "Сварка кузова: MIG пороги и чашки, TIG алюминий и пластик бампера, вырезка гнили. Швы под антикор. От 3 200 ₴ за зону.",
    ),
    "bumper": (
        "Ремонт бампера: тріщини, відірвані скоби й кріплення під фару/решітку, підготовка під фарбу. Пластик паяємо, не «сітку на холодну». Від 1 600 ₴; фарбування сколу — окремо.",
        "Bumper repair: cracks, torn brackets and lamp/grille mounts, prep for paint. Plastic is welded, not cold-meshed. From ₴1,600; chip paint extra.",
        "Ремонт бампера: трещины, скобы и крепления, подготовка под краску. Пластик паяем. От 1 600 ₴; покраска скола отдельно.",
    ),
    "anticor": (
        "Антикор днища: мийка, сушка, мастика порогів, арок і лонжеронів, антигравій. Іржа спочатку зачищається, інакше мастика її консервує. Повний комплекс від 4 500 ₴; повтор через 2–3 роки.",
        "Underbody rustproofing: wash, dry, seam mastic on sills, arches and rails, stone-chip. Rust is dressed first or the coating just seals it in. Full job from ₴4,500; recut in 2–3 years.",
        "Антикор днища: мойка, сушка, мастика порогов, арок и лонжеронов, антигравий. Ржавчину зачищаем до покрытия. Комплекс от 4 500 ₴.",
    ),
    "ppf": (
        "Поліуретанова бронеплівка на капот, бампер, пороги, дзеркала. Видаляє дрібні сколи від траси, не замінює малярку після удару. Зона від 12 000 ₴; повне авто — за площею кузова.",
        "Polyurethane PPF on hood, bumper, sills and mirrors. It stops motorway chips; it does not replace paint after a hit. A zone from ₴12,000; full car by panel area.",
        "Полиуретановая бронепленка на капот, бампер, пороги, зеркала. Зона от 12 000 ₴; полное авто — по площади.",
    ),
    "ceramic": (
        "Полірування в кілька ступенів і кераміка/кварц на чистий лак. Перед шаром — мийка, глина, знежирення. Тримається 12–24 місяці при правильній мийці. Полірування від 4 500 ₴, кераміка від 8 900 ₴.",
        "Multi-stage polish and ceramic/quartz on clean clear coat. Wash, clay and wipe-down first. 12–24 months if you wash it properly. Polish from ₴4,500, ceramic from ₴8,900.",
        "Многоступенчатая полировка и керамика/кварц на чистый лак. Сначала мойка и глина. 12–24 месяца. Полировка от 4 500 ₴, керамика от 8 900 ₴.",
    ),
    "chem-clean": (
        "Хімчистка салону: сидіння, килими, стеля, ремені. Екстракція, сушка, нейтралізація запаху — без різкої хімії в салоні наступного дня. Від 2 800 ₴; сильні запахи (дим, тварини) — окрема оцінка.",
        "Interior shampoo: seats, carpets, headliner, belts. Extraction, dry-out, odour control — no harsh chemical smell the next day. From ₴2,800; smoke or pets quoted after inspection.",
        "Химчистка салона: сиденья, ковры, потолок, ремни. Экстракция и сушка. От 2 800 ₴; запах дыма или животных — после осмотра.",
    ),
    "gearbox": (
        "АКПП, DSG і варіатор: діагностика гідроблока/мехатроніка, заміна оливи зі зняттям піддону, ремонт на стенді, адаптації після збірки. Олива — лише допуск виробника. Заміна оливи від 2 800 ₴; ремонт від 18 000 ₴.",
        "AT, DSG and CVT: mechatronic diagnosis, pan-drop fluid service, bench rebuild, post-build adaptations. Fluid is OEM spec only. Fluid service from ₴2,800; rebuild from ₴18,000.",
        "АКПП, DSG и вариатор: гидроблок/мехатроник, замена масла со снятием поддона, стенд, адаптации. Масло — допуск завода. Замена масла от 2 800 ₴; ремонт от 18 000 ₴.",
    ),
    "clutch": (
        "Зчеплення МКПП: диск, кошик, витискний, двомасовий маховик за люфтом. Після заміни — адаптація точки схоплювання, якщо є. Робота від 7 800 ₴; комплект — за каталогом моделі.",
        "Manual clutch: disc, cover, release bearing, dual-mass flywheel if it has play. Bite-point adaptation after if the car has it. Labour from ₴7,800; kit by the parts catalogue.",
        "Сцепление МКПП: диск, корзина, выжимной, двухмассовый маховик. После замены — адаптация. Работа от 7 800 ₴; комплект по каталогу.",
    ),
    "steering": (
        "Рульова рейка і ГУР: стуки, течі, електрорейка, насос. Після ремонту — розвал. Не «підтягуємо» рейку наживо, якщо зношені втулки. Від 6 500 ₴ робота; рідина ГУР за специфікацією.",
        "Steering rack and PAS: knock, leaks, electric rack, pump. Alignment after the job. We do not “nip up” a worn rack. Labour from ₴6,500; PAS fluid to spec.",
        "Рулевая рейка и ГУР: стуки, течи, электрорейка, насос. После ремонта — развал. Работа от 6 500 ₴.",
    ),
    "turbo": (
        "Турбіна: люфт вала, течі оливи в інтеркулер, картридж, актуатор/геометрія. Причина оливи в турбіні часто в картері — перевіряємо вентиляцію. Від 8 500 ₴; картридж або нова турбіна — за мотором.",
        "Turbo: shaft play, oil in the intercooler, cartridge, actuator/VGT. Oil in the turbo often starts in the crankcase — we check breathers. From ₴8,500; cartridge or new unit by engine.",
        "Турбина: люфт вала, масло в интеркулере, картридж, актуатор. Причину масла ищем и в картере. От 8 500 ₴.",
    ),
    "injectors": (
        "Паливна: промивка форсунок на стенді, рамка, ТНВД, тиск і зворотна магістраль. На дизелі не «ллємо присадки в бак» замість стенду. Від 2 800 ₴; форсунки — за фактом стенду.",
        "Fuel: injector bench clean, rail, high-pressure pump, pressure and return. On diesel we do not pour tank additives instead of a bench. From ₴2,800; injectors priced after the test.",
        "Топливная: промывка форсунок на стенде, рампа, ТНВД. На дизеле не заменяем стенд присадкой в бак. От 2 800 ₴.",
    ),
    "radiator": (
        "Охолодження: радіатор, патрубки, помпа, термостат, пробка. Течі шукаємо під тиском; антифриз не змішуємо (G11/G12/G13). Від 2 400 ₴; рідина окремо за літражем.",
        "Cooling: radiator, hoses, water pump, thermostat, cap. Pressure-test leaks; never mix G11/G12/G13. From ₴2,400; coolant extra by volume.",
        "Охлаждение: радиатор, патрубки, помпа, термостат. Утечки под давлением; антифризы не мешаем. От 2 400 ₴.",
    ),
    "dpf": (
        "Сажовий, EGR, AdBlue/SCR: діагностика засмічення, регенерація, промивка або заміна, клапани EGR. Вимкнення систем під вихлопні норми не робимо. Від 3 500 ₴; сажовий новий — за каталогом.",
        "DPF, EGR, AdBlue/SCR: soot load, regen, clean or replace, EGR valves. We do not delete emissions kit. From ₴3,500; a new DPF is catalogue price.",
        "Сажевый, EGR, AdBlue/SCR: засор, регенерация, промывка или замена. Отключения под нормы не делаем. От 3 500 ₴.",
    ),
    "starter": (
        "Стартер і генератор: не крутить, не заряджає, щітки, бендікс, діодний міст, обгінні муфти. Спочатку тест струму і напруги, потім зняття. Від 1 800 ₴; агрегат — ремонт або новий.",
        "Starter and alternator: no crank, no charge, brushes, bendix, rectifier, overrunning pulley. Current and voltage first, then removal. From ₴1,800; unit rebuilt or new.",
        "Стартер и генератор: не крутит, не заряжает, щетки, бендикс, диодный мост. Сначала замер тока. От 1 800 ₴.",
    ),
    "alarm": (
        "Сигналізація та іммобілайзер: StarLine / Pandora, обхідчик, CAN-модуль, постановка з телефону. Ставимо з урахуванням штатного іммо. Від 4 500 ₴; брелок і сирена — за комплектацією.",
        "Alarm and immobiliser: StarLine / Pandora, bypass, CAN module, phone arming. Fitted around the factory immobiliser. From ₴4,500; fob and siren by kit.",
        "Сигнализация и иммобилайзер: StarLine / Pandora, обходчик, CAN. Ставим вокруг штатного иммо. От 4 500 ₴.",
    ),
    "keys": (
        "Автоключі: чіп-ключ, прописка в іммобілайзер, личинка дверей, замок запалювання. Без «обнулення» блоків наосліп. Від 2 500 ₴; заготовка ключа — за моделлю.",
        "Keys: transponder, immobiliser pairing, door barrel, ignition lock. No blind module wipes. From ₴2,500; blank by model.",
        "Автоключи: чип-ключ, прописка в иммо, личинка, замок зажигания. От 2 500 ₴; заготовка по модели.",
    ),
    "lights": (
        "Світло: бі-LED / ксенон, лінзи, реставрація скла фар, привʼязка після заміни. Полірування без лаку жовтіє за сезон. Реставрація від 1 400 ₴, лінзи від 5 500 ₴; кодування фар — окремо.",
        "Lighting: bi-LED / xenon, projectors, lens restore, pairing after a swap. Polish without lacquer yellows in a season. Restore from ₴1,400, lenses from ₴5,500; coding extra.",
        "Свет: би-LED / ксенон, линзы, реставрация стекла, привязка. Полировка без лака желтеет. Реставрация от 1 400 ₴, линзы от 5 500 ₴.",
    ),
    "sound": (
        "Автозвук: магнітола, динаміки, саб, підсилювач, розведення силового кабелю. Рахуємо струм і переріз, не «на око». Від 6 500 ₴ за систему; CarPlay/Android — окрема позиція.",
        "Car audio: head unit, speakers, sub, amp, power cable sized for current — not guessed. From ₴6,500 for a system; CarPlay/Android billed apart.",
        "Автозвук: магнитола, динамики, саб, усилитель, силовая проводка по току. От 6 500 ₴ за систему.",
    ),
    "soundproof": (
        "Шумо- і віброізоляція: двері, підлога, арки, дах — шари STP/аналог з прокаткою. Без «одного листа в двері». Комплекс від 8 900 ₴; зони можна набирати окремо.",
        "Sound and vibration deadening: doors, floor, arches, roof — rolled STP-type layers, not one sheet in a door. Full job from ₴8,900; zones can be booked separately.",
        "Шумо- и виброизоляция: двери, пол, арки, крыша — слои STP с прокаткой. Комплекс от 8 900 ₴.",
    ),
    "prebuy": (
        "Перевірка перед купівлею: підйомник, товщиномір ЛФМ, сканер усіх блоків, звірка пробігу по модулях, тестова поїздка. Письмовий звіт того ж дня. Від 2 500 ₴; виїзд на місце продавця — окремо.",
        "Pre-purchase: lift, paint meter, full module scan, mileage vs modules, road test. Written report the same day. From ₴2,500; a visit to the seller is extra.",
        "Проверка перед покупкой: подъёмник, толщиномер, сканер всех блоков, пробег по модулям, тест-драйв. Отчёт в тот же день. От 2 500 ₴.",
    ),
    "rims": (
        "Диски: правка литва на стенді, аргон тріщин, порошкове фарбування. Після правки — балансування. Правка від 1 400 ₴ за диск; порошок від 4 500 ₴ за комплект.",
        "Wheels: cast straightening, TIG on cracks, powder coat. Balance after a true. Straighten from ₴1,400 per wheel; powder from ₴4,500 a set.",
        "Диски: правка литья, аргон трещин, порошок. После правки — баланс. Правка от 1 400 ₴ за диск; порошок от 4 500 ₴ за комплект.",
    ),
    "lpg": (
        "ГБО 4-го покоління: редуктор, форсунки, електроніка, балон із сертифікатом, реєстрація. Сервіс — фільтри і регулювання по MAP. Встановлення від 18 000 ₴; сервіс — за регламентом пробігу.",
        "LPG 4th gen: reducer, injectors, controller, certified tank, paperwork. Service is filters and MAP tune. Install from ₴18,000; service by mileage.",
        "ГБО 4 поколения: редуктор, форсунки, электроника, баллон с сертификатом. Установка от 18 000 ₴; сервис по пробегу.",
    ),
    "mobile": (
        "Виїзд майстра: прикурити, запаска, зчитування помилок на місці, дрібна електрика. Складний ремонт — евакуатор у бокс. Від 900 ₴ виїзд у місті; запчастини з собою — за домовленістю.",
        "Mobile tech: jump start, spare wheel, on-site scan, light electrics. Heavy jobs go to the bay on a truck. From ₴900 in town; parts by arrangement.",
        "Выезд мастера: прикурить, запаска, сканер на месте. Сложный ремонт — эвакуатор в бокс. От 900 ₴ в городе.",
    ),
    "adas": (
        "Калібрування камер і радарів ADAS після лобового, підвіски або кодування. Статичний стенд і/або калібрувальний заїзд. Без цього асистенти брешуть. Від 3 200 ₴.",
        "ADAS camera and radar calibration after glass, suspension or coding. Static target and/or a calibration drive. Skip it and the assists lie. From ₴3,200.",
        "Калибровка камер и радаров ADAS после лобового, подвески или кодирования. Статический стенд и/или заезд. От 3 200 ₴.",
    ),
    "android": (
        "Головний пристрій: CarPlay / Android Auto, рамка під модель, камера заднього виду, мікрофон. Зберігаємо кермові кнопки через CAN/адаптер. Від 3 500 ₴ робота; ГУ — за прайсом бренду.",
        "Head unit: CarPlay / Android Auto, model fascia, reversing camera, mic. Steering-wheel keys stay via CAN/adapter. Labour from ₴3,500; unit at brand price.",
        "Головное устройство: CarPlay / Android Auto, рамка, камера заднего вида. Кнопки на руле через CAN. Работа от 3 500 ₴.",
    ),
    "srs": (
        "SRS: індикатор подушки, шлейф керма, блок, піропатрони після ДТП. Діагностика до розбору торпедо. Відновлюємо штатну систему, не «обманки» в колодку. Від 4 500 ₴.",
        "SRS: airbag light, clock spring, module, squibs after a crash. Diagnose before the dash comes out. We restore the factory system, no resistor cheats. From ₴4,500.",
        "SRS: индикатор подушки, шлейф руля, блок, пиропатроны после ДТП. Штатную систему, не «обманки». От 4 500 ₴.",
    ),
    "cvjoint": (
        "ШРУС і піввісь: хрускіт у повороті, порваний пильовик, люфт. Пильовик міняємо до того, як пісок зʼїсть шарнір. Від 1 800 ₴; граната або піввісь — за стороною.",
        "CV joint and axle: click on lock, torn boot, play. A boot is cheaper than a joint full of grit. From ₴1,800; joint or shaft by side.",
        "ШРУС и полуось: хруст в повороте, порванный пыльник, люфт. Пыльник меняем, пока песок не съел шарнир. От 1 800 ₴.",
    ),
}

PRICE = {
    "insurance": ("від 0 ₴ · консультація", "from ₴0 · advice", "от 0 ₴ · консультация"),
    "diag": ("від 1 400 ₴ · робота", "from ₴1,400 · labour", "от 1 400 ₴ · работа"),
    "engine": ("від 1 000 ₴ · робота", "from ₴1,000 · labour", "от 1 000 ₴ · работа"),
    "electronics": ("від 800 ₴ · робота", "from ₴800 · labour", "от 800 ₴ · работа"),
    "coding": ("від 5 500 ₴ · робота", "from ₴5,500 · labour", "от 5 500 ₴ · работа"),
    "chassis": ("від 1 200 ₴ · робота", "from ₴1,200 · labour", "от 1 200 ₴ · работа"),
    "brakes": ("від 1 800 ₴ · робота", "from ₴1,800 · labour", "от 1 800 ₴ · работа"),
    "paint": ("від 2 500 ₴ · робота", "from ₴2,500 · labour", "от 2 500 ₴ · работа"),
    "wash": ("від 350 ₴ · робота", "from ₴350 · labour", "от 350 ₴ · работа"),
    "tires": ("від 250 ₴ · робота", "from ₴250 · labour", "от 250 ₴ · работа"),
    "align": ("від 1 400 ₴ · робота", "from ₴1,400 · labour", "от 1 400 ₴ · работа"),
    "tuning": ("від 8 900 ₴ · робота", "from ₴8,900 · labour", "от 8 900 ₴ · работа"),
    "stage3": ("від 78 000 ₴ · робота", "from ₴78,000 · labour", "от 78 000 ₴ · работа"),
    "exhaust": ("від 8 500 ₴ · робота", "from ₴8,500 · labour", "от 8 500 ₴ · работа"),
    "hydro": ("від 2 200 ₴ · робота", "from ₴2,200 · labour", "от 2 200 ₴ · работа"),
    "carbon": ("від 4 800 ₴ · робота", "from ₴4,800 · labour", "от 4 800 ₴ · работа"),
    "wrap": ("від 4 200 ₴ · робота", "from ₴4,200 · labour", "от 4 200 ₴ · работа"),
    "glass": ("від 800 ₴ · робота", "from ₴800 · labour", "от 800 ₴ · работа"),
    "interior": ("від 5 500 ₴ · робота", "from ₴5,500 · labour", "от 5 500 ₴ · работа"),
    "ac": ("від 1 400 ₴ · робота", "from ₴1,400 · labour", "от 1 400 ₴ · работа"),
    "tow": ("від 1 200 ₴ · виїзд", "from ₴1,200 · call-out", "от 1 200 ₴ · выезд"),
    "service": ("від 350 ₴ · робота", "from ₴350 · labour", "от 350 ₴ · работа"),
    "body": ("від 1 800 ₴ · робота", "from ₴1,800 · labour", "от 1 800 ₴ · работа"),
    "pdr": ("від 1 800 ₴ · робота", "from ₴1,800 · labour", "от 1 800 ₴ · работа"),
    "welding": ("від 3 200 ₴ · робота", "from ₴3,200 · labour", "от 3 200 ₴ · работа"),
    "bumper": ("від 1 600 ₴ · робота", "from ₴1,600 · labour", "от 1 600 ₴ · работа"),
    "anticor": ("від 4 500 ₴ · робота", "from ₴4,500 · labour", "от 4 500 ₴ · работа"),
    "ppf": ("від 12 000 ₴ · зона", "from ₴12,000 · zone", "от 12 000 ₴ · зона"),
    "ceramic": ("від 4 500 ₴ · робота", "from ₴4,500 · labour", "от 4 500 ₴ · работа"),
    "chem-clean": ("від 2 800 ₴ · робота", "from ₴2,800 · labour", "от 2 800 ₴ · работа"),
    "gearbox": ("від 2 800 ₴ · робота", "from ₴2,800 · labour", "от 2 800 ₴ · работа"),
    "clutch": ("від 7 800 ₴ · робота", "from ₴7,800 · labour", "от 7 800 ₴ · работа"),
    "steering": ("від 6 500 ₴ · робота", "from ₴6,500 · labour", "от 6 500 ₴ · работа"),
    "turbo": ("від 8 500 ₴ · робота", "from ₴8,500 · labour", "от 8 500 ₴ · работа"),
    "injectors": ("від 2 800 ₴ · робота", "from ₴2,800 · labour", "от 2 800 ₴ · работа"),
    "radiator": ("від 2 400 ₴ · робота", "from ₴2,400 · labour", "от 2 400 ₴ · работа"),
    "dpf": ("від 3 500 ₴ · робота", "from ₴3,500 · labour", "от 3 500 ₴ · работа"),
    "starter": ("від 1 800 ₴ · робота", "from ₴1,800 · labour", "от 1 800 ₴ · работа"),
    "alarm": ("від 4 500 ₴ · робота", "from ₴4,500 · labour", "от 4 500 ₴ · работа"),
    "keys": ("від 2 500 ₴ · робота", "from ₴2,500 · labour", "от 2 500 ₴ · работа"),
    "lights": ("від 1 400 ₴ · робота", "from ₴1,400 · labour", "от 1 400 ₴ · работа"),
    "sound": ("від 3 500 ₴ · робота", "from ₴3,500 · labour", "от 3 500 ₴ · работа"),
    "soundproof": ("від 8 900 ₴ · робота", "from ₴8,900 · labour", "от 8 900 ₴ · работа"),
    "prebuy": ("від 2 500 ₴ · робота", "from ₴2,500 · labour", "от 2 500 ₴ · работа"),
    "rims": ("від 1 400 ₴ · робота", "from ₴1,400 · labour", "от 1 400 ₴ · работа"),
    "lpg": ("від 18 000 ₴ · робота", "from ₴18,000 · labour", "от 18 000 ₴ · работа"),
    "mobile": ("від 900 ₴ · виїзд", "from ₴900 · call-out", "от 900 ₴ · выезд"),
    "adas": ("від 3 200 ₴ · робота", "from ₴3,200 · labour", "от 3 200 ₴ · работа"),
    "android": ("від 3 500 ₴ · робота", "from ₴3,500 · labour", "от 3 500 ₴ · работа"),
    "srs": ("від 4 500 ₴ · робота", "from ₴4,500 · labour", "от 4 500 ₴ · работа"),
    "cvjoint": ("від 1 800 ₴ · робота", "from ₴1,800 · labour", "от 1 800 ₴ · работа"),
}

SUB = {
    "insurance": ("ОСЦПВ, КАСКО, франшиза, допомога після ДТП", "MTPL, CASCO, deductible, post-crash help", "ОСАГО, КАСКО, франшиза, помощь после ДТП"),
    "diag": ("Дилерський сканер, усі блоки, живі дані, план ремонту", "Dealer scan, all modules, live data, repair plan", "Дилерский сканер, все блоки, живые данные, план ремонта"),
    "engine": ("ГРМ, компресія, турбіна, свічки, дефектування мотора", "Timing, compression, turbo, plugs, engine survey", "ГРМ, компрессия, турбина, свечи, дефектовка мотора"),
    "electronics": ("АКБ, стартер, генератор, джгути, CAN-блоки", "Battery, starter, alternator, looms, CAN modules", "АКБ, стартер, генератор, жгуты, CAN-блоки"),
    "coding": ("ODIS / ISTA / Xentry: опції, фари, привʼязка блоків", "ODIS / ISTA / Xentry: options, lamps, module pairing", "ODIS / ISTA / Xentry: опции, фары, привязка блоков"),
    "chassis": ("Підйомник: важелі, опори, ШРУС, пневмо, люфти", "Lift: arms, mounts, CV joints, air springs, play", "Подъёмник: рычаги, опоры, ШРУС, пневмо, люфты"),
    "brakes": ("Колодки і диски на вісь, проточка, рідина DOT", "Pads and discs per axle, machining, DOT fluid", "Колодки и диски на ось, проточка, жидкость DOT"),
    "paint": ("Підбір емалі, скол або елемент у камері, лак", "Colour match, chip or booth panel, clear coat", "Подбор эмали, скол или элемент в камере, лак"),
    "wash": ("Двофазна мийка, хімчистка, полірування, кераміка", "Two-stage wash, shampoo, polish, ceramic", "Двухфазная мойка, химчистка, полировка, керамика"),
    "tires": ("Монтаж R15–R21, баланс, прокол зсередини, склад", "Fit R15–R21, balance, inside patch, storage", "Монтаж R15–R21, баланс, прокол изнутри, склад"),
    "align": ("3D Hunter після ходової; кути і знос шин", "Hunter 3D after chassis work; angles and tyre wear", "3D Hunter после ходовой; углы и износ шин"),
    "tuning": ("Stage 1–2 з логами і бекапом стокової прошивки", "Stage 1–2 with logs and a stock-file backup", "Stage 1–2 с логами и бэкапом стоковой прошивки"),
    "stage3": ("Ковані поршні, турбо, інтеркулер, збірка на момент", "Forged pistons, turbo, intercooler, torque-spec build", "Кованые поршни, турбо, интеркулер, сборка по моменту"),
    "exhaust": ("Даунпайп, кат, глушник; після заміни — прошивка", "Downpipe, cat, silencer; remap after the pipe", "Даунпайп, кат, глушитель; после замены — прошивка"),
    "hydro": ("Гідродрук пластику, кришок і дисків у ванні", "Hydro dip for plastic, covers and wheels", "Гидропечать пластика, крышек и дисков в ванне"),
    "carbon": ("Real carbon або плівка: капот, спойлер, накладки", "Real carbon or film: hood, spoiler, overlays", "Real carbon или пленка: капот, спойлер, накладки"),
    "wrap": ("Повна або зональна оклейка, підготовка глиною", "Full or zone wrap, clay prep", "Полная или зональная оклейка, подготовка глиной"),
    "glass": ("Скол, лобове, тонування за нормами, ADAS після скла", "Chip, windscreen, legal tint, ADAS after glass", "Скол, лобовое, тонировка по нормам, ADAS после стекла"),
    "interior": ("Шкіра, Alcantara, кермо, стеля — матеріал під зиму", "Leather, Alcantara, wheel, headliner — winter-grade hide", "Кожа, Alcantara, руль, потолок — материал под зиму"),
    "ac": ("Вакуум, течешукач, заправка R134a / R1234yf за вагою", "Vacuum, leak hunt, R134a / R1234yf by weight", "Вакуум, течеискатель, заправка R134a / R1234yf по весу"),
    "tow": ("Платформа, AWD без прокрутки, прикурювання, кільцева", "Flatbed, AWD without spinning, jump, ring road", "Платформа, AWD без прокрутки, прикуривание, кольцевая"),
    "service": ("Олива за VIN, фільтри, антифриз, свічки за пробігом", "Oil by VIN, filters, coolant, plugs by mileage", "Масло по VIN, фильтры, антифриз, свечи по пробегу"),
    "body": ("Рихтовка, стапель, зварювання, геометрія після удару", "Panel beat, jig, weld, post-crash geometry", "Рихтовка, стапель, сварка, геометрия после удара"),
    "pdr": ("Вмʼятини гачками без фарбу, якщо лак цілий", "Paintless dents with hooks if the clear coat is intact", "Вмятины крючками без покраски, если лак целый"),
    "welding": ("MIG пороги й чашки, TIG алюміній і пластик бампера", "MIG sills and towers, TIG aluminium and bumper plastic", "MIG пороги и чашки, TIG алюминий и пластик бампера"),
    "bumper": ("Тріщини, скоби, кріплення, пайка пластику під фарбу", "Cracks, brackets, mounts, plastic weld for paint", "Трещины, скобы, крепления, пайка пластика под краску"),
    "anticor": ("Мийка днища, мастика порогів і арок, антигравій", "Underbody wash, sill and arch mastic, stone-chip", "Мойка днища, мастика порогов и арок, антигравий"),
    "ppf": ("Поліуретан на капот, бампер, пороги, дзеркала", "Polyurethane on hood, bumper, sills, mirrors", "Полиуретан на капот, бампер, пороги, зеркала"),
    "ceramic": ("Багатоступеневе полірування і шар кераміки/кварцу", "Multi-stage polish and a ceramic/quartz layer", "Многоступенчатая полировка и слой керамики/кварца"),
    "chem-clean": ("Екстракція сидінь, килимів і стелі, без різкого запаху", "Seat, carpet and headliner extraction, no harsh smell", "Экстракция сидений, ковров и потолка, без резкого запаха"),
    "gearbox": ("АКПП / DSG / CVT: олива, мехатронік, стенд, адаптації", "AT / DSG / CVT: fluid, mechatronic, bench, adaptations", "АКПП / DSG / CVT: масло, мехатроник, стенд, адаптации"),
    "clutch": ("Диск, кошик, витискний, двомасовий маховик", "Disc, cover, release bearing, dual-mass flywheel", "Диск, корзина, выжимной, двухмассовый маховик"),
    "steering": ("Рейка, насос ГУР, електрорейка, розвал після ремонту", "Rack, PAS pump, electric rack, alignment after", "Рейка, насос ГУР, электрорейка, развал после ремонта"),
    "turbo": ("Люфт вала, картридж, актуатор, причина оливи в інтеркулері", "Shaft play, cartridge, actuator, oil in the intercooler", "Люфт вала, картридж, актуатор, масло в интеркулере"),
    "injectors": ("Стенд форсунок, рамка, ТНВД, тиск паливної", "Injector bench, rail, high-pressure pump, fuel pressure", "Стенд форсунок, рампа, ТНВД, давление топливной"),
    "radiator": ("Радіатор, помпа, патрубки, термостат, антифриз за типом", "Radiator, pump, hoses, thermostat, coolant by spec", "Радиатор, помпа, патрубки, термостат, антифриз по типу"),
    "dpf": ("Сажовий, EGR, AdBlue: регенерація, промивка, заміна", "DPF, EGR, AdBlue: regen, clean, replace", "Сажевый, EGR, AdBlue: регенерация, промывка, замена"),
    "starter": ("Не крутить / не заряджає: щітки, бендікс, діодний міст", "No crank / no charge: brushes, bendix, rectifier", "Не крутит / не заряжает: щетки, бендикс, диодный мост"),
    "alarm": ("StarLine / Pandora, обхідчик, CAN, штатний іммобілайзер", "StarLine / Pandora, bypass, CAN, factory immobiliser", "StarLine / Pandora, обходчик, CAN, штатный иммобилайзер"),
    "keys": ("Чіп-ключ, прописка, личинка дверей, замок запалювання", "Transponder, pairing, door barrel, ignition lock", "Чип-ключ, прописка, личинка дверей, замок зажигания"),
    "lights": ("Бі-LED, лінзи, реставрація скла, привʼязка фар", "Bi-LED, projectors, lens restore, lamp pairing", "Би-LED, линзы, реставрация стекла, привязка фар"),
    "sound": ("Магнітола, динаміки, саб, підсилювач, силовий кабель", "Head unit, speakers, sub, amp, power cable", "Магнитола, динамики, саб, усилитель, силовой кабель"),
    "soundproof": ("STP на двері, підлогу, арки і дах, кілька шарів", "STP on doors, floor, arches and roof, several layers", "STP на двери, пол, арки и крышу, несколько слоёв"),
    "prebuy": ("Підйомник, товщиномір, сканер блоків, звірка пробігу", "Lift, paint meter, module scan, mileage check", "Подъёмник, толщиномер, сканер блоков, сверка пробега"),
    "rims": ("Правка литва, аргон тріщин, порошкове фарбування", "Cast true, TIG cracks, powder coat", "Правка литья, аргон трещин, порошковая покраска"),
    "lpg": ("ГБО 4 покоління: редуктор, форсунки, балон, сервіс", "LPG 4th gen: reducer, injectors, tank, service", "ГБО 4 поколения: редуктор, форсунки, баллон, сервис"),
    "mobile": ("Виїзд: прикурити, запаска, сканер на місці", "Call-out: jump, spare, on-site scan", "Выезд: прикурить, запаска, сканер на месте"),
    "adas": ("Калібрування камер і радарів після скла або ходової", "Camera and radar calibration after glass or chassis", "Калибровка камер и радаров после стекла или ходовой"),
    "android": ("CarPlay / Android Auto, рамка, камера заднього виду", "CarPlay / Android Auto, fascia, reversing camera", "CarPlay / Android Auto, рамка, камера заднего вида"),
    "srs": ("Індикатор подушки, шлейф керма, блок після ДТП", "Airbag light, clock spring, module after a crash", "Индикатор подушки, шлейф руля, блок после ДТП"),
    "cvjoint": ("Хрускіт у повороті, пильовик, граната, піввісь", "Click on lock, boot, CV joint, half-shaft", "Хруст в повороте, пыльник, граната, полуось"),
}


def esc(value: str) -> str:
    return value.replace('\\', '\\\\').replace("'", "\\'")


def dart_l(triple: tuple[str, str, str]) -> str:
    uk, en, ru = triple
    return f"L(\n      '{esc(uk)}',\n      '{esc(en)}',\n      '{esc(ru)}',\n    )"


def process(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    for sid, triple in DETAILS.items():
        marker = f"id: '{sid}',"
        if marker not in text:
            continue
        start = text.index(marker)
        sub_key = "subtitle: L("
        sub_at = text.index(sub_key, start)
        price_key = "priceHint: L("
        price_at = text.index(price_key, sub_at)
        new_sub = f"subtitle: {dart_l(SUB[sid])},"
        new_detail = f"detail: {dart_l(triple)},"
        new_price = f"priceHint: {dart_l(PRICE[sid])},"
        # find end of current priceHint L( ... ),
        # We replace from subtitle through priceHint block.
        # Find closing of priceHint: after price_at, find "),\n"
        # priceHint is L( three strings )
        rest = text[price_at:]
        # end of priceHint call: first "),\n    keywords"
        end_rel = rest.index("keywords:")
        chunk_end = price_at + end_rel
        text = text[:sub_at] + new_sub + "\n    " + new_detail + "\n    " + new_price + "\n    " + text[chunk_end:]
    path.write_text(text, encoding="utf-8")
    present = [sid for sid in DETAILS if f"id: '{sid}'," in path.read_text(encoding="utf-8")]
    print(f"{path.name}: updated {len(present)} spheres")


def main() -> None:
    process(ROOT / "lib" / "data" / "auto_spheres.dart")
    process(ROOT / "lib" / "data" / "auto_spheres_extra.dart")
    leftover = set(DETAILS) 
    # verify all present across both
    both = (ROOT / "lib" / "data" / "auto_spheres.dart").read_text(encoding="utf-8") + (
        ROOT / "lib" / "data" / "auto_spheres_extra.dart"
    ).read_text(encoding="utf-8")
    absent = [sid for sid in DETAILS if f"id: '{sid}'," not in both]
    if absent:
        raise SystemExit(f"Spheres not in files: {absent}")
    print("ok")


if __name__ == "__main__":
    main()
