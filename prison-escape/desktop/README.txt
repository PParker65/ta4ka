СИЗО · Хатка — локальная папка (не сайт Cursor / grok.bot)

macOS
1. Скопируй всю эту папку на Рабочий стол.
2. Двойной клик: «Открыть СИЗО.command»
   (если macOS ругается: ПКМ → Открыть → Открыть)
3. Игра откроется в окне без вкладок браузера.

Windows
1. Скопируй папку на Рабочий стол.
2. Двойной клик: «Открыть СИЗО.bat»
3. Нужен Python в PATH (python.org) или открой index.html через любой локальный сервер.

Скипы (добавь в конец адреса в окне приложения):
  ?cell=1&day=1&phase=wake
  ?cell=1&day=1&phase=food
  ?cell=1&day=1&phase=evening
  ?at=yard
  ?at=yard&day=2
  ?at=shmon
  ?at=shmon&look=desk
  ?at=photo
  ?at=med
  ?at=bath
  ?at=kpp
  ?at=van

Через Node (настоящее Electron-окно):
  cd prison-escape
  npm install
  npm run desktop
