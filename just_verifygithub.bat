@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if exist "github_verify_clone.bat" (
    call github_verify_clone.bat
) else (
    echo ERROR: github_verify_clone.bat was not found.
    echo.
    pause
    exit /b 1
)

endlocal
exit /b %ERRORLEVEL%