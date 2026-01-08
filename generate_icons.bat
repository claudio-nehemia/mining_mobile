@echo off
echo ================================================
echo Nadya Loka Truck Tracking - Icon Generator
echo ================================================
echo.

echo [1/3] Getting Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies
    pause
    exit /b 1
)
echo.

echo [2/3] Generating launcher icons...
call flutter pub run flutter_launcher_icons
if errorlevel 1 (
    echo ERROR: Failed to generate icons
    pause
    exit /b 1
)
echo.

echo [3/3] Cleaning build cache...
call flutter clean
echo.

echo ================================================
echo SUCCESS! Icons have been generated.
echo ================================================
echo.
echo Next steps:
echo 1. Build and install app: flutter run
echo 2. Check if logo looks good on launcher
echo 3. If logo still looks cropped, add padding to logo image
echo.
pause
