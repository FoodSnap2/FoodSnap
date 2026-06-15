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
echo  Get latest from GitHub
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

if defined DIRTY (
    echo ERROR: You have local file changes.
    echo.
    echo Do not pull over local work.
    echo.
    echo Current changes:
    git status --short
    echo.
    echo Recommended:
    echo   git_status_check.bat
    echo.
    pause
    exit /b 1
)

echo Fetching from GitHub...
git fetch
if errorlevel 1 (
    echo.
    echo ERROR: Fetch failed.
    echo Check internet, GitHub login, or origin remote.
    echo.
    pause
    exit /b 1
)

git rev-parse --abbrev-ref --symbolic-full-name @{u} >nul 2>nul
if errorlevel 1 (
    echo.
    echo ERROR: No upstream branch is configured.
    echo.
    echo Usually fix with:
    echo   git push -u origin %CFG_BRANCH%
    echo.
    echo Or run:
    echo   git_login.bat
    echo.
    pause
    exit /b 1
)

set "AHEAD=0"
set "BEHIND=0"

for /f "tokens=1,2" %%A in ('git rev-list --left-right --count HEAD...@{u}') do (
    set "AHEAD=%%A"
    set "BEHIND=%%B"
)

if !AHEAD! GTR 0 if !BEHIND! GTR 0 (
    echo.
    echo ERROR: Local repo and GitHub have both changed.
    echo Do not auto-merge.
    echo.
    echo Recommended:
    echo   git_status_check.bat
    echo.
    pause
    exit /b 1
)

if !BEHIND! GTR 0 (
    echo.
    echo Updating local repo with fast-forward only...
    git merge --ff-only @{u}
    if errorlevel 1 (
        echo.
        echo ERROR: Update failed.
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Updated successfully.
    echo.
    pause
    exit /b 0
)

if !AHEAD! GTR 0 (
    echo.
    echo You already have local commits that are not on GitHub.
    echo.
    echo To push them, run:
    echo   git_push_local.bat
    echo.
    pause
    exit /b 0
)

echo.
echo Already up to date.
echo.
pause
exit /b 0