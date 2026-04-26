@echo off
echo ========================================
echo Digital Khata - Setup Script
echo ========================================
echo.

echo [1/4] Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo Error: Failed to install dependencies
    exit /b %errorlevel%
)
echo.

echo [2/4] Generating code (Drift, Riverpod, Freezed)...
call dart run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo Error: Failed to generate code
    exit /b %errorlevel%
)
echo.

echo [3/4] Generating localizations...
call flutter gen-l10n
if %errorlevel% neq 0 (
    echo Error: Failed to generate localizations
    exit /b %errorlevel%
)
echo.

echo [4/4] Running Flutter analyze...
call flutter analyze
echo.

echo ========================================
echo Setup completed successfully!
echo ========================================
echo.
echo To run the app:
echo   flutter run
echo.
echo To watch for code changes:
echo   dart run build_runner watch --delete-conflicting-outputs
echo.
