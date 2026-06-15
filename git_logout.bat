@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "APP_NAME=project"
set "APP_DISPLAY_NAME="
set "CFG_REPO_URL="
set "CFG_GITHUB_LOGIN="

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "APP_NAME=%app.name%"
if defined app.display_name set "APP_DISPLAY_NAME=%app.display_name%"
if not defined APP_DISPLAY_NAME set "APP_DISPLAY_NAME=%APP_NAME%"

if defined app.repo_url set "CFG_REPO_URL=%app.repo_url%"
if defined app.git_repo_url set "CFG_REPO_URL=%app.git_repo_url%"
if defined app.github_url set "CFG_REPO_URL=%app.github_url%"

if defined app.github_login set "CFG_GITHUB_LOGIN=%app.github_login%"
if defined app.github_account set "CFG_GITHUB_LOGIN=%app.github_account%"
if defined app.github_user set "CFG_GITHUB_LOGIN=%app.github_user%"
if defined app.github_username set "CFG_GITHUB_LOGIN=%app.github_username%"

if defined CFG_REPO_URL call :ParseRepoUrl "%CFG_REPO_URL%"
if not defined CFG_GITHUB_LOGIN if defined REPO_OWNER set "CFG_GITHUB_LOGIN=%REPO_OWNER%"

echo.
echo ============================================================
echo  GitHub logout
echo ============================================================
echo.
echo Project:
echo   %APP_DISPLAY_NAME%
echo.
echo Folder:
echo   %CD%
echo.
echo Expected GitHub login:
if defined CFG_GITHUB_LOGIN (
    echo   %CFG_GITHUB_LOGIN%
) else (
    echo   not configured
)
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo ERROR: git was not found in PATH.
    echo.
    pause
    exit /b 1
)

git credential-manager --version >nul 2>nul
if errorlevel 1 (
    echo WARNING: git credential-manager was not found.
    echo Will still try generic Git and Windows credential cleanup.
    echo.
    set "HAS_GCM="
) else (
    set "HAS_GCM=1"
)

if defined HAS_GCM (
    echo Git Credential Manager accounts currently known:
    echo ------------------------------------------------------------
    git credential-manager github list
    echo ------------------------------------------------------------
    echo.
)

echo This will remove cached GitHub credentials from this Windows login.
echo It will not change commits, branches, remotes, files, or GitHub repos.
echo.

set "CONFIRM="
set /p "CONFIRM=Continue logout? [y/N]: "

if /I not "%CONFIRM%"=="y" (
    echo.
    echo Cancelled.
    echo.
    pause
    exit /b 0
)

echo.
echo Logging out Git Credential Manager accounts...

if defined HAS_GCM (
    if defined CFG_GITHUB_LOGIN (
        git credential-manager github logout "%CFG_GITHUB_LOGIN%" --url https://github.com --no-ui >nul 2>nul
        if errorlevel 1 (
            echo Account not logged out or not found:
            echo   %CFG_GITHUB_LOGIN%
        ) else (
            echo Logged out:
            echo   %CFG_GITHUB_LOGIN%
        )
    )

    for /f "delims=" %%A in ('git credential-manager github list 2^>nul') do call :LogoutListedAccount "%%A"
) else (
    echo Skipped Git Credential Manager account logout.
)

echo.
echo Rejecting generic git credential for github.com...

(
    echo protocol=https
    echo host=github.com
    echo(
) | git credential reject >nul 2>nul

echo Done.

echo.
echo Clearing common Windows Credential Manager targets...

cmdkey /delete:"git:https://github.com" >nul 2>nul
cmdkey /delete:"git:https://github.com/" >nul 2>nul
cmdkey /delete:"https://github.com" >nul 2>nul
cmdkey /delete:"github.com" >nul 2>nul
cmdkey /delete:"LegacyGeneric:target=git:https://github.com" >nul 2>nul
cmdkey /delete:"LegacyGeneric:target=git:https://github.com/" >nul 2>nul

echo Done.

echo.
echo Remaining github-related Windows credentials:
echo ------------------------------------------------------------
cmdkey /list | findstr /I github
if errorlevel 1 echo none found
echo ------------------------------------------------------------

if defined HAS_GCM (
    echo.
    echo Remaining Git Credential Manager GitHub accounts:
    echo ------------------------------------------------------------
    git credential-manager github list
    if errorlevel 1 echo none found
    echo ------------------------------------------------------------
)

echo.
echo Logout cleanup complete.
echo.
echo To test login detection, run:
echo   git_login.bat
echo.
pause
exit /b 0

:LogoutListedAccount
set "ACCOUNT=%~1"

if not defined ACCOUNT exit /b 0

echo %ACCOUNT% | findstr /I "warning error fatal" >nul 2>nul
if not errorlevel 1 exit /b 0

if defined CFG_GITHUB_LOGIN (
    if /I "%ACCOUNT%"=="%CFG_GITHUB_LOGIN%" exit /b 0
)

git credential-manager github logout "%ACCOUNT%" --url https://github.com --no-ui >nul 2>nul
if errorlevel 1 (
    echo Account not logged out or not found:
    echo   %ACCOUNT%
) else (
    echo Logged out:
    echo   %ACCOUNT%
)

exit /b 0

:ParseRepoUrl
set "REPO_URL_WORK=%~1"
set "REPO_OWNER="
set "REPO_NAME="

set "REPO_PATH=%REPO_URL_WORK%"
set "REPO_PATH=%REPO_PATH:https://github.com/=%"
set "REPO_PATH=%REPO_PATH:http://github.com/=%"
set "REPO_PATH=%REPO_PATH:git@github.com:=%"

for /f "tokens=1,2 delims=/" %%A in ("%REPO_PATH%") do (
    set "REPO_OWNER=%%A"
    set "REPO_NAME=%%B"
)

if defined REPO_NAME set "REPO_NAME=%REPO_NAME:.git=%"
exit /b 0