#!/bin/bash

PRIMARY_DISPLAY="DP-2"
CURRENT_MODE=$(xrandr --query | grep "^${PRIMARY_DISPLAY}" -A 20 | grep '\*' | head -1)
echo "Current mode: $CURRENT_MODE"

DISPLAY_REFRESH=$(echo "$CURRENT_MODE" | grep -oP '[0-9]+\.[0-9]+(?=\*)')
echo "Display refresh: '$DISPLAY_REFRESH'"

if [ -z "$DISPLAY_REFRESH" ]; then
    DISPLAY_REFRESH=$(echo "$CURRENT_MODE" | grep -oP '[0-9]+\.[0-9]+' | head -1)
    echo "Fallback refresh: '$DISPLAY_REFRESH'"
fi

DISPLAY_FPS=$(printf "%.0f" "$DISPLAY_REFRESH")
echo "Display FPS after printf: '$DISPLAY_FPS'"

if [ "$DISPLAY_FPS" -gt 60 ] 2>/dev/null; then
    echo "FPS > 60, capping at 60"
    DISPLAY_FPS=60
fi

echo "Before fallback check: DISPLAY_FPS='$DISPLAY_FPS'"
[ -z "$DISPLAY_FPS" ] || [ "$DISPLAY_FPS" -eq 0 ] && DISPLAY_FPS=30

echo "Final Display FPS: $DISPLAY_FPS"
