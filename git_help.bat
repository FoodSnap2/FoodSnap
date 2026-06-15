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
echo  %APP_DISPLAY_NAME% Git helper scripts
echo ============================================================
echo.
echo Project folder:
echo   %CD%
echo.
echo These scripts are generic.
echo They read project settings from:
echo   build_config.bat
echo.
echo Important config values:
echo   app.name
echo   app.display_name
echo   app.repo_url
echo   app.git_branch
echo   app.git_name        optional
echo   app.git_email       optional
echo   app.git_backup_dir  optional
echo.
echo ============================================================
echo  Normal daily workflow
echo ============================================================
echo.
echo 1. Before starting work, especially on another computer:
echo      git_get_latest.bat
echo.
echo 2. Edit files.
echo.
echo 3. For normal code work:
echo      build.bat
echo.
echo 4. For README, script, docs, or non-build changes:
echo      git_commit_and_push_now.bat
echo.
echo 5. Whenever unsure:
echo      git_status_check.bat
echo.

echo ============================================================
echo  Script reference
echo ============================================================

echo.
echo ------------------------------------------------------------
echo  git_login.bat
echo ------------------------------------------------------------
echo What it does:
echo   Initializes Git if needed.
echo   Sets the GitHub origin remote.
echo   Sets local Git name/email.
echo   Configures Git Credential Manager if available.
echo   Pushes the current branch with upstream tracking if commits exist.
echo.
echo Reads from:
echo   build_config.bat
echo   existing .git config
echo   global Git config
echo.
echo Use when:
echo   Setting up a project for GitHub the first time.
echo   Changing the GitHub repository URL.
echo   Fixing missing upstream tracking.
echo.

echo ------------------------------------------------------------
echo  git_status_check.bat
echo ------------------------------------------------------------
echo What it does:
echo   Shows current branch.
echo   Shows GitHub remote.
echo   Shows local file changes.
echo   Checks whether local Git and GitHub are synced.
echo   Gives a recommendation.
echo.
echo Use when:
echo   You are unsure what to do next.
echo   Before pulling.
echo   Before pushing.
echo   Before switching computers.
echo.

echo ------------------------------------------------------------
echo  git_get_latest.bat
echo ------------------------------------------------------------
echo What it does:
echo   Safely gets latest commits from GitHub.
echo   Only works when there are no uncommitted local changes.
echo   Uses fast-forward only, so it does not auto-merge divergent work.
echo.
echo Use when:
echo   Starting work.
echo   Moving between computers.
echo   GitHub has newer commits.
echo.

echo ------------------------------------------------------------
echo  git_push_local.bat
echo ------------------------------------------------------------
echo What it does:
echo   Pushes existing local commits to GitHub.
echo   Does not create a new commit.
echo.
echo Use when:
echo   git_status_check.bat says you are ahead of GitHub.
echo.

echo ------------------------------------------------------------
echo  git_commit_and_push_now.bat
echo ------------------------------------------------------------
echo What it does:
echo   Adds all current file changes.
echo   Creates a commit.
echo   Pushes the commit to GitHub.
echo.
echo Use when:
echo   Changing README files.
echo   Changing helper scripts.
echo   Making docs or non-build changes.
echo.
echo For normal code changes:
echo   Prefer build.bat if your build system commits only after success.
echo.

echo ------------------------------------------------------------
echo  git_show_history.bat
echo ------------------------------------------------------------
echo What it does:
echo   Shows recent commits in a readable graph.
echo.
echo Use when:
echo   You want to confirm what was committed.
echo   You want to see recent project history.
echo.

echo ------------------------------------------------------------
echo  git_backup_bundle.bat
echo ------------------------------------------------------------
echo What it does:
echo   Creates an offline Git backup bundle.
echo   Saves it to a project-specific backup folder.
echo   Does not require internet or GitHub.
echo.
echo Use when:
echo   Before risky changes.
echo   Before moving/copying the project.
echo   Before cleaning or discarding files.
echo.

echo ------------------------------------------------------------
echo  github_verify_clone.bat
echo ------------------------------------------------------------
echo What it does:
echo   Makes a temporary fresh clone from GitHub.
echo   Confirms GitHub has a usable copy of the project.
echo   Deletes the test clone afterward.
echo.
echo Use when:
echo   After an important first push.
echo   Before trusting that GitHub has everything.
echo   Before moving to another computer.
echo.

echo ------------------------------------------------------------
echo  git_discard_local_changes_DANGEROUS.bat
echo ------------------------------------------------------------
echo What it does:
echo   Restores tracked files back to the last commit.
echo   Deletes untracked non-ignored files.
echo   Keeps ignored files/folders.
echo.
echo Use when:
echo   You are absolutely sure you want to abandon local edits.
echo.

echo ============================================================
echo  Usual choices
echo ============================================================
echo.
echo First setup:
echo   git_login.bat
echo.
echo Unsure:
echo   git_status_check.bat
echo.
echo Get newest GitHub version:
echo   git_get_latest.bat
echo.
echo Push existing commits:
echo   git_push_local.bat
echo.
echo Commit and push current changes:
echo   git_commit_and_push_now.bat
echo.
echo View history:
echo   git_show_history.bat
echo.
echo Backup:
echo   git_backup_bundle.bat
echo.
echo Verify GitHub:
echo   github_verify_clone.bat
echo.
echo Throw away local changes:
echo   git_discard_local_changes_DANGEROUS.bat
echo.

pause
exit /b 0