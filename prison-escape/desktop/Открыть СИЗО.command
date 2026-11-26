#!/bin/bash
# Double-click on macOS → opens SIZO as a Chrome/Edge app window (no website tab).
set -e
cd "$(dirname "$0")"
PORT=8765

if command -v lsof >/dev/null 2>&1; then
  if lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    PORT=8775
  fi
fi

python3 -m http.server "$PORT" --bind 127.0.0.1 >/tmp/sizo-hatka-server.log 2>&1 &
PID=$!
trap 'kill "$PID" 2>/dev/null || true' EXIT
sleep 0.6

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

echo "СИЗО · Хатка running. Close this window to stop."
wait "$PID"
