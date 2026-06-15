@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "APP_NAME=project"
set "APP_DISPLAY_NAME="
set "CFG_REPO_URL="
set "CFG_BRANCH=main"

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "APP_NAME=%app.name%"
if defined app.display_name set "APP_DISPLAY_NAME=%app.display_name%"
if not defined APP_DISPLAY_NAME set "APP_DISPLAY_NAME=%APP_NAME%"

if defined app.repo_url set "CFG_REPO_URL=%app.repo_url%"
if defined app.git_repo_url set "CFG_REPO_URL=%app.git_repo_url%"
if defined app.github_url set "CFG_REPO_URL=%app.github_url%"

if defined app.git_branch set "CFG_BRANCH=%app.git_branch%"
if defined app.branch set "CFG_BRANCH=%app.branch%"
if not defined CFG_BRANCH set "CFG_BRANCH=main"

echo.
echo ============================================================
echo  Git status check
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

set "CURRENT_BRANCH="
set "ORIGIN_URL="
set "DIRTY="
set "HAS_HEAD="
set "AHEAD=0"
set "BEHIND=0"

for /f "delims=" %%A in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%A"
for /f "delims=" %%A in ('git remote get-url origin 2^>nul') do set "ORIGIN_URL=%%A"
for /f "delims=" %%A in ('git status --porcelain 2^>nul') do set "DIRTY=1"

git rev-parse --verify HEAD >nul 2>nul
if not errorlevel 1 set "HAS_HEAD=1"

echo Branch:
if defined CURRENT_BRANCH (
    echo   %CURRENT_BRANCH%
) else (
    echo   no current branch detected
)
echo.

echo Origin remote:
if defined ORIGIN_URL (
    echo   %ORIGIN_URL%
) else (
    echo   not configured
)
echo.

if defined CFG_REPO_URL (
    echo Repo URL from build_config.bat:
    echo   %CFG_REPO_URL%
    echo.
)

echo Local status:
git status -sb
echo.

if not defined HAS_HEAD (
    echo ============================================================
    echo  Recommendation
    echo ============================================================
    echo.
    echo No commits exist yet.
    echo.
    if defined DIRTY (
        echo You have files that can be committed.
        echo.
        echo Recommended:
        echo   git_commit_and_push_now.bat
    ) else (
        echo There are no commits and no visible local changes.
    )
    echo.
    pause
    exit /b 0
)

if not defined ORIGIN_URL (
    echo ============================================================
    echo  Recommendation
    echo ============================================================
    echo.
    echo No origin remote is configured.
    echo.
    echo Recommended:
    echo   git_login.bat
    echo.
    pause
    exit /b 1
)

echo Checking GitHub...
git fetch --quiet
if errorlevel 1 (
    echo.
    echo WARNING: Could not contact GitHub.
    echo This may be internet, login, or remote URL related.
    echo.
    echo Local status above is still useful.
    echo.
    pause
    exit /b 1
)

git rev-parse --abbrev-ref --symbolic-full-name @{u} >nul 2>nul
if errorlevel 1 (
    echo.
    echo ============================================================
    echo  Recommendation
    echo ============================================================
    echo.
    echo No upstream branch is configured.
    echo.
    if defined CURRENT_BRANCH (
        echo Usually fix with:
        echo   git push -u origin %CURRENT_BRANCH%
    ) else (
        echo Usually fix with:
        echo   git push -u origin %CFG_BRANCH%
    )
    echo.
    echo Or run:
    echo   git_login.bat
    echo.
    pause
    exit /b 1
)

for /f "tokens=1,2" %%A in ('git rev-list --left-right --count HEAD...@{u} 2^>nul') do (
    set "AHEAD=%%A"
    set "BEHIND=%%B"
)

echo.
echo ============================================================
echo  Recommendation
echo ============================================================
echo.

if defined DIRTY (
    echo You have local file changes.
    echo.
    echo Usually:
    echo   For code changes, run build.bat.
    echo   For docs/scripts/non-build changes, run git_commit_and_push_now.bat.
    echo.
    echo Do not run git_get_latest.bat until local changes are committed or discarded.
) else (
    if !AHEAD! EQU 0 if !BEHIND! EQU 0 (
        echo Everything is clean and synced.
        echo No action needed.
    )

    if !AHEAD! GTR 0 if !BEHIND! EQU 0 (
        echo You have local commits that are not on GitHub yet.
        echo.
        echo Recommended:
        echo   git_push_local.bat
    )

    if !AHEAD! EQU 0 if !BEHIND! GTR 0 (
        echo GitHub has newer commits.
        echo.
        echo Recommended:
        echo   git_get_latest.bat
    )

    if !AHEAD! GTR 0 if !BEHIND! GTR 0 (
        echo Your local repo and GitHub have both changed.
        echo.
        echo Do not auto-merge unless you know exactly what changed.
        echo.
        echo Safer first step:
        echo   git_backup_bundle.bat
    )
)

echo.
echo Ahead of GitHub:  !AHEAD!
echo Behind GitHub:   !BEHIND!
echo.

pause
exit /b 0