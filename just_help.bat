@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "APP_NAME=project"
set "APP_DISPLAY_NAME="

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "APP_NAME=%app.name%"
if defined app.display_name set "APP_DISPLAY_NAME=%app.display_name%"
if not defined APP_DISPLAY_NAME set "APP_DISPLAY_NAME=%APP_NAME%"

echo.
echo ============================================================
echo  %APP_DISPLAY_NAME% just_* helper commands
echo ============================================================
echo.
echo Folder:
echo   %CD%
echo.
echo These are short convenience wrappers around build.bat and git_*.bat.
echo.

echo ============================================================
echo  Quick summary
echo ============================================================
echo.
echo just_help.bat             - Show this help.
echo just_build.bat            - Build only. No commit. No push.
echo just_check.bat            - Check build setup only. Does not compile.
echo just_compileandrun.bat    - Build only, then run using just_run.bat.
echo just_run.bat              - Run using build_config.bat run settings.
echo just_status.bat           - Show Git/project status and recommended next action.
echo just_diff.bat             - Show changed files and a diff summary.
echo just_commit.bat           - Commit current local changes only. No push.
echo just_push.bat             - Push already-created local commits to GitHub.
echo just_getlatest.bat        - Safely get latest commits from GitHub.
echo just_history.bat          - Show recent Git commit history.
echo just_backup.bat           - Create an offline Git backup bundle.
echo just_verifygithub.bat     - Test that GitHub can be cloned successfully.
echo.

echo ============================================================
echo  Main everyday choices
echo ============================================================
echo.
echo First GitHub setup:
echo   git_login.bat
echo.
echo Normal code save:
echo   build.bat
echo.
echo Build only:
echo   just_build.bat
echo.
echo Build and run:
echo   just_compileandrun.bat
echo.
echo Unsure:
echo   just_status.bat
echo.
echo Docs/scripts/config only:
echo   just_commit.bat
echo   just_push.bat
echo.
echo Starting work on another computer:
echo   just_getlatest.bat
echo.
echo Backup before risky work:
echo   just_backup.bat
echo.
pause

echo.
echo ============================================================
echo  More usage help
echo ============================================================
echo.

echo ------------------------------------------------------------
echo just_build.bat
echo ------------------------------------------------------------
echo Runs:
echo   build.bat nosync
echo.
echo Use when:
echo   You want to compile-test the project.
echo   You do not want a Git commit.
echo   You do not want a GitHub push.
echo.

echo ------------------------------------------------------------
echo just_check.bat
echo ------------------------------------------------------------
echo Runs:
echo   build.bat check
echo.
echo Use when:
echo   You want to check setup without compiling.
echo.

echo ------------------------------------------------------------
echo just_compileandrun.bat
echo ------------------------------------------------------------
echo Runs:
echo   build.bat nosync
echo   just_run.bat
echo.
echo Use when:
echo   You want to build first, then run.
echo.

echo ------------------------------------------------------------
echo just_run.bat
echo ------------------------------------------------------------
echo Uses build_config.bat when available.
echo.
echo Supported run settings:
echo   app.run_command
echo   app.run_file
echo   app.output_exe
echo   app.output_apk plus app.launch_activity
echo.
echo For Android APK projects, it tries adb install and adb shell am start.
echo.

echo ------------------------------------------------------------
echo just_status.bat
echo ------------------------------------------------------------
echo Runs:
echo   git_status_check.bat
echo.
echo Use when:
echo   You are unsure what to do.
echo   You want to know whether files changed.
echo   You want to know whether GitHub is ahead or behind.
echo.

echo ------------------------------------------------------------
echo just_commit.bat
echo ------------------------------------------------------------
echo Commits current local changes only.
echo.
echo It does:
echo   git add --all
echo   git commit
echo.
echo It does not:
echo   build
echo   push
echo.
echo Afterward, push with:
echo   just_push.bat
echo.

echo ------------------------------------------------------------
echo just_push.bat
echo ------------------------------------------------------------
echo Runs:
echo   git_push_local.bat
echo.
echo Use when:
echo   You already have local commits.
echo   You want to send them to GitHub.
echo.

echo ------------------------------------------------------------
echo just_getlatest.bat
echo ------------------------------------------------------------
echo Runs:
echo   git_get_latest.bat
echo.
echo Use when:
echo   You are starting work.
echo   GitHub has newer commits.
echo   just_status.bat says you are behind GitHub.
echo.

echo ------------------------------------------------------------
echo just_backup.bat
echo ------------------------------------------------------------
echo Runs:
echo   git_backup_bundle.bat
echo.
echo Creates an offline Git bundle backup.
echo Does not need internet.
echo.

echo ------------------------------------------------------------
echo just_verifygithub.bat
echo ------------------------------------------------------------
echo Runs:
echo   github_verify_clone.bat
echo.
echo Makes a temporary fresh clone from GitHub.
echo Confirms GitHub has a usable copy.
echo.

echo ------------------------------------------------------------
echo Suggested workflows
echo ------------------------------------------------------------
echo Normal code save:
echo   build.bat
echo.
echo Quick compile test:
echo   just_build.bat
echo.
echo Quick compile and run:
echo   just_compileandrun.bat
echo.
echo Docs/scripts/config only:
echo   just_commit.bat
echo   just_push.bat
echo.
echo Starting work:
echo   just_getlatest.bat
echo.
echo Unsure:
echo   just_status.bat
echo.

echo ============================================================
echo.
pause
exit /b 0