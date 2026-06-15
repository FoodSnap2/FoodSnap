@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if exist "git_show_history.bat" (
    call git_show_history.bat
) else (
    echo ERROR: git_show_history.bat was not found.
    echo.
    pause
    exit /b 1
)

endlocal
exit /b %ERRORLEVEL%