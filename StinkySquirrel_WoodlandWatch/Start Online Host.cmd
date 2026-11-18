@echo off
setlocal
cd /d "%~dp0"

set "WOODLAND_GODOT=%~1"
if not defined WOODLAND_GODOT if exist "%LOCALAPPDATA%\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" set "WOODLAND_GODOT=%LOCALAPPDATA%\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if not defined WOODLAND_GODOT for %%G in (godot.exe) do set "WOODLAND_GODOT=%%~$PATH:G"
if not defined WOODLAND_GODOT (
    echo Godot was not found. Drag the Godot console executable onto this launcher.
    pause
    exit /b 1
)

set "WOODLAND_NODE="
for %%N in (node.exe) do set "WOODLAND_NODE=%%~$PATH:N"
if not defined WOODLAND_NODE if exist "%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" set "WOODLAND_NODE=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
if not defined WOODLAND_NODE (
    echo Node.js was not found. Install Node.js 22 or newer from https://nodejs.org/.
    pause
    exit /b 1
)

"%WOODLAND_NODE%" "%~dp0tools\browser-host.mjs" "%WOODLAND_GODOT%"
set "WOODLAND_EXIT=%ERRORLEVEL%"
if not "%WOODLAND_EXIT%"=="0" pause
exit /b %WOODLAND_EXIT%
