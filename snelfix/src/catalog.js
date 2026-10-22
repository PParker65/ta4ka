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

export { SERVICES, SECTIONS } from "./price-catalog.js";

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
