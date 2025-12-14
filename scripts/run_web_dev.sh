#!/bin/bash
# Run Flutter web with Chrome with disabled web security (development only!)
# This bypasses CORS restrictions for local development

echo "⚠️  WARNING: Running with web security disabled - for development only!"
echo ""

# Find Chrome executable
if command -v google-chrome &> /dev/null; then
    CHROME_PATH="google-chrome"
elif command -v google-chrome-stable &> /dev/null; then
    CHROME_PATH="google-chrome-stable"  
elif command -v chromium &> /dev/null; then
    CHROME_PATH="chromium"
elif command -v chromium-browser &> /dev/null; then
    CHROME_PATH="chromium-browser"
elif [ -f "/usr/bin/flatpak" ]; then
    # Flatpak Chrome
    echo "Using Flatpak Chrome..."
    CHROME_PATH="flatpak run com.google.Chrome"
else
    echo "Chrome not found. Please install Chrome/Chromium."
    exit 1
fi

# Create temp directory for Chrome user data
CHROME_DATA_DIR=$(mktemp -d)
trap "rm -rf $CHROME_DATA_DIR" EXIT

echo "Starting Flutter web server..."
flutter run -d web-server --web-port=8080 &
FLUTTER_PID=$!

sleep 5

echo "Opening Chrome with disabled web security..."
$CHROME_PATH \
    --disable-web-security \
    --user-data-dir="$CHROME_DATA_DIR" \
    --disable-features=VizDisplayCompositor \
    http://localhost:8080

wait $FLUTTER_PID
