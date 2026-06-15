@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "APP_NAME=project"
set "APP_DISPLAY_NAME="

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "APP_NAME=%app.name%"
if defined app.display_name set "APP_DISPLAY_NAME=%app.display_name%"
if not defined APP_DISPLAY_NAME set "APP_DISPLAY_NAME=%APP_NAME%"

echo.
echo ============================================================
echo  Recent Git history
echo ============================================================
echo.
echo Project:
echo   %APP_DISPLAY_NAME%
echo.
echo Folder:
echo   %CD%
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: git was not found in PATH.
    echo.
    pause
    exit /b 1
)

if not exist ".git" (
    echo ERROR: This folder is not a Git repository.
    echo.
    echo Run first:
    echo   git_login.bat
    echo.
    pause
    exit /b 1
)

git rev-parse --verify HEAD >nul 2>nul
if errorlevel 1 (
    echo No commits exist yet.
    echo.
    pause
    exit /b 0
)

echo Branch/status:
git status -sb
echo.

echo Recent commits:
echo.
git log --oneline --decorate --graph -30

echo.
pause
exit /b 0