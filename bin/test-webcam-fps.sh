#!/bin/bash

# Simulate display detection
PRIMARY_DISPLAY="DP-2"
GEOMETRY="1920x1080"

echo "Testing FPS with WEBCAM ENABLED"
echo "================================"

# Display detection
CURRENT_MODE=$(xrandr --query | grep "^${PRIMARY_DISPLAY}" -A 20 | grep '\*' | head -1)
DISPLAY_REFRESH=$(echo "$CURRENT_MODE" | grep -oP '[0-9]+\.[0-9]+(?=\*)')
DISPLAY_FPS=$(printf "%.0f" "$DISPLAY_REFRESH")
[ "$DISPLAY_FPS" -gt 60 ] && DISPLAY_FPS=60
[ -z "$DISPLAY_FPS" ] || [ "$DISPLAY_FPS" -eq 0 ] && DISPLAY_FPS=30

echo "Display FPS: $DISPLAY_FPS"

# Simulate webcam detection
WEBCAM_ENABLED=true
WEBCAM_DEVICE="/dev/video0"

if [ "$WEBCAM_ENABLED" = true ] && [ -e "$WEBCAM_DEVICE" ]; then
    echo ""
    echo "Detecting webcam capabilities..."

    if command -v v4l2-ctl &> /dev/null; then
        # Get actual webcam FPS
        AVAILABLE_FPS=$(v4l2-ctl -d "$WEBCAM_DEVICE" --list-formats-ext 2>/dev/null | \
            grep -oP '\(\K[0-9.]+(?= fps)' | sort -rn | head -5)

        echo "Available webcam framerates:"
        echo "$AVAILABLE_FPS" | head -5

        # Select best framerate (prefer 30fps)
        if echo "$AVAILABLE_FPS" | grep -q "^30"; then
            WEBCAM_FPS="30"
        elif echo "$AVAILABLE_FPS" | grep -q "^60"; then
            WEBCAM_FPS="60"
        else
            WEBCAM_FPS=$(echo "$AVAILABLE_FPS" | head -1)
        fi

        echo ""
        echo "Selected webcam FPS: $WEBCAM_FPS"

        # FPS handling (no downgrade)
        echo ""
        if [ "$WEBCAM_FPS" != "$DISPLAY_FPS" ]; then
            echo "Note: Display at ${DISPLAY_FPS} fps, webcam at ${WEBCAM_FPS} fps"
            echo "      Output will be ${DISPLAY_FPS} fps (webcam frames duplicated to match)"
        fi

        # Always use display fps
        RECORDING_FPS=$DISPLAY_FPS
    else
        echo "v4l2-ctl not found, using defaults"
        WEBCAM_FPS="30"
        RECORDING_FPS=$WEBCAM_FPS
    fi
else
    echo "Webcam not found at $WEBCAM_DEVICE"
    RECORDING_FPS=$DISPLAY_FPS
fi

echo ""
echo "================================"
echo "FINAL RECORDING FPS: $RECORDING_FPS"
echo "================================"
echo ""
echo "FFmpeg will use:"
echo "  Display capture: -framerate $DISPLAY_FPS"
echo "  Webcam capture: -framerate $WEBCAM_FPS"
echo "  Output: -r $RECORDING_FPS"
