@echo off
cd /d "%~dp0"
set PORT=8765
start "SIZO-server" /min cmd /c python -m http.server %PORT% --bind 127.0.0.1
timeout /t 1 /nobreak >nul
start "" "http://127.0.0.1:%PORT%/"
echo SIZO Hatka. Close this window after you finish playing, then end the python server in Task Manager if needed.
pause
