# AutoShift → Mac (Cursor)

## 1. Перенести

1. Скопіюй архів `Autoservice_for_Mac.zip` на Mac (AirDrop / iCloud / USB / Google Drive).
2. Розпакуй у зручне місце, наприклад `~/Developer/Autoservice`.
3. Відкрий Cursor → **Open Folder** → обери розпаковану папку `Autoservice`.

## 2. Flutter на Mac (один раз)

```bash
# якщо Flutter ще немає:
# https://docs.flutter.dev/get-started/install/macos

flutter doctor
cd ~/Developer/Autoservice   # або твій шлях
flutter pub get
```

Для iPhone симулятора / збірки:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
flutter doctor --android-licenses   # якщо потрібен Android
```

## 3. Запуск

```bash
# web
flutter run -d chrome

# або iOS simulator
open -a Simulator
flutter run
```

Web-збірка як раніше:

```bash
powershell не потрібен — на Mac:
flutter build web --release
# або скрипти в scripts/ підправ під bash пізніше
```

## 4. Що вже в проєкті

- Flutter CRM клієнт + СТО + аукціон + реферал + MAPA
- Монохром UI (v1.0.23), блок «Знайти СТО», 3D GLB
- Карта структури: `web/structure-map.html`
- Design lab: `web/design-lab.html`

## 5. Чого немає в архіві (і навіщо)

| Виключено | Чому |
|-----------|------|
| `build/` | перезбирається (`flutter build`) |
| `.dart_tool/` | `flutter pub get` |
| `release/*.apk` | зібрати на Mac або Windows знову |
| `hosting/` | деплой-артефакти |
| `.tmp-refs/` | тимчасове |

`assets/` (моделі машин) **включено** — без них 3D не відкриється.

## 6. Продовжуй у Cursor

Просто пиши в чат як раніше — історія чатів з Windows **не** переноситься автоматично; код і правила в `.cursorrules.txt` / проєкті — так.
