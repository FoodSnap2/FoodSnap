@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "APP_NAME=project"
set "APP_DISPLAY_NAME="
set "CFG_BRANCH=main"

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "APP_NAME=%app.name%"
if defined app.display_name set "APP_DISPLAY_NAME=%app.display_name%"
if not defined APP_DISPLAY_NAME set "APP_DISPLAY_NAME=%APP_NAME%"

if defined app.git_branch set "CFG_BRANCH=%app.git_branch%"
if defined app.branch set "CFG_BRANCH=%app.branch%"
if not defined CFG_BRANCH set "CFG_BRANCH=main"

echo.
echo ============================================================
echo  Push local commits to GitHub
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
    echo ERROR: No commits exist yet.
    echo.
    echo To create the first commit, run:
    echo   git_commit_and_push_now.bat
    echo.
    pause
    exit /b 1
)

set "CURRENT_BRANCH="
for /f "delims=" %%A in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%A"

if not defined CURRENT_BRANCH set "CURRENT_BRANCH=%CFG_BRANCH%"
if not defined CURRENT_BRANCH set "CURRENT_BRANCH=main"

git remote get-url origin >nul 2>nul
if errorlevel 1 (
    echo ERROR: No origin remote is configured.
    echo.
    echo Run:
    echo   git_login.bat
    echo.
    pause
    exit /b 1
)

echo Current status:
git status -sb
echo.

git rev-parse --abbrev-ref --symbolic-full-name @{u} >nul 2>nul
if errorlevel 1 (
    echo No upstream branch is configured.
    echo.
    echo Pushing with upstream tracking:
    echo   git push -u origin %CURRENT_BRANCH%
    echo.

    git push -u origin "%CURRENT_BRANCH%"
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
    echo Push complete. Upstream tracking is now configured.
    echo.
    pause
    exit /b 0
)

echo Pushing...
git push
if errorlevel 1 (
    echo.
    echo ERROR: Push failed.
    echo Possible causes:
    echo   internet problem
    echo   GitHub login needed
    echo   GitHub has newer commits
    echo   wrong origin URL
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