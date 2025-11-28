#!/bin/bash
# Monitor configuration backup
# Created: 2025-11-28
# This script restores your dual monitor setup

xrandr --output DP-4 --mode 1920x1080 --rate 60 --rotate left --pos 0x0 \
       --output DP-2 --mode 1920x1080 --rate 60 --rotate normal --pos 1080x479 \
       --output HDMI-0 --off \
       --output DP-0 --off \
       --output DP-1 --off \
       --output HDMI-1 --off \
       --output DP-3 --off \
       --output DP-5 --off

echo "Monitor configuration restored:"
echo "  DP-4 (27\" Dell): 1920x1080 portrait mode at 0,0"
echo "  DP-2 (22\" Dell): 1920x1080 landscape mode at 1080,479"
