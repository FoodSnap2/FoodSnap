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
echo  Git helper quick help
echo ============================================================
echo.
echo Project:
echo   %APP_DISPLAY_NAME%
echo.
echo Folder:
echo   %CD%
echo.
echo Main idea:
echo   For normal code work, run build.bat.
echo   For uncertainty, run git_status_check.bat.
echo   For docs or script-only changes, run git_commit_and_push_now.bat.
echo.
echo ============================================================
echo  3-line descriptions
echo ============================================================

echo.
echo build.bat
echo   Builds the project.
echo   May create build/source snapshots depending on your build system.
echo   Use after normal code edits.

echo.
echo git_login.bat
echo   Sets up GitHub origin, local Git name/email, and first push.
echo   Reads repo settings from build_config.bat when available.
echo   Use once per project or when changing GitHub remotes.

echo.
echo git_status_check.bat
echo   Shows local changes, branch, remote, and GitHub sync state.
echo   Tells you whether you are clean, ahead, behind, or both.
echo   Use whenever you are unsure what to do next.

echo.
echo git_get_latest.bat
echo   Gets the latest commits from GitHub safely.
echo   Only works when your local folder has no uncommitted changes.
echo   Use before working on another computer.

echo.
echo git_push_local.bat
echo   Pushes already-created local commits to GitHub.
echo   Does not commit new file changes.
echo   Use when status says you are ahead of GitHub.

echo.
echo git_commit_and_push_now.bat
echo   Commits current file changes with a message.
echo   Pushes that commit to GitHub.
echo   Use for README, docs, helper scripts, or non-build changes.

echo.
echo git_show_history.bat
echo   Shows recent commits in a readable graph.
echo   Helps confirm that your saves and builds were committed.
echo   Use when you want to see project history.

echo.
echo git_backup_bundle.bat
echo   Creates an offline Git backup bundle.
echo   Does not need internet or GitHub.
echo   Use before risky changes or moving computers.

echo.
echo github_verify_clone.bat
echo   Makes a temporary fresh clone from GitHub.
echo   Confirms GitHub has a usable copy of the project.
echo   Use after important pushes.

echo.
echo git_discard_local_changes_DANGEROUS.bat
echo   Throws away uncommitted local changes.
echo   Restores files back to the last commit.
echo   Use only when you are sure you want to abandon edits.

echo.
echo ============================================================
echo  1-line quick summary
echo ============================================================

echo.
echo build.bat - Build the project.
echo git_login.bat - Set up GitHub login/origin/upstream.
echo git_status_check.bat - Check what state Git is in and what to do next.
echo git_get_latest.bat - Safely update from GitHub before starting work.
echo git_push_local.bat - Push local commits that already exist.
echo git_commit_and_push_now.bat - Manually commit and push non-build changes.
echo git_show_history.bat - Show recent commit history.
echo git_backup_bundle.bat - Create an offline backup of the Git repo.
echo github_verify_clone.bat - Test that GitHub can be cloned successfully.
echo git_discard_local_changes_DANGEROUS.bat - Throw away uncommitted local edits.
echo.

echo ============================================================
echo  Usual choices
echo ============================================================

echo.
echo First GitHub setup:
echo   git_login.bat
echo.
echo Normal code work:
echo   build.bat
echo.
echo Unsure what to do:
echo   git_status_check.bat
echo.
echo Script or README edit:
echo   git_commit_and_push_now.bat
echo.
echo Before risky work:
echo   git_backup_bundle.bat
echo.
echo Get latest before working:
echo   git_get_latest.bat
echo.

pause
exit /b 0