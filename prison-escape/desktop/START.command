#!/bin/bash
# Double-click this file to play SIZO · Hatka as an app window.
cd "$(dirname "$0")" || exit 1
PORT=8765

pick_port() {
  local p
  for p in 8765 8775 8785 8795; do
    if command -v lsof >/dev/null 2>&1; then
      lsof -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1 && continue
    fi
    PORT=$p
    return
  done
}
pick_port

start_server() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -m http.server "$PORT" --bind 127.0.0.1 >/tmp/sizo-hatka.log 2>&1 &
    echo $!
    return
  fi
  if command -v python >/dev/null 2>&1; then
    python -m http.server "$PORT" --bind 127.0.0.1 >/tmp/sizo-hatka.log 2>&1 &
    echo $!
    return
  fi
  if command -v node >/dev/null 2>&1; then
    node -e "require('http').createServer((q,s)=>{const fs=require('fs'),p=require('path'),u=require('url').parse(q.url).pathname,f=p.join(process.cwd(),u==='/'?'index.html':u);fs.readFile(f,(e,d)=>{if(e){s.writeHead(404);s.end('404');return}const t={'.html':'text/html','.js':'text/javascript','.css':'text/css','.svg':'image/svg+xml'};s.writeHead(200,{'Content-Type':t[p.extname(f)]||'application/octet-stream'});s.end(d)})}).listen($PORT,'127.0.0.1')" >/tmp/sizo-hatka.log 2>&1 &
    echo $!
    return
  fi
  osascript -e 'display alert "СИЗО" message "Нужен Python 3 или Node.js. Установи python.org или nodejs.org и снова кликни START.command"' 2>/dev/null || true
  exit 1
}

PID=$(start_server)
trap 'kill "$PID" 2>/dev/null || true' EXIT
sleep 0.7
URL="http://127.0.0.1:${PORT}/"

if [ -d "/Applications/Google Chrome.app" ]; then
  open -na "Google Chrome" --args --app="$URL" --new-window
elif [ -d "/Applications/Microsoft Edge.app" ]; then
  open -na "Microsoft Edge" --args --app="$URL" --new-window
elif [ -d "/Applications/Chromium.app" ]; then
  open -na "Chromium" --args --app="$URL" --new-window
else
  open "$URL"
fi

osascript -e 'display notification "Закрой это окно Терминала — игра остановится." with title "СИЗО · Хатка"' 2>/dev/null || true
wait "$PID"
