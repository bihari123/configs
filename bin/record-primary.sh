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

# Detect display capabilities
echo "Detecting display capabilities..."

# Get the full xrandr line for the selected display to extract refresh rate
DISPLAY_INFO=$(xrandr --query | grep "^${PRIMARY_DISPLAY} connected")
CURRENT_MODE=$(xrandr --query | grep "^${PRIMARY_DISPLAY}" -A 20 | grep '\*' | head -1)

# Extract refresh rate from current mode (e.g., "1920x1080 60.00*+")
DISPLAY_REFRESH=$(echo "$CURRENT_MODE" | grep -oP '[0-9]+\.[0-9]+(?=\*)')
if [ -z "$DISPLAY_REFRESH" ]; then
    # Fallback: try to get any refresh rate
    DISPLAY_REFRESH=$(echo "$CURRENT_MODE" | grep -oP '[0-9]+\.[0-9]+' | head -1)
fi

# Round refresh rate to nearest integer
DISPLAY_FPS=$(printf "%.0f" "$DISPLAY_REFRESH")

# Cap at 60fps for recording (higher framerates increase file size significantly)
if [ "$DISPLAY_FPS" -gt 60 ]; then
    DISPLAY_FPS=60
fi

# Default to 30 if detection failed
[ -z "$DISPLAY_FPS" ] || [ "$DISPLAY_FPS" -eq 0 ] && DISPLAY_FPS=30

# Calculate appropriate bitrate based on resolution
SCREEN_WIDTH=$(echo $GEOMETRY | cut -d'x' -f1)
SCREEN_HEIGHT=$(echo $GEOMETRY | cut -d'x' -f2)
TOTAL_PIXELS=$((SCREEN_WIDTH * SCREEN_HEIGHT))

# Bitrate calculation for high quality 60fps recording
# Formula: (pixels / 1000) * fps * quality_factor
# Quality factor: 0.20 for high quality, 0.25 for highest quality with webcam
if [ "$WEBCAM_ENABLED" = true ]; then
    QUALITY_FACTOR="0.25"
else
    QUALITY_FACTOR="0.20"
fi

CALCULATED_BITRATE=$(awk "BEGIN {printf \"%.0f\", ($TOTAL_PIXELS / 1000) * $DISPLAY_FPS * $QUALITY_FACTOR}")

# Set reasonable min/max bounds (increased for better quality)
MIN_BITRATE=2000
MAX_BITRATE=20000
if [ "$CALCULATED_BITRATE" -lt "$MIN_BITRATE" ]; then
    DISPLAY_BITRATE=$MIN_BITRATE
elif [ "$CALCULATED_BITRATE" -gt "$MAX_BITRATE" ]; then
    DISPLAY_BITRATE=$MAX_BITRATE
else
    DISPLAY_BITRATE=$CALCULATED_BITRATE
fi

DISPLAY_MAXRATE=$((DISPLAY_BITRATE * 12 / 10))  # 120% of target for peaks
DISPLAY_BUFSIZE=$((DISPLAY_BITRATE * 2))        # 2 seconds buffer

echo "Display configuration:"
echo "  Resolution: $GEOMETRY"
echo "  Refresh rate: ${DISPLAY_REFRESH} Hz"
echo "  Recording FPS: ${DISPLAY_FPS}"
echo "  Bitrate: ${DISPLAY_BITRATE}k"

# Validate and detect webcam capabilities if enabled
if [ "$WEBCAM_ENABLED" = true ]; then
    # Check if webcam device exists
    if [ ! -e "$WEBCAM_DEVICE" ]; then
        echo "Error: Webcam device $WEBCAM_DEVICE not found"
        echo "Available video devices:"
        ls -1 /dev/video* 2>/dev/null || echo "  No video devices found"
        exit 1
    fi

    # Check if v4l2-ctl is available
    if ! command -v v4l2-ctl &> /dev/null; then
        echo "Warning: v4l2-ctl not found, using default settings"
        echo "Install v4l-utils for automatic capability detection"
        WEBCAM_FORMAT="mjpeg"
        FORMAT_FLAG="-input_format mjpeg"
        WEBCAM_RESOLUTION="640x480"
        WEBCAM_FPS="30"
    else
        echo "Detecting webcam capabilities for $WEBCAM_DEVICE..."

        # Query supported formats (prefer MJPEG > YUYV > others)
        if v4l2-ctl -d "$WEBCAM_DEVICE" --list-formats-ext | grep -q "MJPEG"; then
            WEBCAM_FORMAT="mjpeg"
            FORMAT_FLAG="-input_format mjpeg"
        elif v4l2-ctl -d "$WEBCAM_DEVICE" --list-formats-ext | grep -q "YUYV"; then
            WEBCAM_FORMAT="yuyv422"
            FORMAT_FLAG=""
        else
            # Use first available format
            WEBCAM_FORMAT=$(v4l2-ctl -d "$WEBCAM_DEVICE" --list-formats | grep -oP "'\K[^']+" | head -1 | tr '[:upper:]' '[:lower:]')
            FORMAT_FLAG=""
        fi

        # Get available resolutions for the selected format
        AVAILABLE_RESOLUTIONS=$(v4l2-ctl -d "$WEBCAM_DEVICE" --list-formats-ext | \
            awk -v fmt="$WEBCAM_FORMAT" 'toupper($0) ~ toupper(fmt) {flag=1} flag && /Size:/ {print $2}' | \
            sort -t'x' -k1 -k2 -rn)

        # Select best resolution (prefer 1280x720 > 960x540 > 640x480, or highest available)
        if echo "$AVAILABLE_RESOLUTIONS" | grep -q "1280x720"; then
            WEBCAM_RESOLUTION="1280x720"
        elif echo "$AVAILABLE_RESOLUTIONS" | grep -q "960x540"; then
            WEBCAM_RESOLUTION="960x540"
        elif echo "$AVAILABLE_RESOLUTIONS" | grep -q "640x480"; then
            WEBCAM_RESOLUTION="640x480"
        else
            WEBCAM_RESOLUTION=$(echo "$AVAILABLE_RESOLUTIONS" | head -1)
        fi

        # Get supported framerates for selected resolution
        AVAILABLE_FPS=$(v4l2-ctl -d "$WEBCAM_DEVICE" --list-formats-ext | \
            awk -v res="$WEBCAM_RESOLUTION" '$0 ~ res {flag=1} flag && /Interval/ {print $0}' | \
            grep -oP '\(\K[0-9.]+(?= fps)' | sort -rn)

        # Select best framerate (prefer 30fps, or closest to 30)
        if echo "$AVAILABLE_FPS" | grep -q "^30"; then
            WEBCAM_FPS="30"
        elif echo "$AVAILABLE_FPS" | grep -q "^60"; then
            WEBCAM_FPS="60"
        else
            WEBCAM_FPS=$(echo "$AVAILABLE_FPS" | head -1)
        fi

        # Fallback to defaults if detection failed
        [ -z "$WEBCAM_RESOLUTION" ] && WEBCAM_RESOLUTION="640x480"
        [ -z "$WEBCAM_FPS" ] && WEBCAM_FPS="30"
    fi

    # Note about framerate handling
    if [ "$WEBCAM_FPS" != "$DISPLAY_FPS" ]; then
        echo ""
        echo "Note: Display at ${DISPLAY_FPS} fps, webcam at ${WEBCAM_FPS} fps"
        echo "      Output will be ${DISPLAY_FPS} fps (webcam frames will be duplicated to match)"
    fi

    echo ""
    echo "Webcam configuration:"
    echo "  Device: $WEBCAM_DEVICE"
    echo "  Format: $WEBCAM_FORMAT"
    echo "  Resolution: $WEBCAM_RESOLUTION"
    echo "  Framerate: ${WEBCAM_FPS} fps"
fi

# Always use display fps for recording
RECORDING_FPS=$DISPLAY_FPS

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
    # With webcam overlay in bottom right (natural aspect ratio)
    # Fixed width, height scales proportionally
    WEBCAM_WIDTH=320
    PADDING=20

    ffmpeg -f x11grab -framerate $DISPLAY_FPS -probesize 42M -draw_mouse 0 -thread_queue_size 512 -s $GEOMETRY -i :0.0+$OFFSET \
      -f v4l2 $FORMAT_FLAG -video_size $WEBCAM_RESOLUTION -framerate $WEBCAM_FPS -thread_queue_size 512 -i "$WEBCAM_DEVICE" \
      -f pulse -thread_queue_size 512 -i default \
      -filter_complex "[1:v]scale=${WEBCAM_WIDTH}:-1,fps=${RECORDING_FPS}[webcam]; \
                       [0:v][webcam]overlay=W-w-${PADDING}:H-h-${PADDING}[outv]" \
      -map "[outv]" -map 2:a \
      -c:v libx264 -preset slow -tune film -crf 18 -pix_fmt yuv420p \
      -r $RECORDING_FPS -g $((RECORDING_FPS * 2)) \
      -threads 0 -x264-params keyint=$((RECORDING_FPS*4)):min-keyint=$((RECORDING_FPS)):ref=5:bframes=3 \
      -vsync cfr \
      -af "afftdn=nf=-25,highpass=f=200" \
      -c:a aac -ar 48000 -ac 2 -b:a 128k \
      -movflags +faststart \
      "$OUTPUT_FILE"
else
    # Without webcam
    ffmpeg -f x11grab -framerate $DISPLAY_FPS -probesize 42M -draw_mouse 0 -thread_queue_size 512 -s $GEOMETRY -i :0.0+$OFFSET \
      -f pulse -thread_queue_size 512 -i default \
      -c:v libx264 -preset slow -tune film -crf 18 -pix_fmt yuv420p \
      -r $RECORDING_FPS -g $((RECORDING_FPS * 2)) \
      -threads 0 -x264-params keyint=$((RECORDING_FPS*4)):min-keyint=$((RECORDING_FPS)):ref=5:bframes=3 \
      -vsync cfr \
      -af "afftdn=nf=-25,highpass=f=200" \
      -c:a aac -ar 48000 -ac 2 -b:a 128k \
      -movflags +faststart \
      "$OUTPUT_FILE"
fi

echo "Recording saved as: $OUTPUT_FILE"