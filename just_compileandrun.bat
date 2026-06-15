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
echo  Build and run
echo ============================================================
echo.
echo Project:
echo   %APP_DISPLAY_NAME%
echo.
echo Folder:
echo   %CD%
echo.

if not exist "build.bat" (
    echo ERROR: build.bat was not found.
    echo.
    pause
    exit /b 1
)

call build.bat nosync
if errorlevel 1 (
    echo.
    echo Build failed. Not running.
    echo.
    pause
    exit /b 1
)

if exist "just_run.bat" (
    call just_run.bat
    endlocal
    exit /b %ERRORLEVEL%
)

echo.
echo ERROR: just_run.bat was not found.
echo.
pause
exit /b 1