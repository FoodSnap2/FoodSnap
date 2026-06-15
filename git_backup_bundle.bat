@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "APP_NAME=project"
set "APP_DISPLAY_NAME="
set "BACKUP_DIR="

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "APP_NAME=%app.name%"
if defined app.display_name set "APP_DISPLAY_NAME=%app.display_name%"
if not defined APP_DISPLAY_NAME set "APP_DISPLAY_NAME=%APP_NAME%"

if defined app.git_backup_dir set "BACKUP_DIR=%app.git_backup_dir%"

set "SAFE_APP_NAME=%APP_NAME%"
set "SAFE_APP_NAME=%SAFE_APP_NAME: =_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME:/=_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME:\=_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME::=_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME:*=_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME:?=_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME:"=_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME:<=_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME:>=_%"
set "SAFE_APP_NAME=%SAFE_APP_NAME:|=_%"

if not defined BACKUP_DIR (
    set "BACKUP_DIR=%USERPROFILE%\Desktop\%SAFE_APP_NAME%-git-backups"
)

echo.
echo ============================================================
echo  Create Git backup bundle
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
    pause
    exit /b 1
)

git rev-parse --verify HEAD >nul 2>nul
if errorlevel 1 (
    echo ERROR: No commits exist yet.
    echo A Git bundle needs at least one commit.
    echo.
    pause
    exit /b 1
)

if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
    if errorlevel 1 (
        echo ERROR: Could not create backup folder:
        echo   %BACKUP_DIR%
        echo.
        pause
        exit /b 1
    )
)

for /f "delims=" %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd.HHmmss"') do set "STAMP=%%A"

set "BACKUP_FILE=%BACKUP_DIR%\%SAFE_APP_NAME%-%STAMP%.bundle"

echo Backup folder:
echo   %BACKUP_DIR%
echo.
echo Creating backup bundle...
echo.

git bundle create "%BACKUP_FILE%" --all
if errorlevel 1 (
    echo.
    echo ERROR: Backup bundle failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Backup created:
echo   %BACKUP_FILE%
echo.
pause
exit /b 0