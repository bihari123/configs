# TMux Session Persistence Guide

## 🎯 What Gets Saved & Restored

After computer restart, your tmux sessions will restore:

### ✅ **Always Restored:**
- ✓ **Session names** and layout
- ✓ **Window names** and positions
- ✓ **Pane splits** and sizes
- ✓ **Working directories** for each pane
- ✓ **Active window/pane** selection

### ⚠️ **Conditionally Restored:**
- ✓ **Running processes** - Only if in the allowed list (see below)
- ✓ **Pane contents** - Saved but NOT in scrollback (see workaround)
- ✓ **Command history** - Only if properly configured (see below)

### ❌ **NOT Restored:**
- ✗ **Bash prompts** - If pane was at a prompt, nothing to restore
- ✗ **Scrollback buffer** - Saved content doesn't go into scrollback
- ✗ **Temporary sessions** - Only [P]ersistent sessions are saved

---

## 🔧 How to Make Process Restoration Work

Process restoration ONLY works for **actively running programs**, not bash prompts.

### **Allowed Processes** (auto-restart on restore):
Currently configured to restore:
- `ssh` - SSH connections
- `psql`, `mysql`, `sqlite3` - Database connections
- `npm start`, `npm run dev` - Node servers
- `python`, `node` - Running scripts
- `go run`, `cargo run` - Running programs

### **Add More Processes:**
Edit `~/.config/tmux/tmux.conf` line 19:
```tmux
set -g @resurrect-processes 'ssh psql mysql "~npm start" "your-program-here"'
```
- Use `~` prefix to restore with exact arguments
- No `~` means restore with generic command

### **Example - Working vs Not Working:**

**✅ WORKS - Process Running:**
```bash
# Start a server in a pane
npm run dev
# Save session: Alt+Shift+s
# Restart computer
# Start tmux
# Result: npm run dev is running again!
```

**❌ DOESN'T WORK - Just a Prompt:**
```bash
# At bash prompt, do nothing
$ _
# Save session: Alt+Shift+s
# Restart computer
# Start tmux
# Result: Just a bash prompt, no commands restored
```

---

## 📜 How to View Saved Pane Contents

Pane contents ARE saved but NOT restored to scrollback buffer.

### **View Saved Contents:**
Press `Alt+Shift+v` to view the last saved contents of current pane.

**Or manually:**
```bash
~/configs/bin/tmux-view-saved-pane [session:window.pane]
```

**Examples:**
```bash
# View current pane's saved contents
~/configs/bin/tmux-view-saved-pane

# View specific pane
~/configs/bin/tmux-view-saved-pane mysession:0.0
```

### **Why Not in Scrollback?**
TMux-resurrect saves pane contents to a file but cannot inject them into the scrollback buffer without:
1. Executing all commands again (dangerous!)
2. Slow line-by-line replay (impractical)

So instead, contents are saved for viewing but don't appear in scrollback.

---

## 💾 Session Types: Persistent vs Temporary

### **[P] Persistent Sessions** (Saved & Restored)
- Created via session menu: `Alt+s` → Select zoxide directory
- Marked with `[P]` in session selector
- Auto-saved every 1 minute
- Restored after restart

### **[T] Temporary Sessions** (NOT Saved)
- Quick scratch sessions
- Marked with `[T]` in session selector
- NOT saved or restored
- Use for temporary work

### **Change Session Type:**
Open session menu (`Alt+s`) and manage session settings.

---

## 🔄 Auto-Save & Auto-Restore

### **Auto-Save (Continuum):**
Sessions auto-save every 1 minute when:
- You're working in a persistent session
- Tmux is running
- No interference

### **Auto-Restore (On Startup):**
When you start tmux after restart:
```bash
tmux
```
All persistent sessions restore automatically!

### **Manual Save:**
Press `Alt+Shift+s` anytime to manually save.

### **Verify What's Saved:**
```bash
~/configs/bin/tmux-verify-save
```

---

## 🧪 Testing Session Persistence

### **Test 1: Basic Restore**
```bash
# 1. Create a persistent session with some panes
Alt+s → Select a directory → Enter
Alt+n → Split pane
cd /tmp
ls -la

# 2. Save manually
Alt+Shift+s

# 3. Kill tmux
tmux kill-server

# 4. Start tmux
tmux

# Result: Session restored with same layout and directories!
```

### **Test 2: Process Restore**
```bash
# 1. Create persistent session
Alt+s → Select directory

# 2. Start a long-running process
python3 -m http.server 8000

# 3. Save
Alt+Shift+s

# 4. Restart computer

# 5. Start tmux
tmux

# Result: Python server is running again!
```

### **Test 3: View Saved Contents**
```bash
# In any pane with history
echo "Line 1"
echo "Line 2"
pwd

# Save
Alt+Shift+s

# View saved contents
Alt+Shift+v

# Result: See all your previous output!
```

---

## 📂 Where Data is Stored

### **Session Data:**
```
~/.tmux/resurrect/
├── last                                    # Symlink to latest save
├── tmux_resurrect_20251119T150418.txt     # Session structure
└── pane_contents.tar.gz                   # Pane scrollback contents
```

### **Logs:**
```
~/.tmux/logs/
├── mysession-0-0-20251119-150000.log      # Continuous logging
└── screen_capture_20251119-150000.txt     # Screen captures
```

---

## 🔑 Keyboard Shortcuts Summary

| Key | Action |
|-----|--------|
| `Alt+s` | Session selector (create/switch) |
| `Alt+Shift+s` | Manual save session |
| `Alt+Shift+v` | View saved pane contents |
| `Alt+Shift+h` | Save complete scrollback to file |
| `Alt+Shift+l` | Toggle continuous logging |
| `Alt+Shift+p` | Screen capture to file |

---

## ⚙️ Configuration Files

### **TMux Config:**
`~/.config/tmux/tmux.conf`
- Lines 9-22: Persistence settings
- Line 19: Process restoration list
- Lines 25-29: Auto-save hooks

### **Helper Scripts:**
```
~/configs/bin/tmux-session-menu          # Session manager
~/configs/bin/tmux-save-persistent       # Save wrapper
~/configs/bin/tmux-resurrect-filter-post # Filter temporary sessions
~/configs/bin/tmux-view-saved-pane       # View saved contents
~/configs/bin/tmux-verify-save           # Verify what's saved
```

---

## 🐛 Troubleshooting

### **Sessions not restoring after restart:**
```bash
# Check if auto-restore is enabled
tmux show-option -gv @continuum-restore
# Should show: on

# Check if sessions were saved
ls -lah ~/.tmux/resurrect/

# Manually restore
~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
```

### **Processes not restarting:**
1. Check if process is in allowed list (line 19 of tmux.conf)
2. Verify process was running when saved (not just at prompt)
3. Test: `grep "your-process" ~/.tmux/resurrect/last`

### **Pane contents not showing:**
This is expected! Pane contents are saved but not restored to scrollback.
- Use: `Alt+Shift+v` to view saved contents
- Or: `Alt+Shift+h` to save current scrollback to file

### **Temporary sessions being saved:**
Check session type in session menu (`Alt+s`). Only `[P]` sessions are saved.

---

## 💡 Best Practices

### **1. Use Persistent Sessions for Work:**
Create persistent sessions for projects you'll return to:
```bash
Alt+s → Select project directory → Enter
```

### **2. Start Long-Running Processes:**
For processes you want restored, keep them running:
```bash
# Good: Will be restored
npm run dev
python3 app.py

# Won't restore: Just a prompt
$ _
```

### **3. Save Before Shutting Down:**
While auto-save runs every minute, save manually before shutdown:
```bash
Alt+Shift+s
```

### **4. Use Logging for Critical Output:**
For important output you need later:
```bash
Alt+Shift+l  # Toggle logging
# Work...
Alt+Shift+l  # Stop logging
# Output saved to ~/.tmux/logs/
```

### **5. Review Saved Contents:**
Before restart, verify what's saved:
```bash
~/configs/bin/tmux-verify-save
```

---

## 🎓 Summary

**What Works After Restart:**
- ✅ Session layout and pane splits
- ✅ Working directories
- ✅ Running processes (if configured)
- ✅ Saved pane contents (viewable with Alt+Shift+v)

**What Doesn't Work:**
- ❌ Bash prompts (nothing to restore)
- ❌ Scrollback buffer (use viewer instead)
- ❌ Temporary sessions (by design)

**Key Point:** Tmux persistence works best with long-running processes (servers, SSH, databases) rather than interactive shell sessions.
