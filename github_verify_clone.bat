@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "APP_NAME=project"
set "APP_DISPLAY_NAME="
set "CFG_REPO_URL="

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "APP_NAME=%app.name%"
if defined app.display_name set "APP_DISPLAY_NAME=%app.display_name%"
if not defined APP_DISPLAY_NAME set "APP_DISPLAY_NAME=%APP_NAME%"

if defined app.repo_url set "CFG_REPO_URL=%app.repo_url%"
if defined app.git_repo_url set "CFG_REPO_URL=%app.git_repo_url%"
if defined app.github_url set "CFG_REPO_URL=%app.github_url%"

echo.
echo ============================================================
echo  Verify GitHub clone
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

set "REMOTE_URL="
set "LOCAL_HEAD="

if exist ".git" (
    for /f "delims=" %%A in ('git remote get-url origin 2^>nul') do set "REMOTE_URL=%%A"
    for /f "delims=" %%A in ('git rev-parse HEAD 2^>nul') do set "LOCAL_HEAD=%%A"
)

if not defined REMOTE_URL if defined CFG_REPO_URL set "REMOTE_URL=%CFG_REPO_URL%"

if not defined REMOTE_URL (
    echo ERROR: Could not determine GitHub repo URL.
    echo.
    echo Add this to build_config.bat:
    echo   set "app.repo_url=https://github.com/OWNER/REPO.git"
    echo.
    echo Or run:
    echo   git_login.bat
    echo.
    pause
    exit /b 1
)

set "TEST_DIR=%TEMP%\github-verify-clone-%RANDOM%-%RANDOM%"

echo Remote URL:
echo   %REMOTE_URL%
echo.
echo Test clone folder:
echo   %TEST_DIR%
echo.

if exist "%TEST_DIR%" (
    rmdir /S /Q "%TEST_DIR%" >nul 2>nul
)

echo Cloning fresh copy from GitHub...
git clone "%REMOTE_URL%" "%TEST_DIR%"
if errorlevel 1 (
    echo.
    echo ERROR: Test clone failed.
    echo.
    echo Possible causes:
    echo   GitHub login problem
    echo   wrong repo URL
    echo   repo is private and credentials are missing
    echo   internet problem
    echo   nothing has been pushed yet
    echo.
    pause
    exit /b 1
)

echo.
echo Test clone succeeded.
echo.

if defined LOCAL_HEAD (
    set "CLONE_HEAD="
    for /f "delims=" %%A in ('git -C "%TEST_DIR%" rev-parse HEAD 2^>nul') do set "CLONE_HEAD=%%A"

    if not defined CLONE_HEAD (
        echo ERROR: GitHub cloned, but the remote repo has no commits yet.
        echo.
        echo Your local repo has a commit, but it has not been pushed.
        echo.
        echo Run:
        echo   just_push.bat
        echo.
        echo Removing test clone...
        rmdir /S /Q "%TEST_DIR%" >nul 2>nul
        echo.
        pause
        exit /b 1
    )

    if /I not "!CLONE_HEAD!"=="!LOCAL_HEAD!" (
        echo ERROR: GitHub clone does not match your local commit.
        echo.
        echo Local HEAD:
        echo   !LOCAL_HEAD!
        echo.
        echo GitHub HEAD:
        echo   !CLONE_HEAD!
        echo.
        echo This usually means your latest commit has not been pushed yet.
        echo.
        echo Run:
        echo   just_push.bat
        echo.
        echo Removing test clone...
        rmdir /S /Q "%TEST_DIR%" >nul 2>nul
        echo.
        pause
        exit /b 1
    )

    echo GitHub HEAD matches local HEAD:
    echo   !LOCAL_HEAD!
    echo.
)

echo Cloned folder contents:
dir "%TEST_DIR%"
echo.

if exist "%TEST_DIR%\.git" (
    echo Clone Git status:
    git -C "%TEST_DIR%" status -sb
    echo.
)

echo Removing test clone...
rmdir /S /Q "%TEST_DIR%"
if errorlevel 1 (
    echo.
    echo WARNING: Could not remove test clone folder:
    echo   %TEST_DIR%
    echo You may delete it manually.
    echo.
    pause
    exit /b 1
)

echo.
echo GitHub verification complete.
echo.
pause
exit /b 0