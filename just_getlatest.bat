@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if exist "git_get_latest.bat" (
    call git_get_latest.bat
) else (
    echo ERROR: git_get_latest.bat was not found.
    echo.
    pause
    exit /b 1
)

endlocal
exit /b %ERRORLEVEL%