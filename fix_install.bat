@echo off
echo Fixing ADB and reinstalling app...

REM Use Flutter's bundled ADB
set FLUTTER_ROOT=%LOCALAPPDATA%\Android\Sdk\platform-tools

if exist "%FLUTTER_ROOT%\adb.exe" (
    echo Found ADB at %FLUTTER_ROOT%
    "%FLUTTER_ROOT%\adb.exe" devices
    "%FLUTTER_ROOT%\adb.exe" uninstall com.example.hamro_pasal
    echo.
    echo Now run: flutter run
) else (
    echo ADB not found. Trying alternative path...
    set FLUTTER_ROOT=%USERPROFILE%\AppData\Local\Android\Sdk\platform-tools
    if exist "%FLUTTER_ROOT%\adb.exe" (
        "%FLUTTER_ROOT%\adb.exe" devices
        "%FLUTTER_ROOT%\adb.exe" uninstall com.example.hamro_pasal
        echo.
        echo Now run: flutter run
    ) else (
        echo Could not find ADB. Please enable "Install via USB" on your phone.
    )
)

pause
