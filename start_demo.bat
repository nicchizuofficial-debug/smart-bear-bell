@echo off
taskkill /F /IM dart.exe > nul 2>&1
start "" /B flutter run -d web-server --web-port 8080
timeout /t 12 /nobreak > nul
start http://localhost:8080
pause