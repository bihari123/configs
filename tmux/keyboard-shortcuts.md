# Tmux Keyboard Shortcuts

## Basic Commands
- `Ctrl+b` - Prefix key (all commands start with this)

## Session Management
- `prefix + d` - Detach from session
- `prefix + s` - List and switch sessions
- `prefix + $` - Rename current session

## Window Management
- `prefix + c` - Create new window (opens in current directory)
- `prefix + w` - List and switch windows
- `prefix + n` - Next window
- `prefix + p` - Previous window
- `prefix + &` - Kill current window
- `prefix + ,` - Rename current window
- `prefix + 0-9` - Switch to window by number

## Pane Management
- `prefix + "` - Split window horizontally (opens in current directory)
- `prefix + %` - Split window vertically (opens in current directory)
- `prefix + arrow keys` - Navigate between panes
- `prefix + x` - Kill current pane
- `prefix + z` - Toggle pane zoom (fullscreen)
- `prefix + {` - Swap pane with previous
- `prefix + }` - Swap pane with next
- `prefix + o` - Go to next pane
- `prefix + ;` - Go to last active pane

## Custom Shortcuts (from config)
- `prefix + r` - Rename current pane title
- `prefix + B` - Toggle pane border position (top/bottom)

## Pomodoro Timer (tmux-pomodoro-plus)
- `prefix + p` - Start 25-minute coding session 🍅
- `prefix + P` - Cancel/stop timer

## Copy Mode (tmux-yank)
- `prefix + [` - Enter copy mode
- `Space` - Start selection
- `Enter` - Copy selection and exit copy mode
- `prefix + ]` - Paste
- `y` - Copy selection to system clipboard (in copy mode)
- `Y` - Copy current line to system clipboard (in copy mode)

## Plugin Management (TPM)
- `prefix + I` - Install plugins
- `prefix + U` - Update plugins
- `prefix + alt + u` - Uninstall plugins

## Session Persistence (tmux-resurrect)
- `prefix + Ctrl+s` - Save current session
- `prefix + Ctrl+r` - Restore saved session

## Auto-save (tmux-continuum)
- Automatically saves sessions every 15 minutes
- Shows save status in status bar
- `prefix + Ctrl+s` - Manual save

## Mouse Support
- Click to select panes and windows
- Drag to resize panes
- Scroll wheel to scroll through history
- Right-click for context menu

## Reload Configuration
- `prefix + :` then type `source-file ~/.tmux.conf` - Reload config

## Status Bar Information
- **Left:** Session name with modern styling
- **Right:** Date, time, and pomodoro timer status
- **Headers:** Pane number, title, and current command with gradient styling

## Plugins Included
1. **TPM** - Plugin manager
2. **tmux-sensible** - Basic settings and shortcuts
3. **tmux-yank** - Copy to system clipboard
4. **tmux-resurrect** - Save/restore sessions
5. **tmux-continuum** - Auto-save sessions
6. **tmux-pomodoro-plus** - Coding session timer

## tmux-sensible Additional Features
- `prefix + R` - Reload tmux config
- Improved scrolling and mouse support
- Better default key bindings
- Enhanced copy mode

## Complete Plugin Keyboard Shortcuts

### TPM (Tmux Plugin Manager)
- `prefix + I` - Install plugins listed in config
- `prefix + U` - Update all plugins
- `prefix + alt + u` - Remove/uninstall plugins not in config

### tmux-sensible
- `prefix + R` - Reload tmux configuration
- Enables focus events for vim/neovim
- Improves default settings (no additional shortcuts)

### tmux-yank
- `y` - Copy selection to system clipboard (in copy mode)
- `Y` - Copy current line to system clipboard (in copy mode)
- `prefix + y` - Copy current command line to clipboard
- `prefix + Y` - Copy current working directory to clipboard

### tmux-resurrect
- `prefix + Ctrl + s` - Save current tmux environment
- `prefix + Ctrl + r` - Restore tmux environment
- Saves: sessions, windows, panes, their order, current working directory, exact pane layouts, active and alternative sessions, active and alternative windows for each session, windows with focus, active pane for each window, "grouped sessions", programs running within a session

### tmux-continuum
- No keyboard shortcuts (automatic functionality)
- Auto-saves environment every 15 minutes
- Auto-starts tmux on boot (if configured)
- Shows save status: ● (saved) or ○ (not saved) in status bar

### tmux-pomodoro-plus
- `prefix + p` - Start pomodoro timer (25 minutes)
- `prefix + P` - Cancel/stop current timer
- `prefix + Ctrl + p` - Toggle between work and break sessions
- Timer shows in status bar with icons: 🍅 (work), ☕ (break), ✅ (complete)