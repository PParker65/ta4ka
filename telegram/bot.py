#!/usr/bin/env python3
"""Apex Telegram bot — full client Mini App, not a FAQ stub.

Env:
  TELEGRAM_BOT_TOKEN      from BotFather /newbot
  TELEGRAM_WEBAPP_URL     HTTPS origin of `flutter build web` (trailing slash ok)
  TELEGRAM_BOT_USERNAME   without @  (optional, for t.me links in replies)

BotFather:
  /newbot
  /newapp  → title Apex, Web App URL = TELEGRAM_WEBAPP_URL
  Menu Button → Open Mini App (same URL)
  Direct link short name `app` → https://t.me/<bot>/app

Run:
  export TELEGRAM_BOT_TOKEN=...
  export TELEGRAM_WEBAPP_URL=https://your-host/
  python3 telegram/bot.py
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def _load_env() -> None:
    path = Path(__file__).resolve().with_name(".env")
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip().strip('"').strip("'")
        os.environ.setdefault(key, val)


_load_env()

TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
WEBAPP = os.environ.get("TELEGRAM_WEBAPP_URL", "").strip().rstrip("/")
BOT_USER = os.environ.get("TELEGRAM_BOT_USERNAME", "chip365auto_bot").strip().lstrip("@")
API = f"https://api.telegram.org/bot{TOKEN}" if TOKEN else ""

COPY = {
    "uk": {
        "hello": (
            "Ta4ka у Telegram — той самий софт: запис, СТО, авто з США, наряди, стрічка.\n"
            "Натисни кнопку нижче і працюй прямо тут."
        ),
    "open": "Відкрити Ta4ka",
        "help": (
            "Команди:\n"
            "/start — відкрити додаток\n"
            "/usa — авто з США\n"
            "/book — мої записи\n"
            "/shops — каталог СТО\n"
            "/help — ця підказка"
        ),
        "need_url": "Mini App ще не підключено: задай TELEGRAM_WEBAPP_URL (https).",
    },
    "ru": {
        "hello": (
            "Ta4ka в Telegram — тот же софт: запись, СТО, авто из США, наряды, лента.\n"
            "Нажми кнопку ниже и работай прямо здесь."
        ),
    "open": "Открыть Ta4ka",
        "help": (
            "Команды:\n"
            "/start — открыть приложение\n"
            "/usa — авто из США\n"
            "/book — мои записи\n"
            "/shops — каталог СТО\n"
            "/help — эта подсказка"
        ),
        "need_url": "Mini App ещё не подключено: задай TELEGRAM_WEBAPP_URL (https).",
    },
    "en": {
        "hello": (
            "Ta4ka in Telegram is the same product: booking, shops, USA cars, work orders, feed.\n"
            "Tap the button below and use it here."
        ),
    "open": "Open Ta4ka",
        "help": (
            "Commands:\n"
            "/start — open the app\n"
            "/usa — cars from USA\n"
            "/book — my bookings\n"
            "/shops — shop catalog\n"
            "/help — this hint"
        ),
        "need_url": "Mini App is not wired yet: set TELEGRAM_WEBAPP_URL (https).",
    },
}


def lang_of(user: dict | None) -> str:
    code = ((user or {}).get("language_code") or "uk").lower()[:2]
    return code if code in COPY else "uk"


def t(user: dict | None, key: str) -> str:
    return COPY[lang_of(user)][key]


def app_url(start: str = "") -> str:
    if not WEBAPP:
        return ""
    if not start:
        return WEBAPP
    return f"{WEBAPP}?start={urllib.parse.quote(start)}"


def keyboard(user: dict | None, start: str = "") -> dict:
    url = app_url(start)
    open_label = t(user, "open")
    if not url:
        return {"remove_keyboard": True}
    return {
        "keyboard": [[{"text": open_label, "web_app": {"url": url}}]],
        "resize_keyboard": True,
        "is_persistent": True,
    }


def inline(user: dict | None, start: str = "") -> dict | None:
    url = app_url(start)
    if not url:
        return None
    rows = [
        [{"text": t(user, "open"), "web_app": {"url": url}}],
        [
            {"text": "USA", "web_app": {"url": app_url("usa")}},
            {"text": "СТО", "web_app": {"url": app_url("shops")}},
            {"text": "Запис", "web_app": {"url": app_url("book")}},
        ],
    ]
    return {"inline_keyboard": rows}


def api(method: str, payload: dict) -> dict:
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f"{API}/{method}",
        data=data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=40) as res:
        return json.loads(res.read().decode())


def send(chat_id: int, text: str, user: dict | None, start: str = "") -> None:
    body: dict = {
        "chat_id": chat_id,
        "text": text,
    }
    extra = inline(user, start)
    if extra:
        body["reply_markup"] = extra
    else:
        body["reply_markup"] = keyboard(user, start)
    api("sendMessage", body)


def handle(update: dict) -> None:
    msg = update.get("message") or update.get("edited_message")
    if not msg:
        return
    chat_id = msg["chat"]["id"]
    user = msg.get("from")
    text = (msg.get("text") or "").strip()
    cmd = text.split()[0].split("@")[0].lower() if text.startswith("/") else ""

    if not WEBAPP:
        api("sendMessage", {"chat_id": chat_id, "text": t(user, "need_url")})
        return

    if cmd in ("/start", "/app", ""):
        send(chat_id, t(user, "hello"), user)
        return
    if cmd == "/usa":
        send(chat_id, t(user, "hello"), user, "usa")
        return
    if cmd in ("/book", "/bookings"):
        send(chat_id, t(user, "hello"), user, "book")
        return
    if cmd in ("/shops", "/sto"):
        send(chat_id, t(user, "hello"), user, "shops")
        return
    if cmd == "/help":
        send(chat_id, t(user, "help"), user)
        return
    send(chat_id, t(user, "hello"), user)


def main() -> int:
    if not TOKEN:
        print(
            "Set TELEGRAM_BOT_TOKEN from BotFather, then:\n"
            "  export TELEGRAM_BOT_TOKEN=...\n"
            "  export TELEGRAM_WEBAPP_URL=https://your-https-host/\n"
            "  python3 telegram/bot.py",
            file=sys.stderr,
        )
        return 1
    if not WEBAPP.startswith("https://"):
        print(
            "TELEGRAM_WEBAPP_URL must be HTTPS (Flutter web build). Mini App buttons need it.",
            file=sys.stderr,
        )
    print(f"Ta4ka bot polling · webapp={WEBAPP or '(unset)'} · @{BOT_USER}")
    if WEBAPP.startswith("https://"):
        try:
            api(
                "setChatMenuButton",
                {
                    "menu_button": {
                        "type": "web_app",
                        "text": "Ta4ka",
                        "web_app": {"url": WEBAPP},
                    }
                },
            )
        except Exception as exc:  # noqa: BLE001
            print("menu button:", exc, file=sys.stderr)
    offset = 0
    while True:
        try:
            data = api("getUpdates", {"offset": offset, "timeout": 25})
            for upd in data.get("result") or []:
                offset = int(upd["update_id"]) + 1
                try:
                    handle(upd)
                except Exception as exc:  # noqa: BLE001
                    print("handle:", exc, file=sys.stderr)
        except urllib.error.HTTPError as exc:
            print("http:", exc.read().decode(errors="replace"), file=sys.stderr)
            time.sleep(2)
        except Exception as exc:  # noqa: BLE001
            print("poll:", exc, file=sys.stderr)
            time.sleep(2)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
