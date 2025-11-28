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
            echo ""
            echo "Record your screen or a specific window with optional webcam overlay."
            echo ""
            echo "Options:"
            echo "  -w, --webcam          Enable webcam overlay in bottom right"
            echo "  --webcam-device       Specify webcam device (default: /dev/video0)"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Ask user for recording mode
echo "Recording mode:"
echo "  1. Whole screen"
echo "  2. Window"
echo ""

while true; do
    read -p "Choose recording mode (1-2): " MODE_CHOICE
    if [[ "$MODE_CHOICE" == "1" ]]; then
        RECORDING_MODE="screen"
        break
    elif [[ "$MODE_CHOICE" == "2" ]]; then
        RECORDING_MODE="window"
        break
    else
        echo "Invalid choice. Please enter 1 or 2"
    fi
done

if [ "$RECORDING_MODE" = "window" ]; then
    # List all windows
    echo ""
    echo "Detecting windows..."

    # Try wmctrl first (cleaner output), fall back to xwininfo
    if command -v wmctrl &> /dev/null; then
        # Use wmctrl for cleaner window list
        mapfile -t WINDOW_IDS < <(wmctrl -l | awk '{print $1}')
        mapfile -t WINDOW_NAMES < <(wmctrl -l | cut -d' ' -f5-)

        if [ ${#WINDOW_IDS[@]} -eq 0 ]; then
            echo "Error: No windows found"
            exit 1
        fi
    elif command -v xwininfo &> /dev/null; then
        # Fall back to xwininfo with better filtering
        # Get all window info at once
        WINDOW_TREE=$(xwininfo -root -tree)

        # Arrays to collect valid windows
        WINDOW_IDS=()
        WINDOW_NAMES=()

        # Parse each line and filter
        while IFS= read -r line; do
            # Skip if doesn't match window format
            if ! echo "$line" | grep -qE '^\s+0x[0-9a-f]+'; then
                continue
            fi

            # Extract window ID
            WID=$(echo "$line" | awk '{print $1}')

            # Extract window name (between quotes)
            WNAME=$(echo "$line" | sed -n 's/.*"\(.*\)".*/\1/p')

            # Skip if no name or has problematic patterns
            if [ -z "$WNAME" ] || \
               [[ "$WNAME" == *"has no name"* ]] || \
               [[ "$WNAME" == "Desktop" ]] || \
               [[ "$WNAME" == "xfce4-panel" ]] || \
               [[ "$WNAME" == "Plank" ]]; then
                continue
            fi

            # Extract geometry
            GEOM=$(echo "$line" | grep -oE '[0-9]+x[0-9]+')

            # Skip 1x1 windows (likely hidden/system windows)
            if [ "$GEOM" = "1x1" ]; then
                continue
            fi

            # Skip if no geometry found
            if [ -z "$GEOM" ]; then
                continue
            fi

            # This is a valid window, add it
            WINDOW_IDS+=("$WID")
            WINDOW_NAMES+=("$WNAME")
        done <<< "$WINDOW_TREE"

        if [ ${#WINDOW_IDS[@]} -eq 0 ]; then
            echo "Error: No windows found"
            exit 1
        fi
    else
        echo "Error: Neither wmctrl nor xwininfo found. Please install wmctrl or x11-utils package."
        exit 1
    fi

    # Show available windows
    echo "Available windows:"
    for i in "${!WINDOW_IDS[@]}"; do
        echo "  $((i+1)). ${WINDOW_NAMES[$i]}"
    done
    echo ""

    # Ask user to choose
    while true; do
        read -p "Choose window to record (1-${#WINDOW_IDS[@]}): " WINDOW_CHOICE
        if [[ "$WINDOW_CHOICE" =~ ^[0-9]+$ ]] && [ "$WINDOW_CHOICE" -ge 1 ] && [ "$WINDOW_CHOICE" -le ${#WINDOW_IDS[@]} ]; then
            SELECTED_WINDOW_ID="${WINDOW_IDS[$((WINDOW_CHOICE-1))]}"
            SELECTED_WINDOW_NAME="${WINDOW_NAMES[$((WINDOW_CHOICE-1))]}"
            break
        else
            echo "Invalid choice. Please enter a number between 1 and ${#WINDOW_IDS[@]}"
        fi
    done

    echo "Selected window: $SELECTED_WINDOW_NAME ($SELECTED_WINDOW_ID)"
else
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
fi

# Get geometry based on recording mode
if [ "$RECORDING_MODE" = "window" ]; then
    # Get window geometry
    WINDOW_INFO=$(xwininfo -id "$SELECTED_WINDOW_ID")

    # Extract absolute position and dimensions
    ABS_X=$(echo "$WINDOW_INFO" | grep "Absolute upper-left X:" | awk '{print $4}')
    ABS_Y=$(echo "$WINDOW_INFO" | grep "Absolute upper-left Y:" | awk '{print $4}')
    WIDTH=$(echo "$WINDOW_INFO" | grep "Width:" | awk '{print $2}')
    HEIGHT=$(echo "$WINDOW_INFO" | grep "Height:" | awk '{print $2}')

    if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
        echo "Error: Could not get window geometry"
        exit 1
    fi

    # Ensure dimensions are divisible by 2 (required for H.264 encoding)
    # Round down to nearest even number
    WIDTH=$((WIDTH - (WIDTH % 2)))
    HEIGHT=$((HEIGHT - (HEIGHT % 2)))

    GEOMETRY="${WIDTH}x${HEIGHT}"
    OFFSET="${ABS_X},${ABS_Y}"

    echo "Window geometry: ${GEOMETRY} at offset ${OFFSET}"
fi

# Detect display capabilities
echo "Detecting display capabilities..."

# Get the full xrandr line for the selected display to extract refresh rate
if [ "$RECORDING_MODE" = "screen" ]; then
    DISPLAY_INFO=$(xrandr --query | grep "^${PRIMARY_DISPLAY} connected")
    CURRENT_MODE=$(xrandr --query | grep "^${PRIMARY_DISPLAY}" -A 20 | grep '\*' | head -1)
else
    # For window mode, get info from the primary/first connected display
    DISPLAY_INFO=$(xrandr --query | grep " connected" | head -1)
    DISPLAY_NAME=$(echo "$DISPLAY_INFO" | cut -d" " -f1)
    CURRENT_MODE=$(xrandr --query | grep "^${DISPLAY_NAME}" -A 20 | grep '\*' | head -1)
fi

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

# Detect and select audio input device
echo ""
echo "Detecting audio input devices..."

# Get list of pulse audio sources
mapfile -t AUDIO_SOURCES < <(pactl list sources short | awk '{print $2}')
mapfile -t AUDIO_DESCRIPTIONS < <(pactl list sources | grep -E "Name:|Description:" | paste - - | sed 's/.*Name: //' | sed 's/Description: /- /')

if [ ${#AUDIO_SOURCES[@]} -eq 0 ]; then
    echo "Warning: No audio sources found, using default"
    AUDIO_DEVICE="default"
else
    # Show available audio sources
    echo "Available audio input devices:"
    for i in "${!AUDIO_SOURCES[@]}"; do
        echo "  $((i+1)). ${AUDIO_DESCRIPTIONS[$i]}"
    done
    echo ""

    # Ask user to choose
    while true; do
        read -p "Choose audio input device (1-${#AUDIO_SOURCES[@]}): " AUDIO_CHOICE
        if [[ "$AUDIO_CHOICE" =~ ^[0-9]+$ ]] && [ "$AUDIO_CHOICE" -ge 1 ] && [ "$AUDIO_CHOICE" -le ${#AUDIO_SOURCES[@]} ]; then
            AUDIO_DEVICE="${AUDIO_SOURCES[$((AUDIO_CHOICE-1))]}"
            break
        else
            echo "Invalid choice. Please enter a number between 1 and ${#AUDIO_SOURCES[@]}"
        fi
    done

    echo "Selected audio device: $AUDIO_DEVICE"
fi

# Ask user for output filename
while true; do
    read -p "Enter output filename (without .mp4 extension): " FILENAME

    # Add .mp4 extension if not provided
    if [[ "$FILENAME" != *.mp4 ]]; then
        OUTPUT_FILE="${FILENAME}.mp4"
    else
        OUTPUT_FILE="$FILENAME"
    fi

    # Check if file already exists
    if [ -e "$OUTPUT_FILE" ]; then
        echo "Error: File '$OUTPUT_FILE' already exists. Please choose a different name."
    else
        break
    fi
done

if [ "$RECORDING_MODE" = "screen" ]; then
    echo "Recording primary display: $PRIMARY_DISPLAY"
else
    echo "Recording window: $SELECTED_WINDOW_NAME"
fi
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
      -f pulse -thread_queue_size 512 -i "$AUDIO_DEVICE" \
      -filter_complex "[1:v]scale=${WEBCAM_WIDTH}:-1,fps=${RECORDING_FPS}[webcam]; \
                       [0:v][webcam]overlay=W-w-${PADDING}:H-h-${PADDING}[outv]" \
      -map "[outv]" -map 2:a \
      -c:v libx264 -preset slow -tune film -crf 18 -pix_fmt yuv420p \
      -r $RECORDING_FPS -g $((RECORDING_FPS * 2)) \
      -threads 0 -x264-params keyint=$((RECORDING_FPS*4)):min-keyint=$((RECORDING_FPS)):ref=5:bframes=3 \
      -fps_mode cfr \
      -af "afftdn=nf=-25,highpass=f=200" \
      -c:a aac -ar 48000 -ac 2 -b:a 128k \
      -movflags +faststart \
      "$OUTPUT_FILE"
else
    # Without webcam
    ffmpeg -f x11grab -framerate $DISPLAY_FPS -probesize 42M -draw_mouse 0 -thread_queue_size 512 -s $GEOMETRY -i :0.0+$OFFSET \
      -f pulse -thread_queue_size 512 -i "$AUDIO_DEVICE" \
      -c:v libx264 -preset slow -tune film -crf 18 -pix_fmt yuv420p \
      -r $RECORDING_FPS -g $((RECORDING_FPS * 2)) \
      -threads 0 -x264-params keyint=$((RECORDING_FPS*4)):min-keyint=$((RECORDING_FPS)):ref=5:bframes=3 \
      -fps_mode cfr \
      -af "afftdn=nf=-25,highpass=f=200" \
      -c:a aac -ar 48000 -ac 2 -b:a 128k \
      -movflags +faststart \
      "$OUTPUT_FILE"
fi

echo "Recording saved as: $OUTPUT_FILE"