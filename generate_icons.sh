#!/bin/bash

echo "================================================"
echo "Nadya Loka Truck Tracking - Icon Generator"
echo "================================================"
echo ""

echo "[1/3] Getting Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get dependencies"
    exit 1
fi
echo ""

echo "[2/3] Generating launcher icons..."
flutter pub run flutter_launcher_icons
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to generate icons"
    exit 1
fi
echo ""

echo "[3/3] Cleaning build cache..."
flutter clean
echo ""

echo "================================================"
echo "SUCCESS! Icons have been generated."
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Build and install app: flutter run"
echo "2. Check if logo looks good on launcher"
echo "3. If logo still looks cropped, add padding to logo image"
echo ""
