# Autoservice — техническое задание v1.0

**Продукт:** гибрид записи на ремонт (замена мастера-приёмщика) и медиа-ленты автоконтента.  
**Репозиторий клиента:** существующий Flutter-пакет `autoservice` (`lib/`).  
**Валюта:** только UAH (`₴`).  
**Языки UI:** UK / EN / RU (уже есть `AppStrings`).  
**Часовой пояс слотов:** `Europe/Kyiv`.  
**Дата фиксации:** 2026-08-17.

Документ — единственный источник правды для кода. Если фича не описана здесь, её **не делают** в текущем бюджете.

---

## 0. Цель и границы

### 0.1 Что строим

Клиент за 30–60 секунд говорит «что не так» и «что хочет», указывает **номер / марка / модель / год**, видит **свободное окно конкретного мастера**, записывается. СТО обязано снимать ремонт. Лента публичная. Диалог клиент↔СТО по заказу виден всем, писать в него могут только участники заказа. Зрители обсуждают в **отдельной** ветке.

### 0.2 Не делаем в v1 (явный стоп-бюджет)

| Запрещено в v1 | Почему |
|---|---|
| Оплата (LiqPay / карта / подписка) | Только отображение цены в ₴, расчёт на кассе СТО |
| Live RTMP / HLS-трансляция | Только загруженные клипы ≤ 60 с |
| Личные сообщения, сторис, дуэты | Нет |
| Алгоритм TikTok (ML) | Лента: свежесть + вес рейтинга СТО, формула фиксирована |
| Маркетплейс запчастей, эвакуатор как биржа | SOS — только флаг заказа и приоритет слота |
| Гео-поиск «все СТО на карте» | Список СТО + фильтр города, без карты |
| Смена роли client→shop в одном аккаунте | Два отдельных signup |
| Админ-модерация контента как отдельный кабинет | Жалоба `report` пишется в БД, разбор вручную |
| WebSocket | HTTP + poll 5 с на открытом треде ремонта |
| FFI sqlite как source of truth в проде | SQLite только offline-кэш; правда на PostgreSQL |

### 0.3 Что уже есть в репо (не переписывать с нуля)

Использовать и расширять:

- Роутинг `go_router`, состояние `flutter_riverpod`, HTTP-заготовка `ApiClient` (Dio).
- Клиентский интейк: симптомы / желание / номер-марка-модель-год (`ClientIntakeScreen`).
- Каталог работ и цен Basic/Standard/Premium, подсказки «Олег».
- Инспекция кузова `BodyZone` + `DefectKind`, фото.
- Цех: боксы, мастера, статусы.
- Оценка 1–5 (расширить до 4 факторов).

Локальный `MemoryCrmStore` / `SqliteCrmStore` остаются **dev-фолбэком**, если `API_BASE_URL` не задан.

---

## 1. Стек (заморозка)

| Слой | Выбор | Запрещённые альтернативы в v1 |
|---|---|---|
| Мобильное / web | Flutter SDK ≥ 3.5, Dart ≥ 3.5 | React Native, отдельное нативное iOS/Android |
| Состояние | Riverpod 2.x | Bloc, GetX |
| Навигация | go_router | auto_route |
| Backend | **FastAPI** (Python 3.12), один сервис | микросервисы, Nest, Firebase как БД |
| БД | PostgreSQL 16 | Mongo, SQLite в проде |
| Кэш / очереди | Redis 7: сессии refresh, rate-limit, очередь транскода | Kafka |
| Файлы | S3-совместимое (MinIO dev / Hetzner-S3 prod), бакет `autoservice-media` | хранение blob в Postgres |
| Транскод | worker: FFmpeg, выход H.264 + AAC, max 1080p, 8 Mbps | облачный SaaS транскода |
| Auth | JWT access 15 мин, refresh 30 дней, httpOnly на web не требуется (mobile secure storage) | OAuth соцсетей в v1 |
| Деплой | один VPS: Caddy + API + worker + Postgres + Redis + MinIO | Kubernetes |

Конфиг клиента:

```
--dart-define=API_BASE_URL=https://api.example.com
```

Базовый префикс API: `https://{host}/v1`.

---

## 2. Визуальный стиль и UI/UX

### 2.1 Общие правила

- Крупные CTA, минимум полей, чипы вместо длинных форм.
- Клиент **никогда** не видит VIN, пробег, нормо-часы как обязательные поля. VIN/пробег — только панель СТО при приёмке.
- Один главный экшен на экран. Ошибки — SnackBar + текст поля.
- Контраст WCAG AA. Размер тапа ≥ 44 px.
- Шрифт: системный (не подключать платный BMW-like). Заголовки `w800`, letter-spacing −0.3.

### 2.2 Темы (гендерный переключатель)

Хранится в `users.theme`: `guy` | `girl`. Переключатель на экране профиля и в AppBar ленты (иконка палитры). Не спрашивать пол. Подписи:

| Ключ | UK | EN | RU |
|---|---|---|---|
| themeGuy | Тема для хлопців | Guy theme | Тема для парней |
| themeGirl | Тема для дівчат | Girl theme | Тема для девушек |

**Токены `guy` (default после первого запуска, если не выбрано):**

| Токен | Hex | Назначение |
|---|---|---|
| bg | `#0E0F12` | scaffold |
| surface | `#16181D` | карточки |
| carbon | `#1E2229` | инпуты |
| stroke | `#2A3038` | линии |
| text | `#F4F1EA` | основной |
| muted | `#8B928A` | вторичный |
| accent | `#C9A227` | янтарь (уже в теме) |
| danger | `#E24B4A` | SOS / ошибка |

**Токены `girl`:**

| Токен | Hex | Назначение |
|---|---|---|
| bg | `#FBF4F6` | scaffold |
| surface | `#FFFFFF` | карточки |
| blush | `#F3D5DE` | чипы, фон CTA ghost |
| stroke | `#E7C9D2` | линии |
| text | `#2B1E24` | основной |
| muted | `#7A5E68` | вторичный |
| accent | `#C45C7A` | розовый акцент |
| danger | `#C62828` | SOS |

Реализация: `ThemeController` + два `ThemeData` в `lib/app/theme.dart`. Не плодить третью «песочную» тему в проде; текущая sand-green — **legacy shop light**, мапится на `girl` до выпила.

### 2.3 Простота «застрял на трассе»

На клиентском интейке чип симптома `roadside` («Сломался на трассе») ставит `jobs.is_emergency = true`. UI: красный баннер «Вас примут вне очереди в ближайшее окно». Город — одно поле (не адрес дома). Телефон обязателен.

---

## 3. Роли и авторизация

### 3.1 Роли

| `users.role` | Куда попадает после логина | Может |
|---|---|---|
| `client` | `/home` (лента + таб «Запись») | запись, свой тред ремонта, комментарии к постам, оценка после `completed` |
| `shop_admin` | `/staff` | всё СТО: слоты, приёмка, медиа, мастера, боксы |
| `master` | `/staff/bay` | свои слоты, статус бокса, загрузка фото/видео, сообщения в тред своих заказов |
| `guest` | нет JWT; только `/` логин + публичная лента preview 10 постов | скролл превью, запись запрещена |

Один пользователь — одна роль. СТО-сотрудник не логинится клиентским флоу.

### 3.2 Экран входа (обязательный UX)

Маршрут `/`.

1. Приветствие: «Добро пожаловать» + если `display_name` уже известен после повторного входа — «Добро пожаловать, {display_name}».
2. Поля: логин (email **или** телефон E.164) + пароль.
3. Кнопки: «Войти», «Регистрация».
4. Регистрация по умолчанию создаёт `role=client`.
5. Правый нижний угол (не конкурирует с CTA): текст 12 px, opacity 0.6 — «Вход / Регистрация для автосервисов» → `/auth/shop`.
6. После успешного client login → `/home`. После shop/master → `/staff`.

Пароль: min 8, max 128. Хэш: Argon2id. Неверный логин: одно сообщение «Неверный логин или пароль» (без утечки, существует ли аккаунт). Rate limit: 10 попыток / 15 мин / IP+login.

Регистрация СТО (`POST /v1/auth/register-shop`): поля shop_name, city, phone, email, password, display_name. Статус шопа `pending` → в v1 **авто-approve** `active` (флаг `AUTO_APPROVE_SHOPS=true`). Юр. документы — не собирать.

### 3.3 JWT claims

```json
{
  "sub": "user-uuid",
  "role": "client",
  "shop_id": null,
  "ver": 1
}
```

Для `shop_admin` / `master` `shop_id` обязателен. `ver` инкрементится при смене пароля → все refresh инвалидируются.

Заголовок: `Authorization: Bearer <access>`. Refresh: `POST /v1/auth/refresh` body `{ "refresh_token": "..." }`.

---

## 4. Доменные инварианты (бизнес-правила)

1. Клиентские поля заказа: **plate, brand, model, year** (+ опционально phone если не в профиле). VIN/mileage только в инспекции СТО.
2. Запись возможна только на слот со статусом `open`. После брони слот → `booked`, уникальность `(master_id, starts_at)` среди не-`cancelled`.
3. Слот 30 минут. Рабочий день СТО: `shops.open_minutes`–`shops.close_minutes` (default 480–1200, т.е. 08:00–20:00).
4. Emergency: ближайший `open` слот любого мастера нужной specialty **сегодня**, иначе первый завтра. Помечается `priority=emergency`.
5. Переход `job.status → in_progress` запрещён, если нет подписанной инспекции **или** нет ≥1 media `kind=photo` с `tag=before`.
6. Переход `→ ready` запрещён без ≥1 media `tag=process` **и** ≥1 `tag=after`.
7. Тред ремонта (`thread_type=repair`): писать могут `job.client_id`, `shop_admin` этого шопа, `master` с `job.master_id`. Читать — любой авторизованный и guest.
8. Комментарии к посту (`thread_type=flood`): писать любой `client|shop_admin|master`. Нельзя писать в repair-тред.
9. Оценка: один `ratings` на `(job_id, client_id)` после `completed`. 4 фактора 1–5, все обязательны.
10. Публичный рейтинг шопа = среднее арифметическое всех факторов всех оценок за 180 дней, округление 1 знак. Пересчёт job’ом после INSERT rating.
11. Удаление аккаунта: soft `users.deleted_at`; контент шопа остаётся, авторство «Удаленный пользователь».

Статус заказа (канон, заменить старые 4):

```
draft → booked → checked_in → in_progress → awaiting_approval → ready → completed
                                                      ↘ cancelled
booked → no_show (если не checked_in через 30 мин после starts_at, кнопка СТО)
```

`draft` живёт только на клиенте до `POST /jobs`. На сервер уходит сразу `booked`.

---

## 5. Каталог проблем и работ

Не свободный текст как единственный путь. Клиент тыкает чипы, опционально 1 поле «уточнение» ≤ 280 символов.

### 5.1 Симптомы (`symptom_id`)

| id | Специализация слота | Emergency |
|---|---|---|
| noise | chassis | no |
| brakes | chassis | no |
| electrics | electrician | no |
| engine | motorist | no |
| to | maintenance | no |
| unknown | electrician (диагностика) | no |
| headlight_pair | electrician | no |
| underbody_cover | chassis | no |
| ecu_flash | electrician | no |
| roadside | electrician | **yes** |

Маппинг на работу (как сейчас в `ClientIntakeScreen._workIdFor`, расширить):

| want + symptom | catalog `work.id` |
|---|---|
| diag + brakes/noise | diag-chassis |
| diag + * | diag-comp |
| to + * | oil |
| coding + * | coding |
| repair + brakes | pads |
| repair + engine | plugs |
| repair + electrics | battery |
| repair + noise | align |
| repair + headlight_pair | coding |
| repair + underbody_cover | align |
| repair + ecu_flash | coding |
| * + roadside | diag-comp |
| * + unknown | diag-comp |

`want_id`: `diag` | `repair` | `to` | `coding`.

Цены: существующие `price_basic/standard/premium` в каталоге, override на шоп в `shop_prices`.

---

## 6. Data schema (PostgreSQL)

Типы: `uuid` PK default `gen_random_uuid()`, `timestamptz` not null default `now()`, суммы `integer` в **копейках** (1400 ₴ = `140000`). Клиент Flutter сегодня хранит гривны int — **на границе API** отдавать `price_uah` int гривны, в БД копейки. Это единственная конвертация.

### 6.1 Таблицы

```sql
CREATE TABLE users (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  role          text NOT NULL CHECK (role IN ('client','shop_admin','master')),
  email         citext UNIQUE,
  phone         text UNIQUE,              -- E.164, напр. +380501234567
  password_hash text NOT NULL,
  display_name  text NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 80),
  theme         text NOT NULL DEFAULT 'guy' CHECK (theme IN ('guy','girl')),
  lang          text NOT NULL DEFAULT 'uk' CHECK (lang IN ('uk','en','ru')),
  shop_id       uuid REFERENCES shops(id),
  token_ver     int  NOT NULL DEFAULT 1,
  created_at    timestamptz NOT NULL DEFAULT now(),
  deleted_at    timestamptz,
  CHECK (email IS NOT NULL OR phone IS NOT NULL),
  CHECK (
    (role = 'client' AND shop_id IS NULL) OR
    (role IN ('shop_admin','master') AND shop_id IS NOT NULL)
  )
);

CREATE TABLE shops (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text NOT NULL,
  city           text NOT NULL,
  phone          text NOT NULL,
  status         text NOT NULL DEFAULT 'active' CHECK (status IN ('pending','active','blocked')),
  open_minutes   int  NOT NULL DEFAULT 480,
  close_minutes  int  NOT NULL DEFAULT 1200,
  rating_avg     numeric(2,1) NOT NULL DEFAULT 0,
  rating_count   int NOT NULL DEFAULT 0,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE masters (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id     uuid NOT NULL REFERENCES shops(id),
  user_id     uuid REFERENCES users(id),
  name        text NOT NULL,
  specialty   text NOT NULL CHECK (specialty IN ('electrician','motorist','chassis','maintenance')),
  is_open     boolean NOT NULL DEFAULT true,  -- «Свободен / готов принять»
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE boxes (
  id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id  uuid NOT NULL REFERENCES shops(id),
  name     text NOT NULL,
  UNIQUE (shop_id, name)
);

CREATE TABLE catalog_works (
  id              text PRIMARY KEY,          -- 'pads', 'diag-comp', ...
  category        text NOT NULL,
  specialty       text NOT NULL,
  minutes         int  NOT NULL,
  price_basic     int  NOT NULL,             -- копейки
  price_standard  int  NOT NULL,
  price_premium   int  NOT NULL
);

CREATE TABLE shop_prices (
  shop_id   uuid NOT NULL REFERENCES shops(id),
  work_id   text NOT NULL REFERENCES catalog_works(id),
  tier      text NOT NULL CHECK (tier IN ('basic','standard','premium')),
  price     int  NOT NULL,
  PRIMARY KEY (shop_id, work_id, tier)
);

CREATE TABLE slots (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id     uuid NOT NULL REFERENCES shops(id),
  master_id   uuid NOT NULL REFERENCES masters(id),
  starts_at   timestamptz NOT NULL,
  ends_at     timestamptz NOT NULL,
  status      text NOT NULL CHECK (status IN ('open','booked','blocked')),
  UNIQUE (master_id, starts_at)
);

CREATE TABLE jobs (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id        uuid NOT NULL REFERENCES shops(id),
  client_id      uuid NOT NULL REFERENCES users(id),
  master_id      uuid REFERENCES masters(id),
  box_id         uuid REFERENCES boxes(id),
  slot_id        uuid UNIQUE REFERENCES slots(id),
  plate          text NOT NULL,
  brand          text NOT NULL,
  model          text NOT NULL,
  year           int  NOT NULL CHECK (year BETWEEN 1980 AND 2030),
  vin            text NOT NULL DEFAULT '',
  mileage_km     int  NOT NULL DEFAULT 0,
  symptom_id     text NOT NULL,
  want_id        text NOT NULL,
  note           text NOT NULL DEFAULT '',
  work_id        text NOT NULL REFERENCES catalog_works(id),
  tier           text NOT NULL CHECK (tier IN ('basic','standard','premium')),
  price_uah      int  NOT NULL,              -- гривны, как отдаём в UI
  minutes        int  NOT NULL,
  status         text NOT NULL,
  is_emergency   boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE inspections (
  job_id         uuid PRIMARY KEY REFERENCES jobs(id),
  mileage_km     int,
  fuel_eighths   int NOT NULL DEFAULT 4 CHECK (fuel_eighths BETWEEN 0 AND 8),
  zone_defects   jsonb NOT NULL DEFAULT '{}',  -- {"frontBumper":["scratch"]}
  signed_at      timestamptz,
  signed_by      uuid REFERENCES users(id)
);

CREATE TABLE media (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id      uuid NOT NULL REFERENCES shops(id),
  job_id       uuid REFERENCES jobs(id),
  author_id    uuid NOT NULL REFERENCES users(id),
  kind         text NOT NULL CHECK (kind IN ('photo','video')),
  tag          text NOT NULL CHECK (tag IN ('before','process','after','inspect')),
  s3_key       text NOT NULL,
  duration_ms  int,
  width        int,
  height       int,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE posts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_id     uuid NOT NULL REFERENCES shops(id),
  job_id      uuid REFERENCES jobs(id),
  media_id    uuid NOT NULL REFERENCES media(id),
  caption     text NOT NULL DEFAULT '',
  visibility  text NOT NULL DEFAULT 'public' CHECK (visibility IN ('public','shop_only')),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE messages (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id       uuid REFERENCES jobs(id),     -- NOT NULL для repair
  post_id      uuid REFERENCES posts(id),    -- NOT NULL для flood
  thread_type  text NOT NULL CHECK (thread_type IN ('repair','flood')),
  author_id    uuid NOT NULL REFERENCES users(id),
  body         text NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
  media_id     uuid REFERENCES media(id),
  created_at   timestamptz NOT NULL DEFAULT now(),
  CHECK (
    (thread_type = 'repair' AND job_id IS NOT NULL AND post_id IS NULL) OR
    (thread_type = 'flood'  AND post_id IS NOT NULL AND job_id IS NULL)
  )
);

CREATE TABLE ratings (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id        uuid NOT NULL REFERENCES jobs(id),
  client_id     uuid NOT NULL REFERENCES users(id),
  shop_id       uuid NOT NULL REFERENCES shops(id),
  master_id     uuid REFERENCES masters(id),
  quality       int NOT NULL CHECK (quality BETWEEN 1 AND 5),
  politeness    int NOT NULL CHECK (politeness BETWEEN 1 AND 5),
  punctuality   int NOT NULL CHECK (punctuality BETWEEN 1 AND 5),
  cleanliness   int NOT NULL CHECK (cleanliness BETWEEN 1 AND 5),
  comment       text NOT NULL DEFAULT '',
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (job_id, client_id)
);

CREATE TABLE reports (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id  uuid NOT NULL REFERENCES users(id),
  target_type  text NOT NULL CHECK (target_type IN ('message','post','user')),
  target_id    uuid NOT NULL,
  reason       text NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id),
  token_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz
);
```

Индексы:

```sql
CREATE INDEX idx_slots_shop_open ON slots (shop_id, starts_at) WHERE status = 'open';
CREATE INDEX idx_jobs_shop_status ON jobs (shop_id, status);
CREATE INDEX idx_jobs_client ON jobs (client_id, created_at DESC);
CREATE INDEX idx_posts_created ON posts (created_at DESC) WHERE visibility = 'public';
CREATE INDEX idx_messages_repair ON messages (job_id, created_at) WHERE thread_type = 'repair';
CREATE INDEX idx_messages_flood ON messages (post_id, created_at) WHERE thread_type = 'flood';
CREATE INDEX idx_media_job ON media (job_id, created_at);
```

Локализованные названия работ/мастеров **не** в Postgres в v1: остаются в Flutter `catalog_seed.dart` / `L`. Сервер отдаёт `work_id`; клиент рендерит `L`.

### 6.2 Объект media в S3

Ключ: `{shop_id}/{job_id}/{media_id}.{jpg|mp4}`.  
Загрузка: клиент получает presigned PUT (5 мин), затем `POST /media/complete`.  
Лимиты: photo ≤ 8 MB JPEG/HEIC; video ≤ 80 MB, ≤ 60 с, mp4/mov. Worker отклоняет иное.

---

## 7. API

Общий формат ошибки:

```json
{ "error": { "code": "SLOT_TAKEN", "message": "..." } }
```

Коды: `UNAUTHENTICATED`, `FORBIDDEN`, `VALIDATION`, `NOT_FOUND`, `SLOT_TAKEN`, `JOB_RULE`, `RATE_LIMIT`.

Пагинация: `?cursor=<opaque>&limit=20` (max 50). Ответ: `{ "items": [], "next_cursor": null }`.

### 7.1 Auth

| Метод | Путь | Роль | Body / query | 200 |
|---|---|---|---|---|
| POST | `/v1/auth/register` | public | `{email?, phone?, password, display_name}` | `{user, access_token, refresh_token}` |
| POST | `/v1/auth/register-shop` | public | `{email, phone, password, display_name, shop_name, city}` | то же + `shop` |
| POST | `/v1/auth/login` | public | `{login, password}` login = email или phone | то же |
| POST | `/v1/auth/refresh` | public | `{refresh_token}` | токены |
| POST | `/v1/auth/logout` | auth | `{refresh_token}` | `{ok:true}` |
| GET | `/v1/me` | auth | — | user + shop? |
| PATCH | `/v1/me` | auth | `{display_name?, theme?, lang?}` | user |

### 7.2 Слоты и запись

| Метод | Путь | Роль | Назначение |
|---|---|---|---|
| GET | `/v1/shops?city=` | auth/guest | список СТО: name, city, rating_avg, rating_count |
| GET | `/v1/shops/{id}` | auth/guest | карточка СТО |
| GET | `/v1/shops/{id}/slots?from&to&specialty&emergency=` | auth | свободные окна. Ответ элемент: `{id, master_id, master_name, specialty, starts_at, ends_at}` текст UI: «Мастер {name}, {specialty_l10n} — свободен {human_dt}» |
| POST | `/v1/jobs` | client | создать бронь. Body ниже. 409 `SLOT_TAKEN` |
| GET | `/v1/jobs` | client: свои; shop: шопа | список |
| GET | `/v1/jobs/{id}` | auth; guest если есть public posts | детали + inspection + media |
| POST | `/v1/jobs/{id}/cancel` | client или shop_admin | только `booked`/`draft` |

`POST /v1/jobs` body:

```json
{
  "shop_id": "uuid",
  "slot_id": "uuid",
  "plate": "AA1234BB",
  "brand": "BMW",
  "model": "M2",
  "year": 2018,
  "symptom_id": "brakes",
  "want_id": "repair",
  "tier": "standard",
  "note": ""
}
```

Сервер сам ставит `work_id`, `price_uah`, `minutes`, `master_id` из слота, `is_emergency` из symptom.

### 7.3 СТО: приёмка и статусы

| Метод | Путь | Роль |
|---|---|---|
| PATCH | `/v1/masters/{id}` | shop_admin, или master себя `{is_open}` |
| POST | `/v1/shops/{id}/slots/generate` | shop_admin body `{date: "YYYY-MM-DD"}` — нарезка 30-мин open слотов для `is_open` мастеров |
| PATCH | `/v1/jobs/{id}/status` | shop_admin/master `{status}` с проверкой правил §4 |
| PUT | `/v1/jobs/{id}/inspection` | shop_admin/master body mileage, fuel_eighths, zone_defects, signed |
| POST | `/v1/jobs/{id}/assign` | shop_admin `{master_id, box_id}` |

### 7.4 Медиа и лента

| Метод | Путь | Роль |
|---|---|---|
| POST | `/v1/media/sign` | shop_admin/master `{job_id, kind, tag, mime}` → `{upload_url, media_id, s3_key}` |
| POST | `/v1/media/complete` | shop_admin/master `{media_id}` — проверка объекта, для video enqueue transcode |
| POST | `/v1/posts` | shop_admin/master `{media_id, caption}` visibility default public |
| GET | `/v1/feed?cursor` | guest/auth | посты newest, score = created_at − 3h * (5−rating_avg)/4 |
| GET | `/v1/posts/{id}` | guest/auth | пост + media url (presigned GET 10 мин) |

### 7.5 Треды (критичные ACL)

| Метод | Путь | Кто пишет | Кто читает |
|---|---|---|---|
| GET | `/v1/jobs/{id}/thread?cursor` | — | **все** (guest тоже) |
| POST | `/v1/jobs/{id}/thread` | **только** client заказа, shop_admin шопа, assigned master. Body `{body, media_id?}` | — |
| GET | `/v1/posts/{id}/comments?cursor` | — | все |
| POST | `/v1/posts/{id}/comments` | любой auth | — |
| POST | `/v1/reports` | auth | `{target_type, target_id, reason}` |

`POST .../thread` от постороннего → **403 FORBIDDEN** (не 404). Клиент UI не показывает input зрителям.

### 7.6 Рейтинг

| Метод | Путь |
|---|---|
| POST | `/v1/jobs/{id}/rating` client, job.status=`completed`, body `{quality, politeness, punctuality, cleanliness, comment}` |
| GET | `/v1/shops/{id}/ratings` публичные отзывы |

---

## 8. Экраны и маршруты Flutter

Существующие пути сохранить, где возможно.

| Route | Файл (цель) | Роль | Виджеты / поля |
|---|---|---|---|
| `/` | `login_screen.dart` | guest | login, password, Войти, Регистрация, мелкий CTA СТО bottom-right |
| `/auth/register` | новый | guest | display_name, login, password |
| `/auth/shop` | новый | guest | регистрация/вход СТО |
| `/home` | новый shell | client | BottomNav: Лента / Запись / Мои заказы / Профиль |
| `/home/feed` | новый | client/guest | вертикальный PageView.builder клипов (Reels). Тап → пост. Кнопка «Запись» |
| `/home/book` | расширить `client_intake_screen.dart` | client | симптомы, want, 4 поля авто, выбор СТО, список слотов, tier, Submit |
| `/home/jobs` | новый | client | список заказов + статус |
| `/home/jobs/:id` | новый | все | карточка авто, таймлайн статуса, **публичный тред** (input только участникам), ссылка на flood поста |
| `/home/jobs/:id/rate` | расширить rating | client | 4 слайдера 1–5 + комментарий |
| `/home/profile` | новый | client | имя, тема guy/girl, язык, выход |
| `/staff` | `home_screen.dart` | shop | дашборд |
| `/staff/slots` | новый | shop | генерация дня, is_open мастеров |
| `/kiosk` | `kiosk_screen.dart` | shop | полный киоск (VIN/пробег можно) |
| `/kiosk/inspection` | `inspection_screen.dart` | shop | акт приёмки |
| `/workshop` | `workshop_screen.dart` | shop | боксы/статусы + кнопка «загрузить фото/видео» |
| `/loyalty` | `loyalty_screen.dart` | shop | отзывы |
| `/staff/capture/:jobId` | новый | master | камера, tag before/process/after, авто-post |

Гостевой просмотр ленты: `/` имеет ссылку «Смотреть работы» → `/home/feed` без JWT, CTA «Войти чтобы записаться».

Копирайт слота на UI (обязательная строка):

`Мастер {name}, {specialtyLabel} — свободен {EEE d MMM, HH:mm}`  
Пример: «Мастер Олег, электрик — свободен завтра в 09:00».

---

## 9. User flow

### 9.1 Клиент: спокойный ремонт

1. `/` → логин/регистрация client.  
2. `/home/book`: чип «что не так» → чип «что хотите» → номер, марка, модель, год.  
3. Список СТО города (из профиля или одно поле city). Выбор СТО.  
4. `GET slots` → карточки мастеров. Выбор окна. Tier цены.  
5. `POST /jobs` → экран «Вас ждут {datetime}, мастер {name}».  
6. Лента: появляются process-клипы этого заказа. Тред ремонта открыт на `/home/jobs/:id`. Клиент пишет уточнения, СТО отвечает фото. Зрители видят, поля ввода нет.  
7. Статус `ready` → клиент забирает авто (факт на стороне СТО: `completed`).  
8. `/home/jobs/:id/rate` — 4 оценки. Попадание в публичные отзывы СТО.

### 9.2 Клиент: трасса

1. Симптом `roadside`, want `diag` или `repair`.  
2. API ставит `is_emergency`, отдаёт ближайший слот.  
3. Экран: телефон подтверждён, кнопка «Позвонить в СТО» (`tel:` на `shops.phone`). Запись всё равно создаётся.

### 9.3 Зритель соцсети

1. Открывает ленту. Скролл клипов «как перебирают мотор».  
2. Тап «обсудить» → flood-комменты поста.  
3. Тап «заказ» → публичный repair-тред **read-only**. Попытка POST → 403.  
4. Хочет записаться → логин если guest.

### 9.4 СТО: приёмка и обязательный контент

1. Вход `/auth/shop`.  
2. Мастер ставит `is_open=true`. Admin жмёт generate slots на дату.  
3. Клиент приехал: `booked → checked_in`. Инспекция кузова + фото `inspect`. Подпись.  
4. `in_progress` только после before-фото.  
5. Из бокса: capture process (фото/видео) → `media/complete` → авто `POST /posts` (caption = work title + plate masked `AA****BB`).  
6. After-фото → `ready`.  
7. Клиент забрал → `completed`.

### 9.5 Хейт / спам

- Repair input скрыт если `me.id` ∉ {client, shop_admin, assigned master}.  
- Flood: max 5 комментов / мин / user, 2000 символов, без URL-shorteners (regex `bit\.ly|t\.me` → 400).  
- Кнопка «Пожаловаться» на сообщение/пост.

---

## 10. Клиентская архитектура (Flutter)

```
lib/
  app/          router, theme guy|girl, providers
  core/         l10n, uah, api_client (+ interceptors JWT)
  data/
    dto/        json_serializable или ручные fromJson
    catalog_seed.dart     без изменений контракта id
    remote_crm_store.dart реализует CrmStore через Dio
    memory_crm_store.dart dev
  domain/       расширить JobStatus, Rating (4 поля), User, Slot, Post, Message
  presentation/
    auth/
    feed/       feed_screen.dart, post_thread_screen.dart
    kiosk/      client_intake + выбор слота
    inspection/
    workshop/
    loyalty/
```

`CrmStore` расширить методами слотов/ленты **или** завести `FeedRepository` / `BookingRepository` рядом — не смешивать SQL и REST в одном классе.

JWT: `flutter_secure_storage`. 401 → refresh → retry 1 раз.

Маскирование номера в ленте: `plate[0:2] + '****' + plate[-2:]`.

---

## 11. Backend-структура (FastAPI)

```
/app
  main.py
  deps.py              get_current_user
  routers/             auth, shops, slots, jobs, media, feed, messages, ratings
  models/              SQLAlchemy 2
  schemas/             Pydantic v2
  services/            booking.py (транзакция SELECT FOR UPDATE слота)
  workers/             transcode.py
```

Бронирование (обязательная транзакция):

```
BEGIN;
SELECT * FROM slots WHERE id=$1 AND status='open' FOR UPDATE;
-- если нет строк → 409 SLOT_TAKEN
INSERT job;
UPDATE slots SET status='booked';
COMMIT;
```

---

## 12. Порядок работ (чтобы не раздуть бюджет)

Делать **строго по фазам**. Следующая фаза не стартует, пока Definition of Done предыдущей закрыт.

### Фаза A — фундамент (существующий клиент + API-контракт)

- Темы guy/girl, приветствие на логине, кнопка СТО bottom-right (уже близко).
- Расширить `Rating` до 4 факторов в UI.
- DTO + Dio CRUD jobs против mock (http mock / local FastAPI).

DoD: `flutter analyze` clean, widget-тест логина зелёный.

### Фаза B — запись

- Postgres + auth + slots generate + POST jobs.  
- Экран выбора слота с копирайтом мастера.  
- Emergency roadside.

DoD: интеграционный тест «два клиента один слот → один 409».

### Фаза C — приёмка СТО

- inspection API, статусы с серверными правилами before/after.  
- capture-экран.

DoD: нельзя `in_progress` без before (тест API).

### Фаза D — медиа-лента и треды

- presign, complete, feed, repair thread ACL, flood comments, reports.  
- Reels PageView.

DoD: тест «посторонний POST repair → 403», «тот же user POST flood → 201».

Оценка трудозатрат (один fullstack + один Flutter, календарно): A 3–4 дн, B 5–7 дн, C 4–5 дн, D 7–10 дн. **Не параллелить D с B.**

---

## 13. Тесты (минимум, обязательно в CI)

1. Widget: логин показывает «Для автосервісів» / shop CTA.  
2. Unit: `_workIdFor` + emergency flag.  
3. API: slot double-book.  
4. API: repair ACL.  
5. API: rating unique per job.  
6. API: status machine rejects `in_progress` without before media.

---

## 14. Приёмка продукта (чеклист заказчика)

- [ ] Логин клиента и отдельный вход СТО, приветствие по имени.  
- [ ] Тема парней / девушек переключается без перезапуска.  
- [ ] Запись: 4 поля авто + чипы + слот «Мастер … свободен …».  
- [ ] SOS-чип даёт ближайшее окно.  
- [ ] Лента скроллится вертикально, клип из ремзоны.  
- [ ] Тред заказа виден гостю, писать гость не может.  
- [ ] Под постом отдельный чат.  
- [ ] Без before-фото мастер не стартует работу.  
- [ ] 4 оценки публичны на карточке СТО.  
- [ ] Цены только ₴.

Конец ТЗ v1.0. Изменения — только новой версией документа, не устными правками.
