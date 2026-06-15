@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if exist "git_push_local.bat" (
    call git_push_local.bat
) else (
    echo ERROR: git_push_local.bat was not found.
    echo.
    pause
    exit /b 1
)

endlocal
exit /b %ERRORLEVEL%