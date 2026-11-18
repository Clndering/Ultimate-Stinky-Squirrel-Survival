@echo off
setlocal
cd /d "%~dp0"

curl.exe --head --fail --silent --max-time 3 http://127.0.0.1:8080/ >nul
if errorlevel 1 (
    echo Start the game with "Start Online Host.cmd" first, then open this launcher again.
    pause
    exit /b 1
)

set "WOODLAND_TUNNEL="
if exist "%~dp0build\tools\cloudflared.exe" set "WOODLAND_TUNNEL=%~dp0build\tools\cloudflared.exe"
if not defined WOODLAND_TUNNEL for %%T in (cloudflared.exe) do set "WOODLAND_TUNNEL=%%~$PATH:T"
if not defined WOODLAND_TUNNEL (
    echo Download the Windows executable using the Cloudflare link in HOSTING.md.
    echo Save it as build\tools\cloudflared.exe and run this launcher again.
    pause
    exit /b 1
)

echo Share the HTTPS address ending in trycloudflare.com with your players.
echo Keep both hosting windows open. Press Ctrl+C here to stop the public link.
"%WOODLAND_TUNNEL%" tunnel --url http://127.0.0.1:8080
if errorlevel 1 pause
