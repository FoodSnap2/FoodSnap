@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist "build.bat" (
    echo ERROR: build.bat was not found.
    echo Folder:
    echo   %CD%
    echo.
    pause
    exit /b 1
)

call build.bat check

endlocal
exit /b %ERRORLEVEL%