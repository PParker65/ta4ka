СИЗО · Хатка — Mac (без ярлыков .command)

Двойной клик по .command на новых macOS часто блокируется.
Делай так (надёжно):

1. Распакуй SIZO-Hatka.zip на Рабочий стол
   (папка должна называться SIZO-Hatka)

2. Открой Программы → Утилиты → Терминал

3. Вставь целиком одну строку и Enter:

cd ~/Desktop/SIZO-Hatka && xattr -cr . && (python3 -m http.server 8765 --bind 127.0.0.1 >/tmp/sizo.log 2>&1 &) && sleep 1 && open -na "Google Chrome" --args --app="http://127.0.0.1:8765/"

Если Chrome нет — эта строка:

cd ~/Desktop/SIZO-Hatka && xattr -cr . && (python3 -m http.server 8765 --bind 127.0.0.1 >/tmp/sizo.log 2>&1 &) && sleep 1 && open "http://127.0.0.1:8765/"

Игра откроется в окне. Остановить: в Терминале Control+C
или: kill $(lsof -t -iTCP:8765 -sTCP:LISTEN)

Windows: START.bat
