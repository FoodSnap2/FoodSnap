@echo off
:setup
:: ============================================================
:: bootstrap.bat
:: Generic project bootstrapper.
::
:: Batch style:
::   - no delayed expansion
::   - no setlocal
::   - documented functions
::   - one empty line between documented functions
::   - no empty lines inside functions
::
:: Default loader:
::   cd /d %TEMP% & set "bootstrap=https://raw.githubusercontent.com/OWNER/REPO/main/tools/bootstrap.bat" & call curl.exe -sSLO "%bootstrap%" & bootstrap
::
:: Behavior:
::   - infers repo URL from the bootstrap variable when possible
::   - downloads tools\GetGit.bat
::   - installs local Git if needed
::   - clones or updates the project
::   - installs GitHub CLI for GitHub repos if tools\GetGitCLI.bat exists
::   - logs in with gh unless nologin is used
::   - detects write permission to original GitHub repo
::   - offers to create a fork when write access is missing
::   - asks whether to move the project folder at the end
::   - auto mode clones, logs in unless skipped, forks when needed, moves to Documents, and builds
:: ============================================================
cd /d "%~dp0"
set "app.rc=0"
set "app.root=%CD%"
set "app.timestamp="
set "app.log.dir=%CD%\bootstrap_logs"
set "app.log="
set "app.bootstrap="
if defined bootstrap set "app.bootstrap=%bootstrap%"
set "app.repo.url="
set "app.repo.host=generic"
set "app.repo.owner="
set "app.repo.name="
set "app.repo.folder="
set "app.repo.dir="
set "app.branch=main"
set "app.raw.base="
set "app.getgit.url="
set "app.getgh.url="
set "app.tools=%CD%\tools"
set "app.git=%CD%\tools\git\cmd\git.exe"
set "app.gh="
set "app.github.user="
set "app.github.permission="
set "app.fork.mode=ask"
set "app.move.mode=ask"
set "app.login=1"
set "app.help="
set "app.menu="
set "app.auto="
set "app.esc="
set "app.color.reset=0m"
set "app.color.red=31m"
set "app.color.green=32m"
set "app.color.yellow=33m"
set "app.color.cyan=36m"
:main
call :InitializeBootstrap || goto :end_fail
call :ParseArgs %* || goto :end_fail
if defined app.help (call :ShowHelp & goto :end)
call :ResolveRepo || goto :end_fail
call :BuildHelperUrls || goto :end_fail
if defined app.menu (call :ShowBootstrapMenu & goto :end)
if defined app.auto (call :RunAutoBootstrap || goto :end_fail)
if defined app.auto goto :end
call :RunDefaultBootstrap || goto :end_fail
goto :end
:end_fail
set "app.rc=1"
:end
exit /b %app.rc%

:: ============================================================
:: Function: InitializeBootstrap
:: Usage: call :InitializeBootstrap
:: Purpose: initializes timestamp, log path, and console colors.
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
:: Purpose: parses bootstrap command-line arguments.
:: Accepted:
::   repo URL
::   branch NAME
::   dir PATH
::   fork ask|yes|no
::   move ask|no
::   nologin
::   auto
::   help, /help, --help, /?
:: Returns:
::   0 success
::   2 invalid argument
:: ============================================================
:ParseArgs
if "%~1"=="" exit /b 0
if /I "%~1"=="repo" goto :ParseArgsRepo
if /I "%~1"=="branch" goto :ParseArgsBranch
if /I "%~1"=="dir" goto :ParseArgsDir
if /I "%~1"=="fork" goto :ParseArgsFork
if /I "%~1"=="move" goto :ParseArgsMove
if /I "%~1"=="nologin" (set "app.login=" & shift & goto :ParseArgs)
if /I "%~1"=="auto" (set "app.auto=1" & set "app.fork.mode=yes" & shift & goto :ParseArgs)
if /I "%~1"=="menu" (set "app.menu=1" & shift & goto :ParseArgs)
if /I "%~1"=="help" (set "app.help=1" & shift & goto :ParseArgs)
if /I "%~1"=="/help" (set "app.help=1" & shift & goto :ParseArgs)
if /I "%~1"=="--help" (set "app.help=1" & shift & goto :ParseArgs)
if /I "%~1"=="/?" (set "app.help=1" & shift & goto :ParseArgs)
echo %~1 | findstr /I /R "^http:// ^https:// ^git@ " >nul 2>nul
if not errorlevel 1 (set "app.repo.url=%~1" & shift & goto :ParseArgs)
call :Red FAIL: unknown argument: %~1
exit /b 2
:ParseArgsRepo
if "%~2"=="" (call :Red FAIL: repo requires a URL. & exit /b 2)
set "app.repo.url=%~2"
shift
shift
goto :ParseArgs
:ParseArgsBranch
if "%~2"=="" (call :Red FAIL: branch requires a name. & exit /b 2)
set "app.branch=%~2"
shift
shift
goto :ParseArgs
:ParseArgsDir
if "%~2"=="" (call :Red FAIL: dir requires a path. & exit /b 2)
for %%A in ("%~2") do set "app.repo.dir=%%~fA"
shift
shift
goto :ParseArgs
:ParseArgsFork
if "%~2"=="" (call :Red FAIL: fork requires ask, yes, or no. & exit /b 2)
if /I "%~2"=="ask" (set "app.fork.mode=ask" & shift & shift & goto :ParseArgs)
if /I "%~2"=="yes" (set "app.fork.mode=yes" & shift & shift & goto :ParseArgs)
if /I "%~2"=="no" (set "app.fork.mode=no" & shift & shift & goto :ParseArgs)
call :Red FAIL: fork requires ask, yes, or no.
exit /b 2
:ParseArgsMove
if "%~2"=="" (call :Red FAIL: move requires ask or no. & exit /b 2)
if /I "%~2"=="ask" (set "app.move.mode=ask" & shift & shift & goto :ParseArgs)
if /I "%~2"=="no" (set "app.move.mode=no" & shift & shift & goto :ParseArgs)
call :Red FAIL: move requires ask or no.
exit /b 2

:: ============================================================
:: Function: ShowHelp
:: Usage: call :ShowHelp
:: Purpose: prints bootstrap usage.
:: Returns:
::   0 always
:: ============================================================
:ShowHelp
call :Green Generic bootstrap.bat
echo.
call :Yellow Compact loader:
echo   cd /d %%TEMP%% ^& set "bootstrap=https://raw.githubusercontent.com/OWNER/REPO/main/tools/bootstrap.bat" ^& call curl.exe -sSLO "%%bootstrap%%" ^& bootstrap
echo.
call :Yellow Usage:
echo   bootstrap.bat
echo   bootstrap.bat https://github.com/OWNER/REPO.git
echo   bootstrap.bat repo URL branch main dir C:\Project
echo   bootstrap.bat menu
echo   bootstrap.bat auto
echo   bootstrap.bat auto nologin
echo   bootstrap.bat nologin
echo   bootstrap.bat fork ask
echo   bootstrap.bat fork yes
echo   bootstrap.bat fork no
echo   bootstrap.bat move ask
echo   bootstrap.bat move no
echo.
call :Yellow Defaults:
echo   repo:    inferred from bootstrap variable when possible
echo   branch:  %app.branch%
echo   fork:    %app.fork.mode%
echo   move:    %app.move.mode%
echo   login:   %app.login%
echo   menu:    %app.menu%
echo   auto:    %app.auto%
echo   log:     %app.log%
exit /b 0

:: ============================================================
:: Function: ResolveRepo
:: Usage: call :ResolveRepo
:: Purpose: resolves repo URL, host, owner, repo name, branch, raw helper base, and clone folder.
:: Returns:
::   0 resolved
::   1 repo could not be resolved
:: ============================================================
:ResolveRepo
set "ro_line="
for /f "delims=" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$repo=[Environment]::GetEnvironmentVariable('app.repo.url'); $bs=[Environment]::GetEnvironmentVariable('app.bootstrap'); $branch=[Environment]::GetEnvironmentVariable('app.branch'); $host='generic'; $owner=''; $name=''; $raw=''; if(-not $branch){$branch='main'}; if((-not $repo) -and $bs){$u=$bs -replace '\?raw=1$',''; if($u -match '^https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)/(.*)/bootstrap\.bat$'){$owner=$Matches[1];$name=$Matches[2];$branch=$Matches[3];$repo='https://github.com/'+$owner+'/'+$name+'.git';$host='github';$raw='https://raw.githubusercontent.com/'+$owner+'/'+$name+'/'+$branch+'/'+$Matches[4]} elseif($u -match '^https://github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.*)/bootstrap\.bat$'){$owner=$Matches[1];$name=$Matches[2];$branch=$Matches[3];$repo='https://github.com/'+$owner+'/'+$name+'.git';$host='github';$raw='https://raw.githubusercontent.com/'+$owner+'/'+$name+'/'+$branch+'/'+$Matches[4]} else {$repo=''; $raw=($u -replace '/[^/]+$','')}}; if($repo -match '^https://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$'){$owner=$Matches[1];$name=$Matches[2];$host='github'; if(-not $raw){$raw='https://raw.githubusercontent.com/'+$owner+'/'+$name+'/'+$branch+'/tools'}; if($repo -notmatch '\.git$'){$repo='https://github.com/'+$owner+'/'+$name+'.git'}}; if(-not $name -and $repo){$name=($repo -replace '.*/','' -replace '\.git$','')}; if(-not $repo){exit 1}; Write-Output ($repo+'|'+$host+'|'+$owner+'|'+$name+'|'+$branch+'|'+$raw+'|'+$name)"') do set "ro_line=%%A"
if not defined ro_line (call :Red FAIL: could not resolve repo URL. & call :Yellow TIP: set bootstrap=URL or pass bootstrap.bat repo URL & exit /b 1)
for /f "tokens=1-7 delims=|" %%A in ("%ro_line%") do set "app.repo.url=%%A" & set "app.repo.host=%%B" & set "app.repo.owner=%%C" & set "app.repo.name=%%D" & set "app.branch=%%E" & set "app.raw.base=%%F" & set "app.repo.folder=%%G"
if not defined app.repo.dir for %%A in ("%app.root%\%app.repo.folder%") do set "app.repo.dir=%%~fA"
call :Green OK: Repo: %app.repo.url%
call :Green OK: Folder: %app.repo.dir%
set "ro_line="
exit /b 0

:: ============================================================
:: Function: BuildHelperUrls
:: Usage: call :BuildHelperUrls
:: Purpose: builds GetGit and GetGitCLI helper URLs.
:: Returns:
::   0 helper URLs available
::   1 helper URLs unavailable
:: ============================================================
:BuildHelperUrls
if defined app.raw.base set "app.getgit.url=%app.raw.base%/GetGit.bat"
if defined app.raw.base set "app.getgh.url=%app.raw.base%/GetGitCLI.bat"
if defined app.getgit.url exit /b 0
call :Yellow WARN: helper URL could not be inferred; system Git must already exist.
exit /b 0

:: ============================================================
:: Function: RunDefaultBootstrap
:: Usage: call :RunDefaultBootstrap
:: Purpose: runs the normal bootstrap workflow.
:: Returns:
::   0 complete
::   1 failed
:: ============================================================
:RunDefaultBootstrap
call :EnsureGit || exit /b 1
call :CloneOrUpdateRepo || exit /b 1
if /I "%app.repo.host%"=="github" call :EnsureGitHubCLI
if /I "%app.repo.host%"=="github" if defined app.login call :LoginGitHub
if /I "%app.repo.host%"=="github" call :MaybeOfferFork
call :MaybeMoveRepo || exit /b 1
call :Green OK: Bootstrap complete.
call :Green DIR: %app.repo.dir%
exit /b 0

:: ============================================================
:: Function: RunAutoBootstrap
:: Usage: call :RunAutoBootstrap
:: Purpose: runs the automatic bootstrap workflow: clone, optional login, fork if needed, move to Documents, then build.
:: Returns:
::   0 complete
::   1 failed
:: ============================================================
:RunAutoBootstrap
call :Yellow AUTO: clone/update repo.
call :EnsureGit || exit /b 1
call :CloneOrUpdateRepo || exit /b 1
if /I "%app.repo.host%"=="github" call :EnsureGitHubCLI
if /I "%app.repo.host%"=="github" call :AutoLoginGitHub
if /I "%app.repo.host%"=="github" call :AutoForkIfNeeded
call :MoveRepoToDocuments || exit /b 1
call :RunRepoBuild || exit /b 1
call :Green OK: Auto bootstrap complete.
call :Green DIR: %app.repo.dir%
exit /b 0

:: ============================================================
:: Function: ShowBootstrapMenu
:: Usage: call :ShowBootstrapMenu
:: Purpose: shows an interactive DOS-style bootstrap menu.
:: Returns:
::   0 always
:: ============================================================
:ShowBootstrapMenu
call :MenuDraw
set "sbm_choice="
set /p "sbm_choice=Choose an action: "
if not defined sbm_choice goto :ShowBootstrapMenu
if "%sbm_choice%"=="1" call :MenuCloneRepo
if "%sbm_choice%"=="2" call :MenuLoginGitHub
if "%sbm_choice%"=="3" call :MenuForkRepo
if "%sbm_choice%"=="4" call :MenuRunPrepare
if "%sbm_choice%"=="5" call :MenuRunBuild
if "%sbm_choice%"=="6" call :MenuRunInstall
if "%sbm_choice%"=="7" call :MaybeMoveRepo
if "%sbm_choice%"=="8" call :RunDefaultBootstrap
if "%sbm_choice%"=="9" call :RunAutoBootstrap
if "%sbm_choice%"=="0" goto :ShowBootstrapMenuExit
if /I "%sbm_choice%"=="q" goto :ShowBootstrapMenuExit
if /I "%sbm_choice%"=="x" goto :ShowBootstrapMenuExit
echo.
pause
goto :ShowBootstrapMenu
:ShowBootstrapMenuExit
set "sbm_choice="
exit /b 0

:: ============================================================
:: Function: MenuDraw
:: Usage: call :MenuDraw
:: Purpose: draws the colorized DOS-style bootstrap menu.
:: Returns:
::   0 always
:: ============================================================
:MenuDraw
cls
call :Cyan +------------------------------------------------------------+
call :Cyan ^|                   FoodSnap Bootstrap Menu                 ^|
call :Cyan +------------------------------------------------------------+
call :Green ^|  1  Clone or update repo                                 ^|
call :Green ^|  2  Log in to GitHub                                     ^|
call :Green ^|  3  Fork repo / configure remotes                        ^|
call :Green ^|  4  Run prepare.bat                                      ^|
call :Green ^|  5  Run build.bat                                        ^|
call :Green ^|  6  Run install.bat                                      ^|
call :Green ^|  7  Move project folder                                  ^|
call :Green ^|  8  Run full bootstrap                                   ^|
call :Green ^|  9  Run auto bootstrap to Documents and build            ^|
call :Yellow ^|  0  Exit                                                 ^|
call :Cyan +------------------------------------------------------------+
call :Yellow Repo: %app.repo.url%
call :Yellow Dir:  %app.repo.dir%
echo.
exit /b 0

:: ============================================================
:: Function: MenuCloneRepo
:: Usage: call :MenuCloneRepo
:: Purpose: ensures Git exists and clones or updates the repo.
:: Returns:
::   0 repo ready
::   1 failed
:: ============================================================
:MenuCloneRepo
call :EnsureGit || exit /b 1
call :CloneOrUpdateRepo || exit /b 1
exit /b 0

:: ============================================================
:: Function: MenuLoginGitHub
:: Usage: call :MenuLoginGitHub
:: Purpose: installs GitHub CLI when possible and logs in.
:: Returns:
::   0 login complete or skipped
::   1 failed
:: ============================================================
:MenuLoginGitHub
if /I not "%app.repo.host%"=="github" (call :Yellow SKIP: login is only implemented for GitHub repos. & exit /b 0)
call :MenuCloneRepo || exit /b 1
call :EnsureGitHubCLI
call :LoginGitHub
exit /b 0

:: ============================================================
:: Function: MenuForkRepo
:: Usage: call :MenuForkRepo
:: Purpose: checks GitHub write access and offers to create/configure a fork.
:: Returns:
::   0 complete or skipped
::   1 failed
:: ============================================================
:MenuForkRepo
if /I not "%app.repo.host%"=="github" (call :Yellow SKIP: automatic fork creation is only implemented for GitHub repos. & exit /b 0)
call :MenuCloneRepo || exit /b 1
call :EnsureGitHubCLI
call :LoginGitHub
call :MaybeOfferFork
exit /b 0

:: ============================================================
:: Function: MenuRunPrepare
:: Usage: call :MenuRunPrepare
:: Purpose: runs prepare.bat inside the repo.
:: Returns:
::   0 prepare succeeded
::   1 prepare failed or missing
:: ============================================================
:MenuRunPrepare
call :MenuCloneRepo || exit /b 1
if not exist "%app.repo.dir%\prepare.bat" (call :Red FAIL: prepare.bat not found in repo. & exit /b 1)
call :Yellow DO: Running prepare.bat.
pushd "%app.repo.dir%" >nul
call prepare.bat
set "mrp_rc=%errorlevel%"
popd
if not "%mrp_rc%"=="0" (call :Red FAIL: prepare.bat failed with exit code %mrp_rc%. & set "mrp_rc=" & exit /b 1)
set "mrp_rc="
call :Green OK: prepare.bat finished.
exit /b 0

:: ============================================================
:: Function: RunRepoBuild
:: Usage: call :RunRepoBuild
:: Purpose: runs build.bat inside app.repo.dir.
:: Returns:
::   0 build succeeded
::   1 build failed or missing
:: ============================================================
:RunRepoBuild
if not exist "%app.repo.dir%\build.bat" (call :Red FAIL: build.bat not found in repo. & exit /b 1)
call :Yellow DO: Running build.bat.
pushd "%app.repo.dir%" >nul
call build.bat
set "rrb_rc=%errorlevel%"
popd
if not "%rrb_rc%"=="0" (call :Red FAIL: build.bat failed with exit code %rrb_rc%. & set "rrb_rc=" & exit /b 1)
set "rrb_rc="
call :Green OK: build.bat finished.
exit /b 0

:: ============================================================
:: Function: MenuRunBuild
:: Usage: call :MenuRunBuild
:: Purpose: runs build.bat inside the repo.
:: Returns:
::   0 build succeeded
::   1 build failed or missing
:: ============================================================
:MenuRunBuild
call :MenuCloneRepo || exit /b 1
call :RunRepoBuild
exit /b %errorlevel%

:: ============================================================
:: Function: MenuRunInstall
:: Usage: call :MenuRunInstall
:: Purpose: runs install.bat inside the repo.
:: Returns:
::   0 install succeeded
::   1 install failed or missing
:: ============================================================
:MenuRunInstall
call :MenuCloneRepo || exit /b 1
if not exist "%app.repo.dir%\install.bat" (call :Red FAIL: install.bat not found in repo. & exit /b 1)
call :Yellow DO: Running install.bat.
pushd "%app.repo.dir%" >nul
call install.bat
set "mri_rc=%errorlevel%"
popd
if not "%mri_rc%"=="0" (call :Red FAIL: install.bat failed with exit code %mri_rc%. & set "mri_rc=" & exit /b 1)
set "mri_rc="
call :Green OK: install.bat finished.
exit /b 0

:: ============================================================
:: Function: EnsureGit
:: Usage: call :EnsureGit
:: Purpose: ensures git.exe is available, installing local Git through GetGit.bat when possible.
:: Returns:
::   0 git available
::   1 git unavailable
:: ============================================================
:EnsureGit
call :ResolveGit
if not errorlevel 1 exit /b 0
if not defined app.getgit.url (call :Red FAIL: git.exe not found and GetGit.bat URL is unknown. & exit /b 1)
if not exist "%app.tools%" mkdir "%app.tools%" >nul 2>&1
call :Yellow GET: GetGit.bat.
call :Download "%app.getgit.url%" "%app.tools%\GetGit.bat" || exit /b 1
call :Yellow DO: Installing local Git.
call "%app.tools%\GetGit.bat" >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: GetGit.bat failed. & call :Yellow LOG: %app.log% & exit /b 1)
call :ResolveGit
if errorlevel 1 (call :Red FAIL: git.exe is still missing after GetGit.bat. & exit /b 1)
exit /b 0

:: ============================================================
:: Function: ResolveGit
:: Usage: call :ResolveGit
:: Purpose: locates git.exe.
:: Returns:
::   0 git found
::   1 git missing
:: ============================================================
:ResolveGit
if exist "%app.git%" (call :Green OK: Git: %app.git% & exit /b 0)
set "rg_git="
for %%P in (git.exe) do set "rg_git=%%~$PATH:P"
if defined rg_git set "app.git=%rg_git%"
if defined rg_git call :Green OK: Git: %app.git%
if defined rg_git set "rg_git="
if defined app.git exit /b 0
set "rg_git="
exit /b 1

:: ============================================================
:: Function: CloneOrUpdateRepo
:: Usage: call :CloneOrUpdateRepo
:: Purpose: clones the repo or updates an existing clone.
:: Returns:
::   0 repo ready
::   1 clone/update failed
:: ============================================================
:CloneOrUpdateRepo
if exist "%app.repo.dir%\.git" goto :CloneOrUpdateRepoExisting
if exist "%app.repo.dir%" (call :Red FAIL: destination exists but is not a git repo: %app.repo.dir% & exit /b 1)
call :Yellow DO: Cloning %app.repo.url%.
"%app.git%" clone --branch "%app.branch%" "%app.repo.url%" "%app.repo.dir%" >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: git clone failed. & call :Yellow LOG: %app.log% & exit /b 1)
call :Green OK: Cloned.
exit /b 0
:CloneOrUpdateRepoExisting
call :Yellow DO: Updating existing repo.
pushd "%app.repo.dir%" >nul
"%app.git%" fetch --all --prune >> "%app.log%" 2>&1
if errorlevel 1 (popd & call :Red FAIL: git fetch failed. & call :Yellow LOG: %app.log% & exit /b 1)
"%app.git%" checkout "%app.branch%" >> "%app.log%" 2>&1
if errorlevel 1 (popd & call :Red FAIL: git checkout failed. & call :Yellow LOG: %app.log% & exit /b 1)
"%app.git%" pull --ff-only >> "%app.log%" 2>&1
if errorlevel 1 (popd & call :Yellow WARN: git pull --ff-only failed; continuing with current checkout. & exit /b 0)
popd
call :Green OK: Repo updated.
exit /b 0

:: ============================================================
:: Function: EnsureGitHubCLI
:: Usage: call :EnsureGitHubCLI
:: Purpose: ensures gh.exe is available for GitHub login and fork support.
:: Returns:
::   0 gh available or not required
::   1 gh install failed
:: ============================================================
:EnsureGitHubCLI
call :ResolveGh
if not errorlevel 1 exit /b 0
if exist "%app.repo.dir%\tools\GetGitCLI.bat" goto :EnsureGitHubCLIFromRepo
if defined app.getgh.url (call :Yellow GET: GetGitCLI.bat. & call :Download "%app.getgh.url%" "%app.repo.dir%\tools\GetGitCLI.bat")
if errorlevel 1 (call :Yellow WARN: could not download GetGitCLI.bat; GitHub fork/login support unavailable. & exit /b 0)
:EnsureGitHubCLIFromRepo
if not exist "%app.repo.dir%\tools\GetGitCLI.bat" (call :Yellow WARN: GetGitCLI.bat missing; GitHub fork/login support unavailable. & exit /b 0)
call :Yellow DO: Installing GitHub CLI.
pushd "%app.repo.dir%" >nul
call "tools\GetGitCLI.bat" >> "%app.log%" 2>&1
popd
call :ResolveGh
if errorlevel 1 (call :Yellow WARN: gh.exe unavailable after GetGitCLI.bat; GitHub fork/login support unavailable. & exit /b 0)
exit /b 0

:: ============================================================
:: Function: ResolveGh
:: Usage: call :ResolveGh
:: Purpose: locates gh.exe.
:: Returns:
::   0 gh found
::   1 gh missing
:: ============================================================
:ResolveGh
set "app.gh="
if exist "%app.repo.dir%\tools\gh\bin\gh.exe" for %%A in ("%app.repo.dir%\tools\gh\bin\gh.exe") do set "app.gh=%%~fA"
if not defined app.gh if exist "%app.tools%\gh\bin\gh.exe" for %%A in ("%app.tools%\gh\bin\gh.exe") do set "app.gh=%%~fA"
if not defined app.gh for %%P in (gh.exe) do set "app.gh=%%~$PATH:P"
if defined app.gh (call :Green OK: GitHub CLI: %app.gh% & exit /b 0)
exit /b 1

:: ============================================================
:: Function: LoginGitHub
:: Usage: call :LoginGitHub
:: Purpose: logs in to GitHub when gh is available and not already authenticated.
:: Returns:
::   0 logged in or skipped
:: ============================================================
:LoginGitHub
if not defined app.gh (call :Yellow WARN: gh.exe missing; skipping GitHub login. & exit /b 0)
"%app.gh%" auth status >> "%app.log%" 2>&1
if not errorlevel 1 goto :LoginGitHubAlready
call :Yellow DO: GitHub login.
"%app.gh%" auth login --web --git-protocol https
if errorlevel 1 (call :Yellow WARN: GitHub login failed or was cancelled. & exit /b 0)
:LoginGitHubAlready
"%app.gh%" auth setup-git >> "%app.log%" 2>&1
call :Green OK: GitHub auth ready.
exit /b 0

:: ============================================================
:: Function: AutoLoginGitHub
:: Usage: call :AutoLoginGitHub
:: Purpose: performs auto-mode GitHub login, allowing the user to type nologin to skip.
:: Returns:
::   0 logged in or skipped
:: ============================================================
:AutoLoginGitHub
if not defined app.login (call :Yellow SKIP: GitHub login disabled. & exit /b 0)
if not defined app.gh (call :Yellow WARN: gh.exe missing; skipping GitHub login. & exit /b 0)
"%app.gh%" auth status >> "%app.log%" 2>&1
if not errorlevel 1 goto :AutoLoginGitHubAlready
call :Yellow LOGIN: Press Enter to log in with GitHub, or type nologin to skip.
set "algh_answer="
set /p "algh_answer=GitHub login [Enter/nologin]: "
if /I "%algh_answer%"=="nologin" (set "app.login=" & set "algh_answer=" & call :Yellow SKIP: GitHub login skipped. & exit /b 0)
set "algh_answer="
call :LoginGitHub
exit /b 0
:AutoLoginGitHubAlready
"%app.gh%" auth setup-git >> "%app.log%" 2>&1
call :Green OK: GitHub auth ready.
exit /b 0

:: ============================================================
:: Function: AutoForkIfNeeded
:: Usage: call :AutoForkIfNeeded
:: Purpose: creates/configures a fork automatically only when write access to the original GitHub repo is missing.
:: Returns:
::   0 complete or skipped
:: ============================================================
:AutoForkIfNeeded
if not defined app.gh exit /b 0
set "afn_old_fork=%app.fork.mode%"
set "app.fork.mode=yes"
call :MaybeOfferFork
set "app.fork.mode=%afn_old_fork%"
set "afn_old_fork="
exit /b 0

:: ============================================================
:: Function: MaybeOfferFork
:: Usage: call :MaybeOfferFork
:: Purpose: checks write permission and offers to create/configure a fork when needed.
:: Returns:
::   0 always
:: ============================================================
:MaybeOfferFork
if not defined app.gh exit /b 0
call :GetGitHubUser
if not defined app.github.user exit /b 0
call :GetGitHubPermission
if /I "%app.github.permission%"=="ADMIN" (call :Green OK: You can push to %app.repo.owner%/%app.repo.name%. & exit /b 0)
if /I "%app.github.permission%"=="MAINTAIN" (call :Green OK: You can push to %app.repo.owner%/%app.repo.name%. & exit /b 0)
if /I "%app.github.permission%"=="WRITE" (call :Green OK: You can push to %app.repo.owner%/%app.repo.name%. & exit /b 0)
call :Yellow MISS: No write permission to %app.repo.owner%/%app.repo.name%.
if /I "%app.fork.mode%"=="no" (call :Yellow SKIP: fork creation disabled. & exit /b 0)
if /I "%app.fork.mode%"=="yes" goto :MaybeOfferForkYes
set "mof_answer="
set /p "mof_answer=Create a fork under %app.github.user%? [Y/n]: "
if not defined mof_answer goto :MaybeOfferForkYes
if /I "%mof_answer%"=="y" goto :MaybeOfferForkYes
if /I "%mof_answer%"=="yes" goto :MaybeOfferForkYes
call :Yellow SKIP: fork not created.
set "mof_answer="
exit /b 0
:MaybeOfferForkYes
set "mof_answer="
call :CreateOrUseFork
exit /b 0

:: ============================================================
:: Function: GetGitHubUser
:: Usage: call :GetGitHubUser
:: Purpose: gets the logged-in GitHub username.
:: Returns:
::   0 always
:: ============================================================
:GetGitHubUser
set "app.github.user="
for /f "delims=" %%A in ('"%app.gh%" api user --jq ".login" 2^>nul') do set "app.github.user=%%A"
if not defined app.github.user call :Yellow WARN: could not determine GitHub username.
exit /b 0

:: ============================================================
:: Function: GetGitHubPermission
:: Usage: call :GetGitHubPermission
:: Purpose: gets viewerPermission for the original GitHub repo.
:: Returns:
::   0 always
:: ============================================================
:GetGitHubPermission
set "app.github.permission="
for /f "delims=" %%A in ('"%app.gh%" repo view "%app.repo.owner%/%app.repo.name%" --json viewerPermission --jq ".viewerPermission" 2^>nul') do set "app.github.permission=%%A"
if defined app.github.permission (call :Green OK: GitHub permission: %app.github.permission% & exit /b 0)
call :Yellow WARN: could not determine GitHub repo permission.
exit /b 0

:: ============================================================
:: Function: CreateOrUseFork
:: Usage: call :CreateOrUseFork
:: Purpose: creates a GitHub fork if needed and sets remotes to origin=fork, upstream=original.
:: Returns:
::   0 always
:: ============================================================
:CreateOrUseFork
set "cou_fork_url=https://github.com/%app.github.user%/%app.repo.name%.git"
call :Yellow DO: Creating or using fork %app.github.user%/%app.repo.name%.
"%app.gh%" repo fork "%app.repo.owner%/%app.repo.name%" --clone=false >> "%app.log%" 2>&1
"%app.gh%" repo view "%app.github.user%/%app.repo.name%" >> "%app.log%" 2>&1
if errorlevel 1 (call :Yellow WARN: fork was not confirmed; remotes were not changed. & set "cou_fork_url=" & exit /b 0)
pushd "%app.repo.dir%" >nul
"%app.git%" remote get-url upstream >nul 2>&1
if errorlevel 1 ("%app.git%" remote add upstream "%app.repo.url%" >> "%app.log%" 2>&1) else ("%app.git%" remote set-url upstream "%app.repo.url%" >> "%app.log%" 2>&1)
"%app.git%" remote get-url origin >nul 2>&1
if errorlevel 1 ("%app.git%" remote add origin "%cou_fork_url%" >> "%app.log%" 2>&1) else ("%app.git%" remote set-url origin "%cou_fork_url%" >> "%app.log%" 2>&1)
"%app.git%" fetch origin >> "%app.log%" 2>&1
popd
call :Green OK: Fork remote configured.
call :Green ORIGIN: %cou_fork_url%
call :Green UPSTREAM: %app.repo.url%
set "cou_fork_url="
exit /b 0

:: ============================================================
:: Function: MoveRepoToDocuments
:: Usage: call :MoveRepoToDocuments
:: Purpose: moves the project folder to the Windows Documents special folder.
:: Returns:
::   0 moved or already there
::   1 move failed
:: ============================================================
:MoveRepoToDocuments
set "mrtd_parent="
set "mrtd_dest="
for /f "delims=" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "[Environment]::GetFolderPath('MyDocuments')" 2^>^> "%app.log%"') do set "mrtd_parent=%%A"
if not defined mrtd_parent (call :Red FAIL: could not find Windows Documents folder. & exit /b 1)
set "mrtd_dest=%mrtd_parent%\%app.repo.folder%"
call :Yellow AUTO: moving project to Documents.
call :MoveRepoToDestination "%mrtd_dest%" || (set "mrtd_parent=" & set "mrtd_dest=" & exit /b 1)
set "mrtd_parent="
set "mrtd_dest="
exit /b 0

:: ============================================================
:: Function: MaybeMoveRepo
:: Usage: call :MaybeMoveRepo
:: Purpose: asks whether to move the project folder; y opens a PowerShell folder picker.
:: Returns:
::   0 moved, kept, or move canceled by user
::   1 move failed
:: ============================================================
:MaybeMoveRepo
if /I "%app.move.mode%"=="no" exit /b 0
call :Yellow MOVE: Type y to choose a destination folder, n to keep it here, or type a full destination path.
set "mmr_choice="
set "mmr_dest_abs="
set /p "mmr_choice=Move project folder? [n/y/path]: "
if not defined mmr_choice (call :Green OK: Keeping project at %app.repo.dir% & exit /b 0)
if /I "%mmr_choice%"=="n" (call :Green OK: Keeping project at %app.repo.dir% & set "mmr_choice=" & exit /b 0)
if /I "%mmr_choice%"=="no" (call :Green OK: Keeping project at %app.repo.dir% & set "mmr_choice=" & exit /b 0)
if /I "%mmr_choice%"=="y" goto :MaybeMoveRepoPicker
if /I "%mmr_choice%"=="yes" goto :MaybeMoveRepoPicker
for %%A in ("%mmr_choice%") do set "mmr_dest_abs=%%~fA"
call :MoveRepoToDestination "%mmr_dest_abs%" || (set "mmr_choice=" & set "mmr_dest_abs=" & exit /b 1)
set "mmr_choice="
set "mmr_dest_abs="
exit /b 0
:MaybeMoveRepoPicker
call :SelectMoveParentFolder
if errorlevel 1 (call :Yellow MOVE: folder picker canceled; keeping project at %app.repo.dir% & set "mmr_choice=" & set "mmr_dest_abs=" & exit /b 0)
set "mmr_dest_abs=%smp_folder%\%app.repo.folder%"
set "smp_folder="
call :MoveRepoToDestination "%mmr_dest_abs%" || (set "mmr_choice=" & set "mmr_dest_abs=" & exit /b 1)
set "mmr_choice="
set "mmr_dest_abs="
exit /b 0

:: ============================================================
:: Function: SelectMoveParentFolder
:: Usage: call :SelectMoveParentFolder
:: Purpose: opens a PowerShell folder picker for the destination parent folder.
:: Output:
::   smp_folder selected parent folder when successful
:: Returns:
::   0 folder selected
::   1 dialog canceled, closed, or failed
:: ============================================================
:SelectMoveParentFolder
set "smp_folder="
for /f "delims=" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $dialog=New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.Description='Select the folder that should receive the project folder'; $dialog.ShowNewFolderButton=$true; if($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){Write-Output $dialog.SelectedPath}else{exit 3}" 2^>^> "%app.log%"') do set "smp_folder=%%A"
if defined smp_folder exit /b 0
exit /b 1

:: ============================================================
:: Function: MoveRepoToDestination
:: Usage: call :MoveRepoToDestination "destinationFolder"
:: Purpose: moves app.repo.dir to a final destination folder.
:: Input:
::   %~1 final destination folder
:: Returns:
::   0 moved or destination is current folder
::   1 move failed
:: ============================================================
:MoveRepoToDestination
set "mrd_dest=%~1"
if not defined mrd_dest (call :Red FAIL: destination path is empty. & exit /b 1)
if /I "%mrd_dest%"=="%app.repo.dir%" (call :Green OK: Destination is current folder. & set "mrd_dest=" & exit /b 0)
if exist "%mrd_dest%" (call :Red FAIL: destination already exists: %mrd_dest% & set "mrd_dest=" & exit /b 1)
call :Yellow DO: Moving project to %mrd_dest%.
robocopy "%app.repo.dir%" "%mrd_dest%" /E /MOVE >> "%app.log%" 2>&1
if errorlevel 8 (call :Red FAIL: move failed. & call :Yellow LOG: %app.log% & set "mrd_dest=" & exit /b 1)
rmdir "%app.repo.dir%" >nul 2>&1
set "app.repo.dir=%mrd_dest%"
set "mrd_dest="
call :Green OK: Project moved.
exit /b 0

:: ============================================================
:Download
set "dwn_url=%~1"
set "dwn_file=%~2"
for %%A in ("%dwn_file%") do if not exist "%%~dpA" mkdir "%%~dpA" >nul 2>&1
curl.exe -L --fail --retry 3 -o "%dwn_file%" "%dwn_url%" >> "%app.log%" 2>&1
if not errorlevel 1 goto :DownloadCheck
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%dwn_url%' -OutFile '%dwn_file%'" >> "%app.log%" 2>&1
if errorlevel 1 (call :Red FAIL: download failed. & call :Yellow URL: %dwn_url% & call :Yellow LOG: %app.log% & set "dwn_url=" & set "dwn_file=" & exit /b 1)
:DownloadCheck
if not exist "%dwn_file%" (call :Red FAIL: download did not create file: %dwn_file% & set "dwn_url=" & set "dwn_file=" & exit /b 1)
set "dwn_url="
set "dwn_file="
exit /b 0

:: ============================================================
:: Function: SetESC
:: Usage: call :SetESC outputVariable
:: Purpose: captures the ANSI escape character into a variable.
:: Returns:
::   0 success
::   2 missing output variable
:: ============================================================
:SetESC
set "se_out=%~1"
if not defined se_out exit /b 2
for /f %%a in ('echo prompt $E^| cmd') do set "%se_out%=%%a"
set "se_out="
exit /b 0

:: ============================================================
:: Function: Green
:: Usage: call :Green message
:: Purpose: prints a green status line and writes it to the log.
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
:: Purpose: prints a yellow status line and writes it to the log.
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
:: Purpose: prints a red status line and writes it to the log.
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
:: Purpose: prints a cyan status line and writes it to the log.
:: Returns:
::   0 always
:: ============================================================
:Cyan
if defined app.esc (echo %app.esc%[%app.color.cyan%%*%app.esc%[%app.color.reset%) else (echo %*)
if defined app.log >>"%app.log%" echo %*
exit /b 0
