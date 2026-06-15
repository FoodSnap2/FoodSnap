@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "CFG_APP_NAME=project"
set "CFG_APP_DISPLAY_NAME="
set "CFG_REPO_URL="
set "CFG_BRANCH=main"
set "CFG_GIT_NAME="
set "CFG_GIT_EMAIL="
set "CFG_GITHUB_LOGIN="

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "CFG_APP_NAME=%app.name%"
if defined app.display_name set "CFG_APP_DISPLAY_NAME=%app.display_name%"
if not defined CFG_APP_DISPLAY_NAME set "CFG_APP_DISPLAY_NAME=%CFG_APP_NAME%"

if defined app.repo_url set "CFG_REPO_URL=%app.repo_url%"
if defined app.git_repo_url set "CFG_REPO_URL=%app.git_repo_url%"
if defined app.github_url set "CFG_REPO_URL=%app.github_url%"

if defined app.git_branch set "CFG_BRANCH=%app.git_branch%"
if defined app.branch set "CFG_BRANCH=%app.branch%"
if not defined CFG_BRANCH set "CFG_BRANCH=main"

if defined app.git_name set "CFG_GIT_NAME=%app.git_name%"
if defined app.git_user_name set "CFG_GIT_NAME=%app.git_user_name%"

if defined app.git_email set "CFG_GIT_EMAIL=%app.git_email%"
if defined app.git_user_email set "CFG_GIT_EMAIL=%app.git_user_email%"

if defined app.github_login set "CFG_GITHUB_LOGIN=%app.github_login%"
if defined app.github_account set "CFG_GITHUB_LOGIN=%app.github_account%"
if defined app.github_user set "CFG_GITHUB_LOGIN=%app.github_user%"
if defined app.github_username set "CFG_GITHUB_LOGIN=%app.github_username%"

echo.
echo ============================================================
echo  GitHub login / readiness check
echo ============================================================
echo.
echo Project:
echo   %CFG_APP_DISPLAY_NAME%
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

if not defined CFG_REPO_URL (
    echo ERROR: No repo URL is configured.
    echo.
    echo Add this to build_config.bat:
    echo   set "app.repo_url=https://github.com/OWNER/REPO.git"
    echo.
    pause
    exit /b 1
)

call :ParseRepoUrl "%CFG_REPO_URL%"

if not defined REPO_OWNER (
    echo ERROR: Could not parse repo owner from:
    echo   %CFG_REPO_URL%
    echo.
    pause
    exit /b 1
)

if not defined REPO_NAME (
    echo ERROR: Could not parse repo name from:
    echo   %CFG_REPO_URL%
    echo.
    pause
    exit /b 1
)

if not defined CFG_GITHUB_LOGIN set "CFG_GITHUB_LOGIN=%REPO_OWNER%"

echo Repo URL:
echo   %CFG_REPO_URL%
echo.
echo Repo owner:
echo   %REPO_OWNER%
echo.
echo Repo name:
echo   %REPO_NAME%
echo.
echo Expected GitHub login:
echo   %CFG_GITHUB_LOGIN%
echo.
echo This script will not commit or push anything.
echo It will only set/check local Git settings and optionally run a dry-run push.
echo.
pause

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

set "FINAL_BRANCH=%CURRENT_BRANCH%"
if not defined FINAL_BRANCH set "FINAL_BRANCH=%CFG_BRANCH%"
if not defined FINAL_BRANCH set "FINAL_BRANCH=main"

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
    echo ERROR: Git name is required for commits.
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
    echo ERROR: Git email is required for commits.
    echo.
    echo This does not need to be stored in build_config.bat.
    echo It will be stored only in this repo's local .git config.
    echo.
    pause
    exit /b 1
)

echo.
echo Setting local Git identity...
git config --local user.name "%FINAL_NAME%"
if errorlevel 1 (
    echo ERROR: Could not set local Git user.name.
    pause
    exit /b 1
)

git config --local user.email "%FINAL_EMAIL%"
if errorlevel 1 (
    echo ERROR: Could not set local Git user.email.
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
        echo Git may ask for username and token in the console.
    )
)

echo.
echo Setting origin remote...
git remote get-url origin >nul 2>nul
if errorlevel 1 (
    git remote add origin "%CFG_REPO_URL%"
) else (
    git remote set-url origin "%CFG_REPO_URL%"
)

if errorlevel 1 (
    echo ERROR: Could not set origin remote.
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
        echo ERROR: Could not create or switch to "%FINAL_BRANCH%".
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

echo.
echo Checking currently stored github.com credential without opening login...
call :ShowCachedGithubCredential

echo.
set "CLEAR_CREDS="
set /p "CLEAR_CREDS=Clear cached github.com credentials? [y/N]: "

if /I "%CLEAR_CREDS%"=="y" (
    call :ForgetGithubCredentials
    echo.
    echo Rechecking currently stored github.com credential without opening login...
    call :ShowCachedGithubCredential
)

if defined AUTH_LOGIN (
    if /I not "%AUTH_LOGIN%"=="%CFG_GITHUB_LOGIN%" (
        echo.
        echo WARNING: Cached GitHub username does not match expected login.
        echo.
        echo Expected:
        echo   %CFG_GITHUB_LOGIN%
        echo.
        echo Found:
        echo   %AUTH_LOGIN%
        echo.
        set "FORGET_WRONG="
        set /p "FORGET_WRONG=Forget cached github.com credential now? [Y/n]: "

        if /I not "!FORGET_WRONG!"=="n" (
            call :ForgetGithubCredentials
            echo.
            echo Rechecking currently stored github.com credential without opening login...
            call :ShowCachedGithubCredential
        )
    )
)

echo.
echo ============================================================
echo  Optional GitHub network readiness check
echo ============================================================
echo.
echo The next check may open a GitHub login window if no valid credential exists.
echo It will not commit anything.
echo It will not push anything.
echo It will run:
echo   git ls-remote
echo   git push --dry-run
echo.
echo If GitHub opens a login window, complete it and wait.
echo Do not close the login window after the browser says success.
echo.
set "RUN_NETWORK_CHECK="
set /p "RUN_NETWORK_CHECK=Run GitHub login/readiness check now? [Y/n]: "

if /I "%RUN_NETWORK_CHECK%"=="n" (
    echo.
    echo Skipped GitHub network readiness check.
    echo.
    echo Local Git setup is complete, but GitHub login/write access was not verified.
    echo.
    pause
    exit /b 0
)

echo.
echo Checking read access to repo...
git ls-remote "%CFG_REPO_URL%" HEAD >nul 2>nul
if errorlevel 1 (
    echo.
    echo ERROR: Could not read from the GitHub repo.
    echo.
    echo Possible causes:
    echo   wrong GitHub account
    echo   repo URL is wrong
    echo   repo is private and credentials are missing
    echo   internet problem
    echo   GitHub login was cancelled
    echo.
    pause
    exit /b 1
)

echo OK: Repo is reachable.

git rev-parse --verify HEAD >nul 2>nul
if errorlevel 1 (
    echo.
    echo No local commits exist yet.
    echo Skipping push dry-run because there is nothing to test.
    echo.
    echo Login/origin setup is ready.
    echo.
    pause
    exit /b 0
)

echo.
echo Checking push readiness with dry-run only...
echo This does not upload commits.
echo.

set "DRYRUN_LOG=%TEMP%\git-login-dryrun-%RANDOM%-%RANDOM%.txt"

git push --dry-run origin "%CURRENT_BRANCH%" > "%DRYRUN_LOG%" 2>&1
set "DRYRUN_RC=%ERRORLEVEL%"

type "%DRYRUN_LOG%"

findstr /I /C:"denied to" "%DRYRUN_LOG%" >nul 2>nul
if not errorlevel 1 set "DRYRUN_PERMISSION_ERROR=1"

findstr /I /C:"403" "%DRYRUN_LOG%" >nul 2>nul
if not errorlevel 1 set "DRYRUN_PERMISSION_ERROR=1"

findstr /I /C:"Authentication failed" "%DRYRUN_LOG%" >nul 2>nul
if not errorlevel 1 set "DRYRUN_PERMISSION_ERROR=1"

findstr /I /C:"User cancelled" "%DRYRUN_LOG%" >nul 2>nul
if not errorlevel 1 set "DRYRUN_CANCELLED=1"

findstr /I /C:"User canceled" "%DRYRUN_LOG%" >nul 2>nul
if not errorlevel 1 set "DRYRUN_CANCELLED=1"

findstr /I /C:"non-fast-forward" "%DRYRUN_LOG%" >nul 2>nul
if not errorlevel 1 set "DRYRUN_HISTORY_ERROR=1"

findstr /I /C:"fetch first" "%DRYRUN_LOG%" >nul 2>nul
if not errorlevel 1 set "DRYRUN_HISTORY_ERROR=1"

findstr /I /C:"rejected" "%DRYRUN_LOG%" >nul 2>nul
if not errorlevel 1 set "DRYRUN_HISTORY_ERROR=1"

del "%DRYRUN_LOG%" >nul 2>nul

if not "%DRYRUN_RC%"=="0" (
    echo.
    echo ERROR: Push dry-run failed.
    echo.
    echo This did not push anything.
    echo.

    if defined DRYRUN_CANCELLED (
        echo GitHub login was cancelled.
        echo Run this script again and complete the GitHub login window.
        echo.
        pause
        exit /b 1
    )

    if defined DRYRUN_PERMISSION_ERROR (
        echo GitHub permission/authentication failed.
        echo The cached/login account may be wrong, or it may not have write access.
        echo.
        echo Expected account:
        echo   %CFG_GITHUB_LOGIN%
        echo.
        pause
        exit /b 1
    )

    if defined DRYRUN_HISTORY_ERROR (
        echo GitHub login may be OK, but GitHub already has commits
        echo that are not in this local repo.
        echo.
        echo Recommended next step:
        echo   git fetch origin
        echo   git merge origin/%CURRENT_BRANCH% --allow-unrelated-histories
        echo.
        echo If there are conflicts, stop and inspect them before pushing.
        echo.
        pause
        exit /b 1
    )

    echo Unknown dry-run failure.
    echo Inspect the message above.
    echo.
    pause
    exit /b 1
)

echo.
echo OK: GitHub login and push readiness check passed.
echo.
echo No commits were created.
echo No commits were pushed.
echo.
pause
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

:ShowCachedGithubCredential
set "AUTH_LOGIN="
set "FOUND_GITHUB_CRED="
set "CK_IN_GITHUB_BLOCK="

for /f "tokens=* delims=" %%A in ('cmdkey /list 2^>nul') do call :InspectCmdkeyLine "%%A"

if defined FOUND_GITHUB_CRED (
    echo Cached github.com credential appears to exist.

    if defined AUTH_LOGIN (
        echo Cached username appears to be:
        echo   %AUTH_LOGIN%
    ) else (
        echo Cached username could not be read from Windows Credential Manager.
        echo This is normal for some Git Credential Manager versions.
    )

    echo.
    echo Expected for this repo:
    echo   %CFG_GITHUB_LOGIN%
    exit /b 0
)

echo No cached github.com credential was found without prompting login.
echo Expected for this repo:
echo   %CFG_GITHUB_LOGIN%
exit /b 0

:InspectCmdkeyLine
set "CK_LINE=%~1"

echo %CK_LINE% | findstr /I "github.com" >nul 2>nul
if not errorlevel 1 (
    set "FOUND_GITHUB_CRED=1"
    set "CK_IN_GITHUB_BLOCK=1"
    exit /b 0
)

if defined CK_IN_GITHUB_BLOCK (
    echo %CK_LINE% | findstr /I "User:" >nul 2>nul
    if not errorlevel 1 (
        for /f "tokens=1,* delims=:" %%U in ("%CK_LINE%") do set "AUTH_LOGIN=%%V"
        if defined AUTH_LOGIN (
            if "!AUTH_LOGIN:~0,1!"==" " set "AUTH_LOGIN=!AUTH_LOGIN:~1!"
        )
        set "CK_IN_GITHUB_BLOCK="
        exit /b 0
    )

    echo %CK_LINE% | findstr /I "Target:" >nul 2>nul
    if not errorlevel 1 (
        set "CK_IN_GITHUB_BLOCK="
        exit /b 0
    )
)

exit /b 0

:ForgetGithubCredentials
echo.
echo Forgetting cached github.com credential...

set "CRED_REJECT=%TEMP%\git-login-cred-reject-%RANDOM%-%RANDOM%.txt"

> "%CRED_REJECT%" echo protocol=https
>> "%CRED_REJECT%" echo host=github.com
>> "%CRED_REJECT%" echo.

git credential reject < "%CRED_REJECT%" >nul 2>nul

del "%CRED_REJECT%" >nul 2>nul

cmdkey /delete:git:https://github.com >nul 2>nul
cmdkey /delete:git:https://github.com/ >nul 2>nul
cmdkey /delete:https://github.com >nul 2>nul
cmdkey /delete:github.com >nul 2>nul

echo Done.
exit /b 0