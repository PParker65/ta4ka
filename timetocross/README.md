# Time to Cross

Сайт проката кроссовой мототехники и квадроциклов во Вроцлаве. Папка только этого проекта: `timetocrosswroclaw.com`.

Публичная страница: выбрать технику, день и час, оставить имя и телефон. Бронь становится действительной после звонка. Админка: `/admin` — заявки, статистика, телефон, Instagram, Telegram и цены.

Цены по умолчанию с афиши профиля: мото 250 — 150 zł, мото 300 — 200 zł, квадро 250 — 200 zł, квадро 500 — 250 zł. Телефон `+48 793 709 974`, Instagram `@time_to_cross`. Telegram пустой, пока его не сохранят в админке — кнопки на сайте нет.

## Локально

```bash
cd timetocross
cp .dev.vars.example .dev.vars
npm run dev
```

Сайт: http://127.0.0.1:8787  
Админка: http://127.0.0.1:8787/admin  
Локальный вход из `.dev.vars.example`: `admin` / `ttc-wroclaw-dev`

```bash
npm run smoke
```

## Cloudflare

Зона `timetocrosswroclaw.com` должна быть на том же аккаунте. KV только этого сайта, id из другого проекта не подставлять.

```bash
npx wrangler kv namespace create LEADS
```

Вписать `id` в `wrangler.toml`. Потом задать пароль длиннее 10 символов (не локальный):

```bash
npx wrangler secret put ADMIN_PASSWORD
npx wrangler deploy
```

`ADMIN_USER` по умолчанию `admin`. Другой логин: `npx wrangler secret put ADMIN_USER`.

Маршруты воркера: только `timetocrosswroclaw.com` и `www`. `www` уходит на адрес без www.

Шрифты Unbounded и Manrope — SIL Open Font License, тексты лицензий в `public/fonts/`.
