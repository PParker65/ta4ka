@echo off
cd /d "%~dp0"
set PORT=8765
where python >nul 2>&1 && (
  start "SIZO" /min cmd /c python -m http.server %PORT% --bind 127.0.0.1
  goto open
)
where py >nul 2>&1 && (
  start "SIZO" /min cmd /c py -m http.server %PORT% --bind 127.0.0.1
  goto open
)
where node >nul 2>&1 && (
  start "SIZO" /min cmd /c node -e "require('http').createServer((q,s)=>{const fs=require('fs'),p=require('path'),u=require('url').parse(q.url).pathname,f=p.join(process.cwd(),u==='/'?'index.html':u);fs.readFile(f,(e,d)=>{if(e){s.writeHead(404);s.end('404');return}s.writeHead(200);s.end(d)})}).listen(%PORT%,'127.0.0.1')"
  goto open
)
msg * Need Python or Node.js. Install from python.org then click START.bat again.
exit /b 1
:open
timeout /t 1 /nobreak >nul
start "" "http://127.0.0.1:%PORT%/"
echo Close this window when you finish playing.
pause
