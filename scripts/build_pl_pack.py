# -*- coding: utf-8 -*-
"""Rebuild pl_pack.dart with keys that match Dart runtime English strings."""
from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STRINGS = ROOT / "lib/core/l10n/app_strings.dart"
PACK = ROOT / "lib/core/l10n/pl_pack.dart"
CACHE = ROOT / "scripts/_pl_cache.json"
OLD_PACK = PACK.read_text(encoding="utf-8") if PACK.exists() else ""

pat = re.compile(
    r"const L\(\s*'((?:\\'|[^'])*)'\s*,\s*'((?:\\'|[^'])*)'\s*,\s*'((?:\\'|[^'])*)'"
    r"(?:\s*,\s*'((?:\\\\'|[^'])*)')?"
)


def dart_unesc(s: str) -> str:
    out: list[str] = []
    i = 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            n = s[i + 1]
            mapping = {"n": "\n", "t": "\t", "r": "\r", "'": "'", '"': '"', "\\": "\\", "$": "$"}
            out.append(mapping.get(n, n))
            i += 2
        else:
            out.append(s[i])
            i += 1
    return "".join(out)


def dart_esc(s: str) -> str:
    return (
        s.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )


content = STRINGS.read_text(encoding="utf-8")
# raw_en (as in source) -> runtime_en, optional explicit pl raw
entries: list[tuple[str, str, str | None]] = []
seen: set[str] = set()
for m in pat.finditer(content):
    raw_en = m.group(2)
    runtime_en = dart_unesc(raw_en)
    if runtime_en in seen:
        continue
    seen.add(runtime_en)
    raw_pl = m.group(4)
    explicit = dart_unesc(raw_pl) if raw_pl else None
    entries.append((raw_en, runtime_en, explicit))

# Load existing translations from old pack + cache + overrides
def load_old_pack() -> dict[str, str]:
    mp: dict[str, str] = {}
    for m in re.finditer(r"'((?:\\'|[^'])*)'\s*:\s*'((?:\\'|[^'])*)'", OLD_PACK):
        mp[dart_unesc(m.group(1))] = dart_unesc(m.group(2))
    return mp


old = load_old_pack()
cache: dict[str, str] = {}
if CACHE.exists():
    cache = json.loads(CACHE.read_text(encoding="utf-8"))

OVERRIDES = {
    "Today": "Dziś",
    "Shop": "Warsztat",
    "Chat": "Czat",
    "Camera": "Kamera",
    "Messages": "Wiadomości",
    "Extras": "Dod. prace",
    "Feed": "Aktualności",
    "Shops": "Warsztaty",
    "Bookings": "Rezerwacje",
    "Car": "Auto",
    "Profile": "Profil",
    "Home": "Start",
    "Back": "Wstecz",
    "Next": "Dalej",
    "Save": "Zapisz",
    "Cancel": "Anuluj",
    "Confirm": "Potwierdź",
    "Send": "Wyślij",
    "Open chat": "Otwórz czat",
    "Approve": "Zatwierdź",
    "Decline": "Odrzuć",
    "Language": "Język",
    "Login": "Logowanie",
    "Password": "Hasło",
    "Sign in": "Zaloguj się",
    "Register": "Zarejestruj się",
    "Log out": "Wyloguj",
    "Name": "Imię",
    "Phone": "Telefon",
    "Address": "Adres",
    "City": "Miasto",
    "Services": "Usługi",
    "Status": "Status",
    "Total": "Razem",
    "Work": "Praca",
    "Ready": "Gotowe",
    "In progress": "W trakcie",
    "New": "Nowe",
    "Soon": "Wkrótce",
    "Tomorrow": "Jutro",
    "Skip": "Pomiń",
    "Done": "Gotowe",
    "Again": "Ponownie",
    "Categories": "Kategorie",
    "Account": "Konto",
    "Security": "Bezpieczeństwo",
    "Support": "Wsparcie",
    "Garage": "Garaż",
    "Look": "Wygląd",
    "LIVE": "NA ŻYWO",
    "Live": "Na żywo",
    "Welcome": "Witamy",
    "Cars booked for today": "Auta zapisane na dziś",
    "Next car in the arrival queue": "Następne auto w kolejce na wjazd",
    "Extra work requests": "Prośby o dodatkowe prace",
    "No pending extras": "Brak oczekujących dopłat",
    "New messages": "Nowe wiadomości",
    "No new messages": "Brak nowych wiadomości",
    "Take into bay": "Przyjmij na stanowisko",
    "Waiting for client": "Oczekiwanie na klienta",
    "Ready for handover": "Gotowe do wydania",
    "Approval": "Do akceptacji",
    "Autoservice CRM": "Autoservice CRM",
    "Smash the car and tap the pluses. Clear them all and they come back. 100 pluses = +$5, 1000 = +$10, then more.": (
        "Rozbij auto i stukaj plusy. Zbierz wszystkie — wrócą. 100 plusów = +$5, 1000 = +$10, potem więcej."
    ),
    "1. On Car, pick your brand and a category — you will see the job description and a “from” price.\n"
    "2. In Shops, open AutoShift Warsaw for that category: Mon–Sat 09:00–18:00, hourly slots.\n"
    "3. Choose jobs, a technician and a time. Status, bay camera and the report are in Bookings.\n"
    "4. The “from” price is labour unless parts are listed as included.": (
        "1. W Auto wybierz markę i kategorię — zobaczysz opis pracy i cenę „od”.\n"
        "2. W Warsztatach otwórz AutoShift Warszawa dla tej kategorii: pn–sb 09:00–18:00, sloty godzinowe.\n"
        "3. Wybierz prace, mechanika i godzinę. Status, kamera stanowiska i raport są w Rezerwacjach.\n"
        "4. Cena „od” to robocizna, chyba że części są w cenie."
    ),
}


def translate_mymemory(text: str) -> str:
    q = urllib.parse.quote(text[:450])
    url = f"https://api.mymemory.translated.net/get?q={q}&langpair=en|pl"
    req = urllib.request.Request(url, headers={"User-Agent": "AutoservicePL/1.0"})
    with urllib.request.urlopen(req, timeout=25) as resp:
        data = json.loads(resp.read().decode("utf-8"))
    return (data.get("responseData") or {}).get("translatedText") or text


resolved: dict[str, str] = {}
need_api: list[str] = []

for raw_en, runtime_en, explicit in entries:
    if explicit:
        resolved[runtime_en] = explicit
    elif runtime_en in OVERRIDES:
        resolved[runtime_en] = OVERRIDES[runtime_en]
    elif runtime_en in old and old[runtime_en] != runtime_en:
        resolved[runtime_en] = old[runtime_en]
    elif runtime_en in cache and cache[runtime_en] != runtime_en:
        resolved[runtime_en] = cache[runtime_en]
    else:
        need_api.append(runtime_en)

print(f"resolved {len(resolved)}, need API {len(need_api)}", flush=True)

for i, en in enumerate(need_api):
    try:
        pl = translate_mymemory(en)
        pl = (
            pl.replace("&quot;", '"')
            .replace("&#39;", "'")
            .replace("&amp;", "&")
            .replace("&lt;", "<")
            .replace("&gt;", ">")
        )
        resolved[en] = pl
        cache[en] = pl
        print(f"[{i+1}/{len(need_api)}] OK", flush=True)
    except Exception as exc:
        resolved[en] = en
        print(f"[{i+1}/{len(need_api)}] FAIL {exc}", flush=True)
    time.sleep(0.3)
    if (i + 1) % 25 == 0:
        CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")

CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")

# Apply overrides last
for k, v in OVERRIDES.items():
    resolved[k] = v

# Also keep any extra keys from old pack that are still useful
for k, v in old.items():
    resolved.setdefault(k, v)

lines = [
    "/// Polish UI pack keyed by English source string (fallback when L.pl is null).",
    "const plUiByEn = <String, String>{",
]
for en in sorted(resolved.keys()):
    lines.append(f"  '{dart_esc(en)}': '{dart_esc(resolved[en])}',")
lines += [
    "};",
    "",
    "String polishFromEnglish(String english, [String? explicitPl]) {",
    "  if (explicitPl != null && explicitPl.isNotEmpty) {",
    "    return explicitPl;",
    "  }",
    "  return plUiByEn[english] ?? english;",
    "}",
    "",
]
PACK.write_text("\n".join(lines), encoding="utf-8")

same = sum(1 for e, p in resolved.items() if e == p)
print(f"Wrote {len(resolved)} entries; still-english={same}", flush=True)
