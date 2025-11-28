#!/bin/bash

# Parse command line arguments
WEBCAM_ENABLED=false
WEBCAM_DEVICE="/dev/video0"

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--webcam)
            WEBCAM_ENABLED=true
            shift
            ;;
        --webcam-device)
            WEBCAM_DEVICE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [-w|--webcam] [--webcam-device DEVICE]"
            echo "  -w, --webcam          Enable webcam overlay in bottom right"
            echo "  --webcam-device       Specify webcam device (default: /dev/video0)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Get all connected displays with full info
mapfile -t DISPLAY_LINES < <(xrandr --query | grep " connected")

if [ ${#DISPLAY_LINES[@]} -eq 0 ]; then
    echo "Error: No connected displays found"
    exit 1
fi

# Parse display information
DISPLAYS=()
RESOLUTIONS=()
ROTATIONS=()
SIZES=()

for line in "${DISPLAY_LINES[@]}"; do
    # Extract display name
    DISPLAY_NAME=$(echo "$line" | cut -d" " -f1)
    DISPLAYS+=("$DISPLAY_NAME")

    # Extract resolution
    RESOLUTION=$(echo "$line" | grep -o '[0-9]*x[0-9]*+[0-9]*+[0-9]*' | head -1)
    RESOLUTIONS+=("$RESOLUTION")

    # Extract rotation (appears between "connected" and resolution)
    # Format: "DP-2 connected [primary] [rotation] 1920x1080..."
    ROTATION=$(echo "$line" | sed 's/.*connected \(primary \)\?//' | grep -o '^\(left\|right\|inverted\)' || echo "normal")
    ROTATIONS+=("$ROTATION")

    # Extract physical size and convert to inches
    PHYSICAL_SIZE=$(echo "$line" | grep -o '[0-9]*mm x [0-9]*mm')
    if [ -z "$PHYSICAL_SIZE" ]; then
        SIZE_DISPLAY="unknown"
    else
        WIDTH_MM=$(echo "$PHYSICAL_SIZE" | cut -d' ' -f1 | tr -d 'mm')
        HEIGHT_MM=$(echo "$PHYSICAL_SIZE" | cut -d' ' -f3 | tr -d 'mm')
        # Calculate diagonal in inches: sqrt(w^2 + h^2) / 25.4
        DIAGONAL_INCHES=$(awk "BEGIN {printf \"%.1f\", sqrt($WIDTH_MM*$WIDTH_MM + $HEIGHT_MM*$HEIGHT_MM) / 25.4}")
        SIZE_DISPLAY="${DIAGONAL_INCHES}\""
    fi
    SIZES+=("$SIZE_DISPLAY")
done

# If only one display, use it automatically
if [ ${#DISPLAYS[@]} -eq 1 ]; then
    SELECTED_INDEX=0
    echo "Only one display found: ${DISPLAYS[0]}"
    echo "  Resolution: ${RESOLUTIONS[0]}"
    echo "  Rotation: ${ROTATIONS[0]}"
    echo "  Physical size: ${SIZES[0]}"
else
    # Show menu of available displays
    echo "Available displays:"
    for i in "${!DISPLAYS[@]}"; do
        DISPLAY_NAME="${DISPLAYS[$i]}"
        DISPLAY_RES=$(echo "${RESOLUTIONS[$i]}" | cut -d'+' -f1)
        DISPLAY_ROT="${ROTATIONS[$i]}"
        DISPLAY_SIZE="${SIZES[$i]}"
        echo "  $((i+1)). $DISPLAY_NAME - ${DISPLAY_RES} - ${DISPLAY_ROT} - ${DISPLAY_SIZE}"
    done
    echo ""

    # Ask user to choose
    while true; do
        read -p "Choose display to record (1-${#DISPLAYS[@]}): " CHOICE
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le ${#DISPLAYS[@]} ]; then
            SELECTED_INDEX=$((CHOICE-1))
            break
        else
            echo "Invalid choice. Please enter a number between 1 and ${#DISPLAYS[@]}"
        fi
    done
fi

# Get selected display info
PRIMARY_DISPLAY="${DISPLAYS[$SELECTED_INDEX]}"
RESOLUTION="${RESOLUTIONS[$SELECTED_INDEX]}"

if [ -z "$RESOLUTION" ]; then
    echo "Error: Could not get resolution for $PRIMARY_DISPLAY"
    exit 1
fi

# Extract geometry
GEOMETRY=$(echo $RESOLUTION | cut -d'+' -f1)
OFFSET=$(echo $RESOLUTION | cut -d'+' -f2-3 | tr '+' ',')

# Validate webcam if enabled
if [ "$WEBCAM_ENABLED" = true ]; then
    if [ ! -e "$WEBCAM_DEVICE" ]; then
        echo "Error: Webcam device $WEBCAM_DEVICE not found"
        echo "Available video devices:"
        ls -1 /dev/video* 2>/dev/null || echo "  No video devices found"
        exit 1
    fi
    echo "Webcam enabled: $WEBCAM_DEVICE"
fi

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="recording_${TIMESTAMP}.mp4"

echo "Recording primary display: $PRIMARY_DISPLAY"
echo "Resolution: $GEOMETRY"
echo "Offset: $OFFSET"
echo "Output file: $OUTPUT_FILE"
echo "Press Ctrl+C to stop recording"

# Record using ffmpeg with Android-compatible parameters
if [ "$WEBCAM_ENABLED" = true ]; then
    # With webcam overlay - square box in bottom right
    # Calculate square size (15% of smaller dimension)
    SCREEN_WIDTH=$(echo $GEOMETRY | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo $GEOMETRY | cut -d'x' -f2)
    SMALLER_DIM=$((SCREEN_WIDTH < SCREEN_HEIGHT ? SCREEN_WIDTH : SCREEN_HEIGHT))
    WEBCAM_SIZE=$((SMALLER_DIM * 15 / 100))
    PADDING=20

    ffmpeg -f x11grab -s $GEOMETRY -i :0.0+$OFFSET \
      -f v4l2 -input_format mjpeg -video_size 640x480 -i "$WEBCAM_DEVICE" \
      -f pulse -i default \
      -filter_complex "[1:v]scale=${WEBCAM_SIZE}:${WEBCAM_SIZE}:force_original_aspect_ratio=increase,crop=${WEBCAM_SIZE}:${WEBCAM_SIZE}[webcam]; \
                       [0:v][webcam]overlay=W-w-${PADDING}:H-h-${PADDING}[outv]" \
      -map "[outv]" -map 2:a \
      -vcodec libx264 -profile:v baseline -level 4.0 -pix_fmt yuv420p \
      -r 30 -b:v 2000k -maxrate 2000k -bufsize 4000k \
      -af "afftdn=nf=-25,highpass=f=200" \
      -acodec aac -ar 48000 -ac 2 -b:a 128k \
      -movflags +faststart \
      "$OUTPUT_FILE"
else
    # Without webcam
    ffmpeg -f x11grab -s $GEOMETRY -i :0.0+$OFFSET -f pulse -i default \
      -vcodec libx264 -profile:v baseline -level 4.0 -pix_fmt yuv420p \
      -r 30 -b:v 1500k -maxrate 1500k -bufsize 3000k \
      -af "afftdn=nf=-25,highpass=f=200" \
      -acodec aac -ar 48000 -ac 2 -b:a 128k \
      -movflags +faststart \
      "$OUTPUT_FILE"
fi

echo "Recording saved as: $OUTPUT_FILE"