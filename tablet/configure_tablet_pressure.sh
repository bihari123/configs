#!/bin/bash
# Huion Tablet Pressure Sensitivity Configuration

echo "=================================="
echo "Huion Tablet Pressure Configuration"
echo "=================================="
echo ""

# Check current device info
echo "[1] Checking tablet device info..."
echo ""
echo "Running evtest to detect pressure range..."
echo "Please press your pen on the tablet with varying pressure for 5 seconds..."
echo ""

timeout 5 evtest /dev/input/event29 2>&1 | tee /tmp/tablet_test.log | grep -E "PRESSURE|ABS_"

echo ""
echo "[2] Device Properties:"
xinput list-props "HID 256c:006d Pen"

echo ""
echo "=================================="
echo "Configuration Options"
echo "=================================="
echo ""
echo "For libinput devices (like your Huion), pressure sensitivity"
echo "is primarily configured in your drawing application:"
echo ""
echo "In KRITA:"
echo "  Settings → Configure Krita → Tablet Settings"
echo "  - Adjust pressure curve"
echo "  - Enable tablet support"
echo ""
echo "In GIMP:"
echo "  Edit → Input Devices → Configure Extended Input Devices"
echo "  - Set device to 'Screen' mode"
echo "  - Adjust pressure curve in brush dynamics"
echo ""
echo "In Inkscape:"
echo "  Edit → Preferences → Input Devices"
echo "  - Set pen to 'Screen' mode"
echo ""
echo "To create a custom system-wide pressure curve, we can create"
echo "an X11 configuration file."
echo ""
read -p "Would you like to create a custom X11 config? (y/n): " CREATE_CONFIG

if [[ "$CREATE_CONFIG" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Creating X11 configuration..."

    cat > /etc/X11/xorg.conf.d/50-huion-tablet.conf << 'EOF'
# Huion Tablet Configuration
Section "InputClass"
    Identifier "Huion Pen"
    MatchProduct "HID 256c:006d"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"

    # Pressure curve adjustment (optional)
    # Option "PressCurve" "0 10 90 100"  # Softer curve for more sensitivity
    # Option "PressCurve" "0 0 100 100"  # Linear (default)
    # Option "PressCurve" "10 0 100 90"  # Harder curve for less sensitivity
EndSection
EOF

    echo ""
    echo "Configuration file created at: /etc/X11/xorg.conf.d/50-huion-tablet.conf"
    echo ""
    echo "To edit the pressure curve, uncomment and modify the PressCurve option"
    echo "then restart X11 (logout/login) or reboot."
fi

echo ""
echo "=================================="
echo "Done!"
echo "=================================="
