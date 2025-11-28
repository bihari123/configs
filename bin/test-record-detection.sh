#!/bin/bash

# Simulate selecting first display (DP-2)
PRIMARY_DISPLAY="DP-2"
RESOLUTION="1920x1080+1080+479"
GEOMETRY="1920x1080"
OFFSET="1080,479"

echo "Testing FPS detection for $PRIMARY_DISPLAY"
echo "="

# Detect display capabilities (copied from record-primary.sh)
DISPLAY_INFO=$(xrandr --query | grep "^${PRIMARY_DISPLAY} connected")
CURRENT_MODE=$(xrandr --query | grep "^${PRIMARY_DISPLAY}" -A 20 | grep '\*' | head -1)

echo "Current mode line: $CURRENT_MODE"

# Extract refresh rate
DISPLAY_REFRESH=$(echo "$CURRENT_MODE" | grep -oP '[0-9]+\.[0-9]+(?=\*)')
if [ -z "$DISPLAY_REFRESH" ]; then
    DISPLAY_REFRESH=$(echo "$CURRENT_MODE" | grep -oP '[0-9]+\.[0-9]+' | head -1)
fi

echo "Display refresh: $DISPLAY_REFRESH Hz"

# Round to integer
DISPLAY_FPS=$(printf "%.0f" "$DISPLAY_REFRESH")
echo "Display FPS (rounded): $DISPLAY_FPS"

# Cap at 60
if [ "$DISPLAY_FPS" -gt 60 ]; then
    echo "Capping at 60 fps"
    DISPLAY_FPS=60
fi

# Fallback
[ -z "$DISPLAY_FPS" ] || [ "$DISPLAY_FPS" -eq 0 ] && DISPLAY_FPS=30

echo "Final DISPLAY_FPS: $DISPLAY_FPS"

# Calculate bitrate
SCREEN_WIDTH=1920
SCREEN_HEIGHT=1080
TOTAL_PIXELS=$((SCREEN_WIDTH * SCREEN_HEIGHT))
QUALITY_FACTOR="0.10"
CALCULATED_BITRATE=$(awk "BEGIN {printf \"%.0f\", ($TOTAL_PIXELS / 1000) * $DISPLAY_FPS * $QUALITY_FACTOR}")
echo "Calculated bitrate: ${CALCULATED_BITRATE}k"

# No webcam test
WEBCAM_ENABLED=false
if [ "$WEBCAM_ENABLED" = true ]; then
    echo "Webcam enabled path"
else
    RECORDING_FPS=$DISPLAY_FPS
    echo "No webcam, RECORDING_FPS = $RECORDING_FPS"
fi

echo ""
echo "Final values that would be used in ffmpeg:"
echo "  -framerate $DISPLAY_FPS (for x11grab input)"
echo "  -r $RECORDING_FPS (for output)"
