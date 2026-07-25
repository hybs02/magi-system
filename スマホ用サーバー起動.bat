@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================
echo   MAGI SYSTEM  スマホ用サーバー
echo ============================================
echo.
echo  スマホ(同じWi-Fi)のブラウザで次のURLを開いてください:
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%b in ("%%a") do echo      http://%%b:8000/index.html
)
echo.
echo  ※この黒い窓は開いたままにしてください
echo    (閉じるとスマホから使えなくなります)
echo ============================================
echo.
set "PY=python"
where python >nul 2>&1 || set "PY=py"
echo サーバー起動中... (停止するにはこの窓を閉じる)
echo.
"%PY%" -m http.server 8000
echo.
echo === サーバーが停止しました ===
pause >nul
