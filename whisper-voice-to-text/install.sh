#!/bin/bash
set -e

echo "🎤 Whisper Voice-to-Text Hotkey Service Installer"
echo "================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    print_error "This script is designed for Linux systems only."
    exit 1
fi

# Check for required commands
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is required but not installed."
        return 1
    fi
    return 0
}

print_status "Checking system requirements..."

# Update package list
print_status "Updating package list..."
sudo apt update

# Install system dependencies
print_status "Installing system dependencies..."
sudo apt install -y git build-essential cmake python3 python3-pip \
    ffmpeg portaudio19-dev alsa-utils xdotool

# Check for GPU support
if command -v nvidia-smi &> /dev/null; then
    print_success "NVIDIA GPU detected! Installing CUDA toolkit for acceleration..."
    sudo apt install -y nvidia-cuda-toolkit nvidia-cuda-dev
    GPU_BUILD="GGML_CUDA=1"
else
    print_warning "No NVIDIA GPU detected. Will build CPU-only version."
    GPU_BUILD=""
fi

# Install Python dependencies
print_status "Installing Python dependencies..."
pip3 install --user pynput pyperclip

# Install whisper.cpp
WHISPER_DIR="$HOME/whisper.cpp"
if [ -d "$WHISPER_DIR" ]; then
    print_warning "whisper.cpp already exists at $WHISPER_DIR"
    read -p "Do you want to rebuild it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$WHISPER_DIR"
        print_status "Cleaning previous build..."
        make clean 2>/dev/null || true
    else
        print_status "Skipping whisper.cpp installation."
        SKIP_WHISPER=true
    fi
else
    print_status "Cloning whisper.cpp..."
    git clone https://github.com/ggerganov/whisper.cpp.git "$WHISPER_DIR"
    cd "$WHISPER_DIR"
fi

if [ "$SKIP_WHISPER" != true ]; then
    print_status "Building whisper.cpp..."
    if [ -n "$GPU_BUILD" ]; then
        print_status "Building with GPU acceleration..."
        $GPU_BUILD make -j$(nproc)
    else
        print_status "Building CPU-only version..."
        make -j$(nproc)
    fi

    # Verify build
    if [ -f "build/bin/whisper-cli" ]; then
        print_success "whisper.cpp built successfully!"
    else
        print_error "whisper.cpp build failed!"
        exit 1
    fi
fi

# Test audio system
print_status "Testing audio system..."
if arecord -l | grep -q "card"; then
    print_success "Audio devices detected!"
else
    print_warning "No audio devices found. You may need to configure audio."
fi

# Install the script
SCRIPT_PATH="$HOME/whisper-hotkey.py"
if [ -f "whisper-hotkey.py" ]; then
    cp whisper-hotkey.py "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    print_success "Script installed to $SCRIPT_PATH"
else
    print_error "whisper-hotkey.py not found in current directory!"
    exit 1
fi

# Update path in script if needed
if [ "$WHISPER_DIR" != "/home/tarun/whisper.cpp" ]; then
    print_status "Updating whisper.cpp path in script..."
    sed -i "s|/home/tarun/whisper.cpp|$WHISPER_DIR|g" "$SCRIPT_PATH"
fi

echo
print_success "Installation completed successfully!"
echo
print_status "To run the service:"
echo "  python3 $SCRIPT_PATH"
echo
print_status "Hotkeys:"
echo "  Ctrl + Alt + R: Start recording"
echo "  Ctrl + Alt + S: Stop and transcribe"
echo "  Ctrl + C: Exit"
echo
print_status "The first run will download the Whisper model (~1.5GB)"
print_status "This may take 5-10 minutes depending on your internet speed."
echo

# Ask if user wants to run it now
read -p "Do you want to run the whisper service now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Starting Whisper Voice-to-Text service..."
    python3 "$SCRIPT_PATH"
fi