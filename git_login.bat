@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "SCRIPT_NAME=git_login.bat"
set "CONFIG_FILE=build_config.bat"

set "CFG_REPO_URL="
set "CFG_BRANCH=main"
set "CFG_GIT_NAME="
set "CFG_GIT_EMAIL="
set "CFG_APP_NAME="

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "CFG_APP_NAME=%app.name%"
if defined app.display_name set "CFG_APP_NAME=%app.display_name%"

if defined app.repo_url set "CFG_REPO_URL=%app.repo_url%"
if defined app.git_repo_url set "CFG_REPO_URL=%app.git_repo_url%"
if defined app.github_url set "CFG_REPO_URL=%app.github_url%"

if defined app.git_branch set "CFG_BRANCH=%app.git_branch%"
if defined app.branch set "CFG_BRANCH=%app.branch%"

if defined app.git_name set "CFG_GIT_NAME=%app.git_name%"
if defined app.git_user_name set "CFG_GIT_NAME=%app.git_user_name%"

if defined app.git_email set "CFG_GIT_EMAIL=%app.git_email%"
if defined app.git_user_email set "CFG_GIT_EMAIL=%app.git_user_email%"

if not defined CFG_APP_NAME set "CFG_APP_NAME=project"
if not defined CFG_BRANCH set "CFG_BRANCH=main"

echo.
echo ============================================================
echo  GitHub login / origin setup
echo ============================================================
echo.
echo Project folder:
echo   %CD%
echo.
echo Project:
echo   %CFG_APP_NAME%
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: git was not found in PATH.
    echo Install Git for Windows first.
    echo.
    pause
    exit /b 1
)

set "EXISTING_LOCAL_NAME="
set "EXISTING_LOCAL_EMAIL="
set "EXISTING_GLOBAL_NAME="
set "EXISTING_GLOBAL_EMAIL="
set "EXISTING_ORIGIN="
set "CURRENT_BRANCH="

if exist ".git" (
    for /f "delims=" %%A in ('git config --local --get user.name 2^>nul') do set "EXISTING_LOCAL_NAME=%%A"
    for /f "delims=" %%A in ('git config --local --get user.email 2^>nul') do set "EXISTING_LOCAL_EMAIL=%%A"
    for /f "delims=" %%A in ('git remote get-url origin 2^>nul') do set "EXISTING_ORIGIN=%%A"
    for /f "delims=" %%A in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%A"
)

for /f "delims=" %%A in ('git config --global --get user.name 2^>nul') do set "EXISTING_GLOBAL_NAME=%%A"
for /f "delims=" %%A in ('git config --global --get user.email 2^>nul') do set "EXISTING_GLOBAL_EMAIL=%%A"

set "FINAL_NAME=%CFG_GIT_NAME%"
if not defined FINAL_NAME if defined EXISTING_LOCAL_NAME set "FINAL_NAME=%EXISTING_LOCAL_NAME%"
if not defined FINAL_NAME if defined EXISTING_GLOBAL_NAME set "FINAL_NAME=%EXISTING_GLOBAL_NAME%"

set "FINAL_EMAIL=%CFG_GIT_EMAIL%"
if not defined FINAL_EMAIL if defined EXISTING_LOCAL_EMAIL set "FINAL_EMAIL=%EXISTING_LOCAL_EMAIL%"
if not defined FINAL_EMAIL if defined EXISTING_GLOBAL_EMAIL set "FINAL_EMAIL=%EXISTING_GLOBAL_EMAIL%"

set "FINAL_REPO_URL=%CFG_REPO_URL%"
if not defined FINAL_REPO_URL if defined EXISTING_ORIGIN set "FINAL_REPO_URL=%EXISTING_ORIGIN%"

set "FINAL_BRANCH=%CURRENT_BRANCH%"
if not defined FINAL_BRANCH set "FINAL_BRANCH=%CFG_BRANCH%"
if not defined FINAL_BRANCH set "FINAL_BRANCH=main"

echo This script will:
echo   initialize Git here if needed
echo   set local Git name/email for this repo
echo   set the GitHub origin URL
echo   configure Git Credential Manager if available
echo   push the current branch with upstream tracking, if commits exist
echo.
echo Config priority:
echo   1. build_config.bat
echo   2. existing .git config
echo   3. global Git config
echo   4. prompt
echo.
pause

if not exist ".git" (
    echo.
    echo This folder is not currently a Git repository:
    echo   %CD%
    echo.
    set "MAKE_REPO="
    set /p "MAKE_REPO=Initialize Git repository here? [Y/n]: "

    if /I "!MAKE_REPO!"=="n" (
        echo.
        echo Cancelled.
        echo.
        pause
        exit /b 1
    )

    echo.
    echo Initializing Git repository...

    git init -b "%FINAL_BRANCH%" >nul 2>nul
    if errorlevel 1 (
        git init
        if errorlevel 1 (
            echo.
            echo ERROR: git init failed.
            echo.
            pause
            exit /b 1
        )

        git checkout -B "%FINAL_BRANCH%"
        if errorlevel 1 (
            echo.
            echo ERROR: Could not create or switch to branch "%FINAL_BRANCH%".
            echo.
            pause
            exit /b 1
        )
    )
)

echo.
echo Git name:
if defined FINAL_NAME (
    echo   %FINAL_NAME%
) else (
    echo   not set
)

set "INPUT_NAME="
set /p "INPUT_NAME=Git name [%FINAL_NAME%]: "
if defined INPUT_NAME set "FINAL_NAME=%INPUT_NAME%"

if not defined FINAL_NAME (
    echo.
    echo ERROR: Git name is required.
    echo.
    pause
    exit /b 1
)

echo.
echo Git email:
if defined FINAL_EMAIL (
    echo   %FINAL_EMAIL%
) else (
    echo   not set
)

set "INPUT_EMAIL="
set /p "INPUT_EMAIL=Git email [%FINAL_EMAIL%]: "
if defined INPUT_EMAIL set "FINAL_EMAIL=%INPUT_EMAIL%"

if not defined FINAL_EMAIL (
    echo.
    echo ERROR: Git email is required.
    echo.
    pause
    exit /b 1
)

echo.
echo GitHub repo URL:
if defined FINAL_REPO_URL (
    echo   %FINAL_REPO_URL%
) else (
    echo   not set
)

set "INPUT_REPO_URL="
set /p "INPUT_REPO_URL=Repo URL [%FINAL_REPO_URL%]: "
if defined INPUT_REPO_URL set "FINAL_REPO_URL=%INPUT_REPO_URL%"

if not defined FINAL_REPO_URL (
    echo.
    echo ERROR: Repo URL is required.
    echo.
    pause
    exit /b 1
)

echo.
echo Setting local Git identity...
git config --local user.name "%FINAL_NAME%"
if errorlevel 1 (
    echo.
    echo ERROR: Could not set local Git user.name.
    echo.
    pause
    exit /b 1
)

git config --local user.email "%FINAL_EMAIL%"
if errorlevel 1 (
    echo.
    echo ERROR: Could not set local Git user.email.
    echo.
    pause
    exit /b 1
)

echo.
echo Checking Git Credential Manager...
git credential-manager --version >nul 2>nul
if not errorlevel 1 (
    git config --global credential.helper manager
    echo Git Credential Manager configured.
) else (
    git credential-manager-core --version >nul 2>nul
    if not errorlevel 1 (
        git config --global credential.helper manager-core
        echo Git Credential Manager Core configured.
    ) else (
        echo WARNING: Git Credential Manager was not found.
        echo Git may ask for a username and personal access token.
    )
)

echo.
echo Setting origin remote...
git remote get-url origin >nul 2>nul
if errorlevel 1 (
    git remote add origin "%FINAL_REPO_URL%"
) else (
    git remote set-url origin "%FINAL_REPO_URL%"
)

if errorlevel 1 (
    echo.
    echo ERROR: Could not set origin remote.
    echo.
    pause
    exit /b 1
)

for /f "delims=" %%B in ('git branch --show-current 2^>nul') do set "CURRENT_BRANCH=%%B"

if not defined CURRENT_BRANCH (
    echo.
    echo No current branch detected.
    echo Creating or switching to branch "%FINAL_BRANCH%"...
    git checkout -B "%FINAL_BRANCH%"
    if errorlevel 1 (
        echo.
        echo ERROR: Could not create or switch to "%FINAL_BRANCH%".
        echo.
        pause
        exit /b 1
    )
    set "CURRENT_BRANCH=%FINAL_BRANCH%"
)

echo.
echo Current Git setup:
echo ------------------------------------------------------------
echo Name:
git config --local --get user.name
echo.
echo Email:
git config --local --get user.email
echo.
echo Remote:
git remote -v
echo.
echo Branch/status:
git status -sb
echo ------------------------------------------------------------
echo.

git rev-parse --verify HEAD >nul 2>nul
if errorlevel 1 (
    echo No commits exist yet.
    echo.
    echo GitHub origin/login setup is done, but there is nothing to push yet.
    echo.
    echo Recommended next steps:
    echo   1. Make sure .gitignore is correct.
    echo   2. Run git_commit_and_push_now.bat after we update that script.
    echo.
    pause
    exit /b 0
)

echo Ready to push branch "%CURRENT_BRANCH%" to GitHub.
echo During push, GitHub may open a browser login window.
echo.
pause

git push -u origin "%CURRENT_BRANCH%"
if errorlevel 1 (
    echo.
    echo ERROR: Push/login failed.
    echo.
    echo If Git asks for a password, use a GitHub personal access token,
    echo not your GitHub account password.
    echo.
    echo You can inspect the repo state with:
    echo   git_status_check.bat
    echo.
    pause
    exit /b 1
)

echo.
echo GitHub login and push are set up.
echo.
echo Future pushes should work with:
echo   git_push_local.bat
echo   git_commit_and_push_now.bat
echo.
pause
exit /b 0