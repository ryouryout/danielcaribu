@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\launch_local.ps1"
if not errorlevel 1 goto :eof

py -3 -V >nul 2>nul
if not errorlevel 1 (
  py -3 "%SCRIPT_DIR%scripts\launch_local.py"
  goto :eof
)

python -c "import sys; raise SystemExit(0 if sys.version_info.major >= 3 else 1)" >nul 2>nul
if not errorlevel 1 (
  python "%SCRIPT_DIR%scripts\launch_local.py"
  goto :eof
)

python3 -c "import sys; raise SystemExit(0 if sys.version_info.major >= 3 else 1)" >nul 2>nul
if not errorlevel 1 (
  python3 "%SCRIPT_DIR%scripts\launch_local.py"
  goto :eof
)

echo PowerShell launch failed, and Python 3 was not found.
echo Try Start.bat again from a normal Windows session.
echo If it still fails, run scripts\launch_local.ps1 or install Python 3.
pause
exit /b 1
