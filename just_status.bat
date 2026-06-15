@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if exist "git_status_check.bat" (
    call git_status_check.bat
) else (
    echo ERROR: git_status_check.bat was not found.
    echo.
    pause
    exit /b 1
)

endlocal
exit /b %ERRORLEVEL%