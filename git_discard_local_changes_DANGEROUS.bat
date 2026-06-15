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
echo  DANGEROUS: Discard local uncommitted changes
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
    echo ERROR: No commit exists yet.
    echo There is no safe previous commit to restore to.
    echo.
    pause
    exit /b 1
)

echo This will:
echo   restore tracked files to the last commit
echo   unstage staged changes
echo   delete untracked non-ignored files
echo.
echo It should not delete ignored files or ignored folders.
echo.
echo Current changes:
git status --short
echo.

set "CONFIRM="
set /p "CONFIRM=Type YES to discard local changes: "

if not "%CONFIRM%"=="YES" (
    echo.
    echo Cancelled.
    echo.
    pause
    exit /b 0
)

echo.
echo Restoring tracked files and staged changes...
git reset --hard HEAD
if errorlevel 1 (
    echo.
    echo ERROR: git reset failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Removing untracked non-ignored files...
git clean -fd
if errorlevel 1 (
    echo.
    echo ERROR: git clean failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Local uncommitted changes discarded.
echo.
git status -sb
echo.
pause
exit /b 0