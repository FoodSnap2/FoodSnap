@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if exist "git_backup_bundle.bat" (
    call git_backup_bundle.bat
) else (
    echo ERROR: git_backup_bundle.bat was not found.
    echo.
    pause
    exit /b 1
)

endlocal
exit /b %ERRORLEVEL%