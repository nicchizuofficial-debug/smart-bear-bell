@echo off
chcp 65001 > nul
echo Smart Bear Bell デモ起動中...
echo.

:: 既存のDartプロセスを終了
taskkill /F /IM dart.exe > nul 2>&1

:: Flutterウェブサーバーをバックグラウンドで起動
start "" /B flutter run -d web-server --web-port 8080

:: 起動待ち（10秒）
echo サーバー起動中... しばらくお待ちください
timeout /t 10 /nobreak > nul

:: ブラウザで開く
echo ブラウザを起動します...
start http://localhost:8080

echo.
echo ✓ デモ画面が開きました → http://localhost:8080
echo   終了するにはこのウィンドウを閉じてください。
echo.
pause
