#!/bin/bash

# Get primary display info
PRIMARY_DISPLAY=$(xrandr --query | grep " connected primary" | cut -d" " -f1)
RESOLUTION=$(xrandr --query | grep " connected primary" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*' | head -1)

if [ -z "$PRIMARY_DISPLAY" ] || [ -z "$RESOLUTION" ]; then
    echo "Error: Could not detect primary display"
    exit 1
fi

# Extract geometry
GEOMETRY=$(echo $RESOLUTION | cut -d'+' -f1)
OFFSET=$(echo $RESOLUTION | cut -d'+' -f2-3 | tr '+' ',')

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="recording_${TIMESTAMP}.mp4"

echo "Recording primary display: $PRIMARY_DISPLAY"
echo "Resolution: $GEOMETRY"
echo "Offset: $OFFSET"
echo "Output file: $OUTPUT_FILE"
echo "Press Ctrl+C to stop recording"

# Record using ffmpeg with Android-compatible parameters
ffmpeg -f x11grab -s $GEOMETRY -i :0.0+$OFFSET -f pulse -i default \
  -vcodec libx264 -profile:v baseline -level 4.0 -pix_fmt yuv420p \
  -r 30 -b:v 1500k -maxrate 1500k -bufsize 3000k \
  -af "afftdn=nf=-25,highpass=f=200" \
  -acodec aac -ar 48000 -ac 2 -b:a 128k \
  -movflags +faststart \
  "$OUTPUT_FILE"

echo "Recording saved as: $OUTPUT_FILE"