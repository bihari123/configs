# Whisper Voice-to-Text Hotkey Service

A production-ready voice-to-text transcription service using OpenAI's Whisper model with global hotkey support and intelligent text insertion.

## 🚀 Quick Start

```bash
# 1. Install system dependencies
sudo apt update
sudo apt install -y git build-essential cmake python3 python3-pip
sudo apt install -y ffmpeg portaudio19-dev alsa-utils xdotool

# 2. Install Python dependencies
pip3 install --user pynput pyperclip

# 3. Install whisper.cpp
cd ~
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp
GGML_CUDA=1 make -j8  # For GPU acceleration

# 4. Run the script
python3 whisper-hotkey.py
```

## ⌨️ Hotkeys

- **Ctrl + Alt + R**: Start recording
- **Ctrl + Alt + S**: Stop recording and transcribe
- **Ctrl + C**: Exit application

## ✨ Features

- **🎯 High Accuracy**: Uses Whisper large-v3 model by default
- **⚡ GPU Accelerated**: Sub-second transcription on RTX GPUs
- **🛡️ Hallucination Filter**: Removes "thank you for watching" and other false outputs
- **📝 Vim Integration**: Proper text insertion in Vim/Neovim
- **🔧 Auto-Setup**: Downloads models automatically on first run
- **🎪 Universal**: Works in any text application

## 🎛️ Configuration

Edit the script to change models:

```python
MODEL_NAME = "large-v3"    # Best accuracy (default)
MODEL_NAME = "medium"      # Good balance
MODEL_NAME = "small"       # Fast processing
MODEL_NAME = "base"        # Minimal resources
```

## 📊 Performance

| GPU | Model | Latency | Accuracy |
|-----|-------|---------|----------|
| RTX 4090 | large-v3 | ~500ms | Excellent |
| RTX 3080 | medium | ~300ms | Very Good |
| GTX 1080 | small | ~1s | Good |
| CPU Only | base | ~3s | Decent |

## 🔧 Troubleshooting

See the comprehensive troubleshooting guide in the script comments for:
- Audio device issues
- Permission problems
- GPU acceleration setup
- Model download failures

## 🏗️ Development Notes

This script represents the solution to numerous complex challenges:

1. **Whisper CLI Hanging** - Solved with audio validation and timeouts
2. **Threading Deadlocks** - Fixed with proper signal handling
3. **Audio Corruption** - Resolved with format standardization
4. **Hallucination Filter** - Implemented comprehensive YouTube phrase filtering
5. **Vim Integration** - Added proper mode handling for text editors

## 📄 License

MIT License - Feel free to modify and distribute.

## 👨‍💻 Author

**Tarun Thakur**

## 🙏 Acknowledgments

Built using:
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) by Georgi Gerganov
- [OpenAI Whisper](https://github.com/openai/whisper) models
- [pynput](https://github.com/moses-palmer/pynput) for global hotkeys