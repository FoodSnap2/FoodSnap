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
echo  GitHub login check
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
echo This script will not commit, push, pull, merge, or dry-run push.
echo It only checks/starts GitHub login.
echo.
pause

call :FindGitCredentialManager

set "EXISTING_LOCAL_NAME="
set "EXISTING_LOCAL_EMAIL="
set "EXISTING_GLOBAL_NAME="
set "EXISTING_GLOBAL_EMAIL="
set "CURRENT_BRANCH="

if exist ".git" (
    for /f "delims=" %%A in ('git config --local --get user.name 2^>nul') do set "EXISTING_LOCAL_NAME=%%A"
    for /f "delims=" %%A in ('git config --local --get user.email 2^>nul') do set "EXISTING_LOCAL_EMAIL=%%A"
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
    echo It does not need to be stored in build_config.bat.
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
if defined GCM_CMD (
    git config --global credential.helper manager
    echo Git Credential Manager configured.
) else (
    echo WARNING: Git Credential Manager was not found.
    echo Git may require username/token prompts later.
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
echo Checking currently stored GitHub login without opening browser...
call :DetectGithubLogin

echo.
echo GitHub login status:
echo ------------------------------------------------------------
if defined LOGIN_MATCH (
    echo OK: You appear to be logged in as the expected GitHub account:
    echo   %CFG_GITHUB_LOGIN%
    echo.
    echo No login is needed.
    echo.
    pause
    exit /b 0
)

if defined FOUND_GITHUB_CRED (
    echo A GitHub credential appears to exist.
    if defined AUTH_LOGIN (
        echo Detected login:
        echo   %AUTH_LOGIN%
    ) else (
        echo The exact username could not be read without opening login.
    )
    echo.
    echo Expected login:
    echo   %CFG_GITHUB_LOGIN%
    echo.
) else (
    echo No stored GitHub credential was found.
    echo.
    echo Expected login:
    echo   %CFG_GITHUB_LOGIN%
    echo.
)
echo ------------------------------------------------------------

echo.
set "START_LOGIN="
set /p "START_LOGIN=Start GitHub login now? [Y/n]: "

if /I "%START_LOGIN%"=="n" (
    echo.
    echo Cancelled. No GitHub login was started.
    echo.
    pause
    exit /b 1
)

if defined FOUND_GITHUB_CRED (
    echo.
    set "CLEAR_FIRST="
    set /p "CLEAR_FIRST=Clear existing github.com credentials first? [Y/n]: "
    if /I not "!CLEAR_FIRST!"=="n" (
        call :ForgetGithubCredentials
    )
)

echo.
echo Starting GitHub login...
echo If a GitHub window opens, complete the login and wait for it to close by itself.
echo.

call :StartGithubLogin
if errorlevel 1 (
    echo.
    echo ERROR: GitHub login command failed or was cancelled.
    echo.
    pause
    exit /b 1
)

echo.
echo Rechecking stored GitHub login...
call :DetectGithubLogin

echo.
echo Final GitHub login status:
echo ------------------------------------------------------------
if defined LOGIN_MATCH (
    echo OK: You appear to be logged in as:
    echo   %CFG_GITHUB_LOGIN%
    echo.
    echo No commits were created.
    echo Nothing was pushed.
    echo.
    pause
    exit /b 0
)

if defined FOUND_GITHUB_CRED (
    echo A GitHub credential now appears to exist.
    if defined AUTH_LOGIN (
        echo Detected login:
        echo   %AUTH_LOGIN%
    ) else (
        echo The exact username could not be read without opening login.
    )
    echo.
    echo Expected login:
    echo   %CFG_GITHUB_LOGIN%
    echo.
    echo Login may be usable, but this script could not prove the account name.
    echo No commits were created. Nothing was pushed.
    echo.
    pause
    exit /b 0
)

echo No GitHub credential was found after login.
echo.
pause
exit /b 1

:FindGitCredentialManager
set "GCM_CMD="

git credential-manager --version >nul 2>nul
if not errorlevel 1 (
    set "GCM_CMD=git credential-manager"
    exit /b 0
)

git credential-manager-core --version >nul 2>nul
if not errorlevel 1 (
    set "GCM_CMD=git credential-manager-core"
    exit /b 0
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

:DetectGithubLogin
set "FOUND_GITHUB_CRED="
set "AUTH_LOGIN="
set "LOGIN_MATCH="

call :DetectGithubLoginWithGcm
if defined LOGIN_MATCH exit /b 0

call :DetectGithubLoginWithCmdkey
if defined LOGIN_MATCH exit /b 0

exit /b 0

:DetectGithubLoginWithGcm
if not defined GCM_CMD exit /b 0

set "GCM_LIST_FILE=%TEMP%\git-login-gcm-list-%RANDOM%-%RANDOM%.txt"

%GCM_CMD% github list > "%GCM_LIST_FILE%" 2>&1
if errorlevel 1 (
    del "%GCM_LIST_FILE%" >nul 2>nul
    exit /b 0
)

findstr /I /C:"github.com" "%GCM_LIST_FILE%" >nul 2>nul
if not errorlevel 1 set "FOUND_GITHUB_CRED=1"

findstr /I /C:"%CFG_GITHUB_LOGIN%" "%GCM_LIST_FILE%" >nul 2>nul
if not errorlevel 1 (
    set "FOUND_GITHUB_CRED=1"
    set "AUTH_LOGIN=%CFG_GITHUB_LOGIN%"
    set "LOGIN_MATCH=1"
)

del "%GCM_LIST_FILE%" >nul 2>nul
exit /b 0

:DetectGithubLoginWithCmdkey
set "CK_IN_GITHUB_BLOCK="

for /f "tokens=* delims=" %%A in ('cmdkey /list 2^>nul') do call :InspectCmdkeyLine "%%A"

if defined AUTH_LOGIN (
    if /I "%AUTH_LOGIN%"=="%CFG_GITHUB_LOGIN%" set "LOGIN_MATCH=1"
)

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

:StartGithubLogin
if defined GCM_CMD (
    %GCM_CMD% github login
    if not errorlevel 1 exit /b 0
)

echo.
echo Git Credential Manager direct login was unavailable or failed.
echo Trying fallback credential prompt...
echo.

set "CRED_IN=%TEMP%\git-login-cred-in-%RANDOM%-%RANDOM%.txt"

> "%CRED_IN%" echo protocol=https
>> "%CRED_IN%" echo host=github.com
>> "%CRED_IN%" echo path=%REPO_OWNER%/%REPO_NAME%.git
>> "%CRED_IN%" echo.

git credential fill < "%CRED_IN%" >nul
set "FILL_RC=%ERRORLEVEL%"

del "%CRED_IN%" >nul 2>nul

exit /b %FILL_RC%

:ForgetGithubCredentials
echo.
echo Forgetting cached github.com credentials...

set "CRED_REJECT=%TEMP%\git-login-cred-reject-%RANDOM%-%RANDOM%.txt"

> "%CRED_REJECT%" echo protocol=https
>> "%CRED_REJECT%" echo host=github.com
>> "%CRED_REJECT%" echo.

git credential reject < "%CRED_REJECT%" >nul 2>nul

del "%CRED_REJECT%" >nul 2>nul

if defined GCM_CMD (
    %GCM_CMD% github logout >nul 2>nul
)

cmdkey /delete:git:https://github.com >nul 2>nul
cmdkey /delete:git:https://github.com/ >nul 2>nul
cmdkey /delete:https://github.com >nul 2>nul
cmdkey /delete:github.com >nul 2>nul

echo Done.
exit /b 0