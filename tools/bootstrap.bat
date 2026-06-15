@echo off
:setup
:: ============================================================
:: bootstrap.bat
:: Generic Git project bootstrapper.
::
:: Batch style:
::   - no delayed expansion
::   - no setlocal
::   - documented functions
::   - one empty line between documented functions
::   - no empty lines inside functions
::
:: Purpose:
::   Download/install local Git using tools\GetGit.bat, then clone/update
::   a Git repository. For GitHub repositories, optionally install GitHub
::   CLI using tools\GetGitCLI.bat and run gh auth login.
::
:: Common one-line loader:
::   set "bootstrap.url=https://raw.githubusercontent.com/user/repo/main/tools/bootstrap.bat" && call curl.exe -L --fail -o bootstrap.bat "%%bootstrap.url%%" && bootstrap.bat
::
:: Inputs:
::   bootstrap.bat https://github.com/user/repo.git
::   bootstrap.bat https://github.com/user/repo/blob/main/tools/bootstrap.bat
::   bootstrap.bat repo https://github.com/user/repo.git
::   bootstrap.bat branch main
::   bootstrap.bat dir ProjectFolder
::   bootstrap.bat nologin
::
:: Environment:
::   bootstrap.url may point at this bootstrap.bat URL. If no repo URL
::   argument is supplied, the repository URL is inferred from it.
:: ============================================================
cd /d "%~dp0"
set "app.rc=0"
set "app.root=%CD%"
set "app.timestamp="
set "app.log.dir=bootstrap_logs"
set "app.log="
set "app.repo.url="
set "app.repo.host="
set "app.repo.owner="
set "app.repo.name="
set "app.repo.branch=main"
set "app.repo.dir="
set "app.repo.default.dir="
set "app.bootstrap.url="
set "app.getgit.url="
set "app.getgitcli.url="
set "app.getgit.file="
set "app.git.root=%app.root%\tools\git"
set "app.git.exe="
set "app.gh.exe="
set "app.login=1"
set "app.force="
set "app.help="
set "app.esc="
set "app.color.reset=0m"
set "app.color.red=31m"
set "app.color.green=32m"
set "app.color.yellow=33m"
set "app.color.cyan=36m"
if defined bootstrap.url set "app.bootstrap.url=%bootstrap.url%"

:main
call :InitializeBootstrap || (set "app.rc=%errorlevel%" & goto :end)
call :ParseArgs %* || (set "app.rc=%errorlevel%" & goto :end)
if defined app.help (call :ShowHelp & set "app.rc=0" & goto :end)
call :ResolveBootstrapInputs || (set "app.rc=%errorlevel%" & goto :end)
call :WriteLogHeader
call :EnsureGit || (set "app.rc=%errorlevel%" & goto :end)
call :CloneOrUpdateRepo || (set "app.rc=%errorlevel%" & goto :end)
call :MaybeInstallGitHubCLI || (set "app.rc=%errorlevel%" & goto :end)
if "%app.login%"=="1" (call :MaybeLoginGitHub || (set "app.rc=%errorlevel%" & goto :end))
call :Green OK: Bootstrap complete.
call :Yellow DIR: %app.repo.dir%
set "app.rc=0"

:end
exit /b %app.rc%

:: ============================================================
:: Function: InitializeBootstrap
:: Usage: call :InitializeBootstrap
:: Purpose: initializes timestamp, logging, and console colors.
:: Returns:
::   0 success
::   1 initialization failed
:: ============================================================
:InitializeBootstrap
call :SetESC app.esc
if errorlevel 1 set "app.esc="
if /I "%app.esc%"=="rem" set "app.esc="
call :MakeTimestamp || exit /b 1
if not exist "%app.log.dir%\" mkdir "%app.log.dir%" >nul 2>&1
set "app.log=%app.log.dir%\bootstrap.%app.timestamp%.log"
break > "%app.log%"
call :Cyan LOG: %app.log%
exit /b 0

:: ============================================================
:: Function: MakeTimestamp
:: Usage: call :MakeTimestamp
:: Purpose: creates app.timestamp in YYYY-MM-DD.HHhmm.ss format.
:: Returns:
::   0 timestamp created
::   1 timestamp failed
:: ============================================================
:MakeTimestamp
set "app.timestamp="
for /f %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Date -Format yyyy-MM-dd.HH\hmm.ss"') do set "app.timestamp=%%A"
if defined app.timestamp exit /b 0
exit /b 1

:: ============================================================
:: Function: ParseArgs
:: Usage: call :ParseArgs %*
:: Purpose: parses command-line arguments.
:: Accepted:
::   repo URL
::   URL
::   bootstrap URL
::   branch NAME
::   dir FOLDER
::   nologin
::   force
::   help
:: Returns:
::   0 success
::   2 invalid argument
:: ============================================================
:ParseArgs
if "%~1"=="" exit /b 0
if /I "%~1"=="help" (set "app.help=1" & shift & goto :ParseArgs)
if /I "%~1"=="/help" (set "app.help=1" & shift & goto :ParseArgs)
if /I "%~1"=="--help" (set "app.help=1" & shift & goto :ParseArgs)
if /I "%~1"=="/?" (set "app.help=1" & shift & goto :ParseArgs)
if /I "%~1"=="nologin" (set "app.login=0" & shift & goto :ParseArgs)
if /I "%~1"=="force" (set "app.force=1" & shift & goto :ParseArgs)
if /I "%~1"=="repo" goto :ParseArgsRepo
if /I "%~1"=="url" goto :ParseArgsRepo
if /I "%~1"=="bootstrap" goto :ParseArgsBootstrap
if /I "%~1"=="branch" goto :ParseArgsBranch
if /I "%~1"=="dir" goto :ParseArgsDir
echo %~1| findstr /I /C:"://" >nul 2>nul
if not errorlevel 1 (call :AcceptUrlArgument "%~1" & shift & goto :ParseArgs)
call :Red FAIL: unknown argument: %~1
exit /b 2
:ParseArgsRepo
if "%~2"=="" (call :Red FAIL: %~1 requires a repository URL. & exit /b 2)
set "app.repo.url=%~2"
shift
shift
goto :ParseArgs
:ParseArgsBootstrap
if "%~2"=="" (call :Red FAIL: bootstrap requires a bootstrap URL. & exit /b 2)
set "app.bootstrap.url=%~2"
shift
shift
goto :ParseArgs
:ParseArgsBranch
if "%~2"=="" (call :Red FAIL: branch requires a name. & exit /b 2)
set "app.repo.branch=%~2"
shift
shift
goto :ParseArgs
:ParseArgsDir
if "%~2"=="" (call :Red FAIL: dir requires a folder. & exit /b 2)
set "app.repo.dir=%~2"
shift
shift
goto :ParseArgs

:: ============================================================
:: Function: AcceptUrlArgument
:: Usage: call :AcceptUrlArgument "url"
:: Purpose: treats a URL argument as either a repo URL or bootstrap URL.
:: Input:
::   %~1 URL
:: Returns:
::   0 always
:: ============================================================
:AcceptUrlArgument
echo %~1| findstr /I /C:"/blob/" /C:"/raw/" /C:"raw.githubusercontent.com" >nul 2>nul
if not errorlevel 1 (set "app.bootstrap.url=%~1" & exit /b 0)
set "app.repo.url=%~1"
exit /b 0

:: ============================================================
:: Function: ShowHelp
:: Usage: call :ShowHelp
:: Purpose: prints usage and settings.
:: Returns:
::   0 always
:: ============================================================
:ShowHelp
call :Green Generic bootstrap.bat
echo.
call :Yellow Usage:
echo   bootstrap.bat https://github.com/user/repo.git
echo   bootstrap.bat repo https://github.com/user/repo.git
echo   bootstrap.bat bootstrap https://github.com/user/repo/blob/main/tools/bootstrap.bat
echo   bootstrap.bat branch main
echo   bootstrap.bat dir ProjectFolder
echo   bootstrap.bat nologin
echo   bootstrap.bat help
echo.
call :Yellow One-line loader:
echo   set "bootstrap.url=https://raw.githubusercontent.com/user/repo/main/tools/bootstrap.bat" ^&^& call curl.exe -L --fail -o bootstrap.bat "%%bootstrap.url%%" ^&^& bootstrap.bat
echo.
call :Yellow Behavior:
echo   If no repo URL is supplied, repo is inferred from bootstrap.url.
echo   Git is installed using tools\GetGit.bat.
echo   Repo is cloned or updated.
echo   For GitHub repos, GitHub CLI login is attempted unless nologin is used.
echo.
call :Yellow Active settings:
echo   Root:          %app.root%
echo   Bootstrap URL: %app.bootstrap.url%
echo   Repo URL:      %app.repo.url%
echo   Branch:        %app.repo.branch%
echo   Repo dir:      %app.repo.dir%
echo   Login:         %app.login%
exit /b 0

:: ============================================================
:: Function: ResolveBootstrapInputs
:: Usage: call :ResolveBootstrapInputs
:: Purpose: resolves repo URL, helper URLs, repo host, and repo directory.
:: Returns:
::   0 success
::   2 required URL missing or invalid
:: ============================================================
:ResolveBootstrapInputs
if not defined app.repo.url if defined app.bootstrap.url call :InferRepoFromBootstrapUrl
if not defined app.repo.url (call :Red FAIL: repository URL was not supplied and could not be inferred. & call :Yellow TRY: bootstrap.bat https://github.com/user/repo.git & exit /b 2)
call :ParseRepoUrl "%app.repo.url%"
if not defined app.repo.name (call :Red FAIL: could not parse repository name from: %app.repo.url% & exit /b 2)
if not defined app.repo.dir set "app.repo.dir=%app.root%\%app.repo.name%"
if not defined app.getgit.url call :ResolveGetGitUrl
if not defined app.getgitcli.url call :ResolveGetGitCLIUrl
set "app.getgit.file=%app.root%\bootstrap_GetGit.bat"
exit /b 0

:: ============================================================
:: Function: InferRepoFromBootstrapUrl
:: Usage: call :InferRepoFromBootstrapUrl
:: Purpose: infers app.repo.url from app.bootstrap.url.
:: Returns:
::   0 always
:: ============================================================
:InferRepoFromBootstrapUrl
call :ParseUrl "%app.bootstrap.url%"
if /I "%purl_host%"=="raw.githubusercontent.com" goto :InferRepoFromRawGitHub
if /I "%purl_host%"=="github.com" goto :InferRepoFromGitHub
if defined purl_seg1 if defined purl_seg2 set "app.repo.url=%purl_scheme%://%purl_host%/%purl_seg1%/%purl_seg2%.git"
call :ClearParseUrlVars
exit /b 0
:InferRepoFromRawGitHub
set "app.repo.url=https://github.com/%purl_seg1%/%purl_seg2%.git"
if defined purl_seg3 set "app.repo.branch=%purl_seg3%"
call :ClearParseUrlVars
exit /b 0
:InferRepoFromGitHub
if /I "%purl_seg3%"=="blob" if defined purl_seg4 set "app.repo.branch=%purl_seg4%"
if /I "%purl_seg3%"=="raw" if defined purl_seg4 set "app.repo.branch=%purl_seg4%"
set "app.repo.url=https://github.com/%purl_seg1%/%purl_seg2%.git"
call :ClearParseUrlVars
exit /b 0

:: ============================================================
:: Function: ResolveGetGitUrl
:: Usage: call :ResolveGetGitUrl
:: Purpose: resolves the URL for tools\GetGit.bat.
:: Returns:
::   0 always
:: ============================================================
:ResolveGetGitUrl
if defined app.bootstrap.url set "app.getgit.url=%app.bootstrap.url:bootstrap.bat=GetGit.bat%"
if defined app.getgit.url exit /b 0
if /I "%app.repo.host%"=="github.com" set "app.getgit.url=https://raw.githubusercontent.com/%app.repo.owner%/%app.repo.name%/%app.repo.branch%/tools/GetGit.bat"
exit /b 0

:: ============================================================
:: Function: ResolveGetGitCLIUrl
:: Usage: call :ResolveGetGitCLIUrl
:: Purpose: resolves the URL for tools\GetGitCLI.bat.
:: Returns:
::   0 always
:: ============================================================
:ResolveGetGitCLIUrl
if defined app.bootstrap.url set "app.getgitcli.url=%app.bootstrap.url:bootstrap.bat=GetGitCLI.bat%"
if defined app.getgitcli.url exit /b 0
if /I "%app.repo.host%"=="github.com" set "app.getgitcli.url=https://raw.githubusercontent.com/%app.repo.owner%/%app.repo.name%/%app.repo.branch%/tools/GetGitCLI.bat"
exit /b 0

:: ============================================================
:: Function: ParseRepoUrl
:: Usage: call :ParseRepoUrl "repoUrl"
:: Purpose: extracts host, owner, and repository name.
:: Input:
::   %~1 repository URL
:: Returns:
::   0 always
:: ============================================================
:ParseRepoUrl
set "app.repo.host="
set "app.repo.owner="
set "app.repo.name="
call :ParseUrl "%~1"
set "app.repo.host=%purl_host%"
set "app.repo.owner=%purl_seg1%"
set "app.repo.name=%purl_seg2%"
if /I "%app.repo.name:~-4%"==".git" set "app.repo.name=%app.repo.name:~0,-4%"
call :ClearParseUrlVars
exit /b 0

:: ============================================================
:: Function: ParseUrl
:: Usage: call :ParseUrl "url"
:: Purpose: parses an HTTP URL into purl_* variables.
:: Input:
::   %~1 URL
:: Output:
::   purl_scheme, purl_host, purl_seg1, purl_seg2, purl_seg3, purl_seg4
:: Returns:
::   0 always
:: ============================================================
:ParseUrl
set "purl_url=%~1"
set "purl_scheme=https"
set "purl_host="
set "purl_seg1="
set "purl_seg2="
set "purl_seg3="
set "purl_seg4="
set "purl_seg5="
for /f "tokens=1 delims=?" %%A in ("%purl_url%") do set "purl_clean=%%A"
for /f "tokens=1,* delims=:" %%A in ("%purl_clean%") do set "purl_scheme=%%A" & set "purl_after_scheme=%%B"
if "%purl_after_scheme:~0,2%"=="//" set "purl_after_scheme=%purl_after_scheme:~2%"
for /f "tokens=1,2,3,4,5,6 delims=/" %%A in ("%purl_after_scheme%") do set "purl_host=%%A" & set "purl_seg1=%%B" & set "purl_seg2=%%C" & set "purl_seg3=%%D" & set "purl_seg4=%%E" & set "purl_seg5=%%F"
exit /b 0

:: ============================================================
:: Function: ClearParseUrlVars
:: Usage: call :ClearParseUrlVars
:: Purpose: clears function variables from ParseUrl.
:: Returns:
::   0 always
:: ============================================================
:ClearParseUrlVars
for /f "tokens=1 delims==" %%V in ('set purl_ 2^>nul') do set "%%V="
exit /b 0

:: ============================================================
:: Function: WriteLogHeader
:: Usage: call :WriteLogHeader
:: Purpose: writes the bootstrap log header.
:: Returns:
::   0 always
:: ============================================================
:WriteLogHeader
>>"%app.log%" echo Generic bootstrap log
>>"%app.log%" echo Timestamp: %app.timestamp%
>>"%app.log%" echo Root: %app.root%
>>"%app.log%" echo Bootstrap URL: %app.bootstrap.url%
>>"%app.log%" echo Repo URL: %app.repo.url%
>>"%app.log%" echo Repo host: %app.repo.host%
>>"%app.log%" echo Repo owner: %app.repo.owner%
>>"%app.log%" echo Repo name: %app.repo.name%
>>"%app.log%" echo Repo branch: %app.repo.branch%
>>"%app.log%" echo Repo dir: %app.repo.dir%
exit /b 0

:: ============================================================
:: Function: EnsureGit
:: Usage: call :EnsureGit
:: Purpose: finds or installs Git.
:: Returns:
::   0 Git ready
::   3 Git install failed
:: ============================================================
:EnsureGit
call :FindGit
if not errorlevel 1 (call :Green OK: Found git: %app.git.exe% & exit /b 0)
if not defined app.getgit.url (call :Red FAIL: git.exe not found and GetGit.bat URL is unknown. & exit /b 3)
call :Yellow DO: Downloading GetGit.bat.
call :Download "%app.getgit.url%" "%app.getgit.file%" "GetGit.bat" 1024 || exit /b 3
call :Yellow DO: Installing Git.
call "%app.getgit.file%" >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: GetGit.bat failed. & call :Yellow LOG: %app.log% & exit /b 3)
call :FindGit
if errorlevel 1 (call :Red FAIL: git.exe is still missing after GetGit.bat. & call :Yellow LOG: %app.log% & exit /b 3)
call :Green OK: Git ready: %app.git.exe%
exit /b 0

:: ============================================================
:: Function: FindGit
:: Usage: call :FindGit
:: Purpose: locates git.exe.
:: Returns:
::   0 found
::   1 missing
:: ============================================================
:FindGit
set "app.git.exe="
if exist "%app.git.root%\cmd\git.exe" for %%A in ("%app.git.root%\cmd\git.exe") do set "app.git.exe=%%~fA"
if not defined app.git.exe for %%P in (git.exe) do set "app.git.exe=%%~$PATH:P"
if defined app.git.exe exit /b 0
exit /b 1

:: ============================================================
:: Function: CloneOrUpdateRepo
:: Usage: call :CloneOrUpdateRepo
:: Purpose: clones or updates the repository.
:: Returns:
::   0 success
::   4 clone/update failed
:: ============================================================
:CloneOrUpdateRepo
if exist "%app.repo.dir%\.git\" goto :CloneOrUpdateRepoPull
if exist "%app.repo.dir%\" if not defined app.force (call :Red FAIL: target folder exists but is not a git repo: %app.repo.dir% & call :Yellow TRY: bootstrap.bat force & exit /b 4)
if exist "%app.repo.dir%\" if defined app.force rmdir /S /Q "%app.repo.dir%" >> "%app.log%" 2>&1
call :Yellow DO: Cloning %app.repo.url%.
"%app.git.exe%" clone --branch "%app.repo.branch%" "%app.repo.url%" "%app.repo.dir%" >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: git clone failed. & call :Yellow LOG: %app.log% & exit /b 4)
call :Green OK: Cloned: %app.repo.dir%
exit /b 0
:CloneOrUpdateRepoPull
call :Yellow DO: Updating existing repo.
"%app.git.exe%" -C "%app.repo.dir%" fetch --all --prune >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: git fetch failed. & call :Yellow LOG: %app.log% & exit /b 4)
"%app.git.exe%" -C "%app.repo.dir%" checkout "%app.repo.branch%" >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: git checkout failed: %app.repo.branch% & call :Yellow LOG: %app.log% & exit /b 4)
"%app.git.exe%" -C "%app.repo.dir%" pull --ff-only >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: git pull failed. & call :Yellow LOG: %app.log% & exit /b 4)
call :Green OK: Updated: %app.repo.dir%
exit /b 0

:: ============================================================
:: Function: MaybeInstallGitHubCLI
:: Usage: call :MaybeInstallGitHubCLI
:: Purpose: installs GitHub CLI for GitHub repositories when helper exists.
:: Returns:
::   0 success or skipped
::   5 install failed
:: ============================================================
:MaybeInstallGitHubCLI
if /I not "%app.repo.host%"=="github.com" (call :Yellow SKIP: GitHub CLI login is only handled for github.com repos. & exit /b 0)
call :FindGitHubCLI
if not errorlevel 1 (call :Green OK: Found gh: %app.gh.exe% & exit /b 0)
if exist "%app.repo.dir%\tools\GetGitCLI.bat" goto :MaybeInstallGitHubCLIFromRepo
if not defined app.getgitcli.url (call :Yellow SKIP: GetGitCLI.bat URL unknown. & exit /b 0)
call :Yellow DO: Downloading GetGitCLI.bat.
if not exist "%app.repo.dir%\tools\" mkdir "%app.repo.dir%\tools" >nul 2>&1
call :Download "%app.getgitcli.url%" "%app.repo.dir%\tools\GetGitCLI.bat" "GetGitCLI.bat" 1024 || exit /b 5
:MaybeInstallGitHubCLIFromRepo
call :Yellow DO: Installing GitHub CLI.
pushd "%app.repo.dir%" >nul
call "tools\GetGitCLI.bat" >> "%app.log%" 2>&1
set "mighc.rc=%errorlevel%"
popd >nul
if not "%mighc.rc%"=="0" (set "mighc.rc=" & call :Red FAIL: GetGitCLI.bat failed. & call :Yellow LOG: %app.log% & exit /b 5)
set "mighc.rc="
call :FindGitHubCLI
if errorlevel 1 (call :Red FAIL: gh.exe is still missing after GetGitCLI.bat. & call :Yellow LOG: %app.log% & exit /b 5)
call :Green OK: GitHub CLI ready: %app.gh.exe%
exit /b 0

:: ============================================================
:: Function: FindGitHubCLI
:: Usage: call :FindGitHubCLI
:: Purpose: locates gh.exe.
:: Returns:
::   0 found
::   1 missing
:: ============================================================
:FindGitHubCLI
set "app.gh.exe="
if exist "%app.repo.dir%\tools\gh\bin\gh.exe" for %%A in ("%app.repo.dir%\tools\gh\bin\gh.exe") do set "app.gh.exe=%%~fA"
if not defined app.gh.exe if exist "%app.root%\tools\gh\bin\gh.exe" for %%A in ("%app.root%\tools\gh\bin\gh.exe") do set "app.gh.exe=%%~fA"
if not defined app.gh.exe for %%P in (gh.exe) do set "app.gh.exe=%%~$PATH:P"
if defined app.gh.exe exit /b 0
exit /b 1

:: ============================================================
:: Function: MaybeLoginGitHub
:: Usage: call :MaybeLoginGitHub
:: Purpose: runs GitHub CLI login when needed.
:: Returns:
::   0 logged in or skipped
::   6 login failed
:: ============================================================
:MaybeLoginGitHub
if /I not "%app.repo.host%"=="github.com" exit /b 0
call :FindGitHubCLI
if errorlevel 1 (call :Yellow SKIP: gh.exe not available; login skipped. & exit /b 0)
"%app.gh.exe%" auth status >> "%app.log%" 2>&1
if not errorlevel 1 (call :Green OK: GitHub CLI already logged in. & exit /b 0)
call :Yellow DO: GitHub login.
"%app.gh.exe%" auth login --web --git-protocol https
if errorlevel 1 (call :Red FAIL: GitHub login failed. & exit /b 6)
"%app.gh.exe%" auth setup-git >> "%app.log%" 2>&1
if errorlevel 1 (call :Yellow WARN: gh auth setup-git failed. & call :Yellow LOG: %app.log% & exit /b 0)
call :Green OK: GitHub login ready.
exit /b 0

:: ============================================================
:: Function: Download
:: Usage: call :Download "url" "file" "name" minBytes
:: Purpose: downloads a file using curl first, then PowerShell.
:: Input:
::   %~1 URL
::   %~2 file
::   %~3 display name
::   %~4 minimum byte count
:: Returns:
::   0 success
::   1 failed
:: ============================================================
:Download
set "dwn.url=%~1"
set "dwn.file=%~2"
set "dwn.name=%~3"
set "dwn.min=%~4"
if not defined dwn.min set "dwn.min=1024"
if exist "%dwn.file%" del /Q "%dwn.file%" >nul 2>&1
where curl.exe >nul 2>nul
if errorlevel 1 goto :DownloadPowerShell
curl.exe -L --fail --retry 3 --output "%dwn.file%" "%dwn.url%" >> "%app.log%" 2>&1
if not errorlevel 1 goto :DownloadValidate
:DownloadPowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%dwn.url%' -OutFile '%dwn.file%'" >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: download failed: %dwn.name% & call :Yellow URL: %dwn.url% & call :ClearDownloadVars & exit /b 1)
:DownloadValidate
if not exist "%dwn.file%" (call :Red FAIL: download did not create file: %dwn.file% & call :ClearDownloadVars & exit /b 1)
for %%Z in ("%dwn.file%") do if %%~zZ LSS %dwn.min% (call :Red FAIL: downloaded file is too small: %dwn.file% & call :ClearDownloadVars & exit /b 1)
call :ClearDownloadVars
exit /b 0

:: ============================================================
:: Function: ClearDownloadVars
:: Usage: call :ClearDownloadVars
:: Purpose: clears function-local download variables.
:: Returns:
::   0 always
:: ============================================================
:ClearDownloadVars
for /f "tokens=1 delims==" %%V in ('set dwn. 2^>nul') do set "%%V="
exit /b 0

:: ============================================================
:: Function: SetESC
:: Usage: call :SetESC outputVariable
:: Purpose: captures ANSI escape character into a variable.
:: Input:
::   %~1 output variable name
:: Returns:
::   0 success
::   2 missing output variable
:: ============================================================
:SetESC
set "se.out=%~1"
if not defined se.out exit /b 2
for /f %%A in ('echo prompt $E^| cmd') do set "%se.out%=%%A"
set "se.out="
exit /b 0

:: ============================================================
:: Function: Green
:: Usage: call :Green message
:: Purpose: prints a green status line.
:: Returns:
::   0 always
:: ============================================================
:Green
if defined app.esc (echo %app.esc%[%app.color.green%%*%app.esc%[%app.color.reset%) else (echo %*)
if defined app.log >>"%app.log%" echo %*
exit /b 0

:: ============================================================
:: Function: Yellow
:: Usage: call :Yellow message
:: Purpose: prints a yellow status line.
:: Returns:
::   0 always
:: ============================================================
:Yellow
if defined app.esc (echo %app.esc%[%app.color.yellow%%*%app.esc%[%app.color.reset%) else (echo %*)
if defined app.log >>"%app.log%" echo %*
exit /b 0

:: ============================================================
:: Function: Red
:: Usage: call :Red message
:: Purpose: prints a red status line.
:: Returns:
::   0 always
:: ============================================================
:Red
if defined app.esc (echo %app.esc%[%app.color.red%%*%app.esc%[%app.color.reset%) else (echo %*)
if defined app.log >>"%app.log%" echo %*
exit /b 0

:: ============================================================
:: Function: Cyan
:: Usage: call :Cyan message
:: Purpose: prints a cyan status line.
:: Returns:
::   0 always
:: ============================================================
:Cyan
if defined app.esc (echo %app.esc%[%app.color.cyan%%*%app.esc%[%app.color.reset%) else (echo %*)
if defined app.log >>"%app.log%" echo %*
exit /b 0
