#!/bin/bash

set -e

echo "🎮 Installing TaskQuest..."
echo ""

# Build the project
echo "📦 Building TaskQuest in release mode..."
cargo build --release

# Check if build was successful
if [ ! -f "target/release/taskquest" ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build successful!"
echo ""

# Ask user where to install
echo "Where would you like to install TaskQuest?"
echo "1) /usr/local/bin (system-wide, requires sudo)"
echo "2) ~/.local/bin (user only, no sudo required)"
echo "3) Just show the binary location (no install)"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo "Installing to /usr/local/bin..."
        sudo cp target/release/taskquest /usr/local/bin/
        echo "✅ TaskQuest installed to /usr/local/bin/taskquest"
        echo "Run it with: taskquest"
        ;;
    2)
        mkdir -p ~/.local/bin
        cp target/release/taskquest ~/.local/bin/
        echo "✅ TaskQuest installed to ~/.local/bin/taskquest"
        echo ""
        echo "⚠️  Make sure ~/.local/bin is in your PATH!"
        echo "Add this to your ~/.bashrc or ~/.zshrc:"
        echo '    export PATH="$HOME/.local/bin:$PATH"'
        echo ""
        echo "Run it with: taskquest"
        ;;
    3)
        echo "📍 Binary location: $(pwd)/target/release/taskquest"
        echo "Run it with: ./target/release/taskquest"
        ;;
    *)
        echo "Invalid choice. Binary is available at: $(pwd)/target/release/taskquest"
        ;;
esac

echo ""
echo "🎉 Installation complete!"
echo "Start your productivity journey: taskquest"
