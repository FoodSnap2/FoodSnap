@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "CONFIG_FILE=build_config.bat"

set "APP_NAME=project"
set "APP_DISPLAY_NAME="
set "APP_RUN_COMMAND="
set "APP_RUN_FILE="
set "APP_OUTPUT_EXE="
set "APP_OUTPUT_APK="
set "APP_LAUNCH_ACTIVITY="
set "APP_ANDROID_SDK_DIR="
set "APP_ANDROID_SDK_FALLBACK_DIR="

if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"
)

if defined app.name set "APP_NAME=%app.name%"
if defined app.display_name set "APP_DISPLAY_NAME=%app.display_name%"
if not defined APP_DISPLAY_NAME set "APP_DISPLAY_NAME=%APP_NAME%"

if defined app.run_command set "APP_RUN_COMMAND=%app.run_command%"
if defined app.run_file set "APP_RUN_FILE=%app.run_file%"
if defined app.output_exe set "APP_OUTPUT_EXE=%app.output_exe%"
if defined app.output_apk set "APP_OUTPUT_APK=%app.output_apk%"
if defined app.launch_activity set "APP_LAUNCH_ACTIVITY=%app.launch_activity%"
if defined app.android_sdk_dir set "APP_ANDROID_SDK_DIR=%app.android_sdk_dir%"
if defined app.android_sdk_fallback_dir set "APP_ANDROID_SDK_FALLBACK_DIR=%app.android_sdk_fallback_dir%"

echo.
echo ============================================================
echo  Run project
echo ============================================================
echo.
echo Project:
echo   %APP_DISPLAY_NAME%
echo.
echo Folder:
echo   %CD%
echo.

if defined APP_RUN_COMMAND (
    echo Running app.run_command:
    echo   %APP_RUN_COMMAND%
    echo.
    call %APP_RUN_COMMAND%
    endlocal
    exit /b %ERRORLEVEL%
)

if defined APP_RUN_FILE (
    if exist "%APP_RUN_FILE%" (
        echo Running:
        echo   %APP_RUN_FILE%
        echo.
        start "" "%CD%\%APP_RUN_FILE%"
        endlocal
        exit /b 0
    )

    echo ERROR: app.run_file was set but file was not found:
    echo   %APP_RUN_FILE%
    echo.
    pause
    exit /b 1
)

if defined APP_OUTPUT_EXE (
    if exist "%APP_OUTPUT_EXE%" (
        echo Running:
        echo   %APP_OUTPUT_EXE%
        echo.
        start "" "%CD%\%APP_OUTPUT_EXE%"
        endlocal
        exit /b 0
    )

    echo ERROR: app.output_exe was set but file was not found:
    echo   %APP_OUTPUT_EXE%
    echo.
    pause
    exit /b 1
)

if defined APP_OUTPUT_APK (
    if not exist "%APP_OUTPUT_APK%" (
        echo ERROR: APK was not found:
        echo   %APP_OUTPUT_APK%
        echo.
        echo Run first:
        echo   just_build.bat
        echo.
        pause
        exit /b 1
    )

    set "ADB_EXE="

    if defined APP_ANDROID_SDK_DIR (
        if exist "%APP_ANDROID_SDK_DIR%\platform-tools\adb.exe" (
            set "ADB_EXE=%APP_ANDROID_SDK_DIR%\platform-tools\adb.exe"
        )
    )

    if not defined ADB_EXE if defined APP_ANDROID_SDK_FALLBACK_DIR (
        if exist "%APP_ANDROID_SDK_FALLBACK_DIR%\platform-tools\adb.exe" (
            set "ADB_EXE=%APP_ANDROID_SDK_FALLBACK_DIR%\platform-tools\adb.exe"
        )
    )

    if not defined ADB_EXE (
        where adb >nul 2>nul
        if not errorlevel 1 set "ADB_EXE=adb"
    )

    if not defined ADB_EXE (
        echo ERROR: adb was not found.
        echo.
        echo Install Android platform-tools or set one of these in build_config.bat:
        echo   app.android_sdk_dir
        echo   app.android_sdk_fallback_dir
        echo.
        pause
        exit /b 1
    )

    echo Installing APK:
    echo   %APP_OUTPUT_APK%
    echo.
    "%ADB_EXE%" install -r "%APP_OUTPUT_APK%"
    if errorlevel 1 (
        echo.
        echo ERROR: APK install failed.
        echo Make sure a device or emulator is connected.
        echo.
        pause
        exit /b 1
    )

    if defined APP_LAUNCH_ACTIVITY (
        echo.
        echo Launching activity:
        echo   %APP_LAUNCH_ACTIVITY%
        echo.
        "%ADB_EXE%" shell am start -n "%APP_LAUNCH_ACTIVITY%"
        if errorlevel 1 (
            echo.
            echo ERROR: App launch failed.
            echo.
            pause
            exit /b 1
        )
    ) else (
        echo.
        echo APK installed.
        echo No app.launch_activity is configured, so nothing was launched.
        echo.
    )

    pause
    exit /b 0
)

echo ERROR: No run target is configured.
echo.
echo Add one of these to build_config.bat:
echo.
echo   set "app.run_command=your command here"
echo.
echo or:
echo.
echo   set "app.run_file=relative\path\to\program.exe"
echo.
echo or:
echo.
echo   set "app.output_exe=relative\path\to\program.exe"
echo.
echo or for Android:
echo.
echo   set "app.output_apk=build\YourApp-debug.apk"
echo   set "app.launch_activity=your.package/.MainActivity"
echo.
pause
exit /b 1