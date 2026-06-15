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
echo  Commit and push now
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

set "DIRTY="
for /f "delims=" %%A in ('git status --porcelain') do set "DIRTY=1"

if not defined DIRTY (
    echo No local file changes to commit.
    echo.
    echo Trying push anyway, in case commits are pending...
    echo.

    git push
    if errorlevel 1 (
        echo.
        echo ERROR: Push failed.
        echo.
        echo Check the repo state with:
        echo   git_status_check.bat
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Push complete.
    echo.
    pause
    exit /b 0
)

echo Current changes:
git status --short
echo.

set "MSG="
set /p "MSG=Commit message, or press Enter for default: "

if not defined MSG (
    set "MSG=Manual save %APP_DISPLAY_NAME% %DATE% %TIME%"
)

echo.
echo Adding files...
git add --all
if errorlevel 1 (
    echo.
    echo ERROR: git add failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Creating commit...
git commit -m "%MSG%"
if errorlevel 1 (
    echo.
    echo ERROR: git commit failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Pushing to GitHub...
git push
if errorlevel 1 (
    echo.
    echo ERROR: Push failed.
    echo Your commit is saved locally, but it was not pushed to GitHub.
    echo.
    echo Check the repo state with:
    echo   git_status_check.bat
    echo.
    pause
    exit /b 1
)

echo.
echo Commit and push complete.
echo.
pause
exit /b 0