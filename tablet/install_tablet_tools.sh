#!/bin/bash
# Huion Tablet Tools Installation Script

echo "=================================="
echo "Huion Tablet Tools Installer"
echo "=================================="
echo ""

# Update package list
echo "[1/3] Updating package list..."
apt update

# Install diagnostic and configuration tools
echo ""
echo "[2/3] Installing tablet tools..."
apt install -y \
    evtest \
    libinput-tools \
    xserver-xorg-input-libinput \
    xinput

# Optional: Install additional useful tools
echo ""
echo "[3/3] Installing optional GUI tools..."
apt install -y \
    input-utils \
    jstest-gtk

echo ""
echo "=================================="
echo "Installation Complete!"
echo "=================================="
echo ""
echo "Installed tools:"
echo "  - evtest: Test tablet events and pressure"
echo "  - libinput-tools: Advanced input configuration"
echo "  - xinput: X11 input device configuration"
echo "  - input-utils: Input device utilities"
echo "  - jstest-gtk: GUI for testing input devices"
echo ""
echo "To test your tablet pen, run:"
echo "  sudo evtest /dev/input/event29"
echo ""
echo "To see tablet info, run:"
echo "  libinput list-devices"
echo ""
echo "To configure tablet mapping, run:"
echo "  xinput list-props 'HID 256c:006d Pen'"
echo ""
