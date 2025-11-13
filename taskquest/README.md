# TaskQuest

A gamified task management TUI (Terminal User Interface) application built with Rust and Ratatui. Track your tasks, earn points, maintain streaks, and visualize your productivity with beautiful graphs!

## Design Philosophy

TaskQuest is designed with **safety and clarity** in mind:
- **Visual Feedback**: Active input fields are clearly highlighted so you always know what you're editing
- **Deliberate Actions**: Task completion uses `x` (not Enter) to prevent accidental completions
- **No Conflicts**: Keyboard shortcuts don't interfere with tmux, alacritty, or other terminal tools

## Features

### Task Management
- Create, edit, and delete tasks
- Assign difficulty levels (1-10) to each task
- Start/pause/complete tasks with time tracking
- View active tasks or all tasks (including completed)

### Intelligent Scoring System
Based on research into effective gamification, TaskQuest implements:

- **Base Points**: Difficulty × 10
- **Time Efficiency Bonus**: Complete tasks faster than average to earn bonus points
- **Streak Multiplier**: Daily completion streaks boost your points (up to 50% bonus)
- **Focus Bonus**: Fewer interruptions (pauses) = higher rewards
- **Milestone Rewards**: Bonus points at 10, 25, 50, 100, 250, 500 tasks
- **Gradual Decay**: Missing a day won't instantly reset your streak - it decays gradually to avoid burnout

### Performance Metrics
- **Focus Score**: Measures how consistently you work without interruptions
- **Efficiency Score**: Tracks how quickly you complete tasks relative to your averages
- **Daily Statistics**: Points earned, tasks completed, and focus time
- **Visual Charts**: Bar charts for daily points, line graphs for focus time

### TUI Features
- Beautiful, colorful interface with progress bars and gauges
- Multiple views: Tasks, Stats, Help
- Mouse support (scroll to navigate task list)
- Keyboard shortcuts designed to avoid conflicts with tmux and alacritty
- Persistent data storage with SQLite

## Installation

### Prerequisites
- Rust (1.70+)
- Cargo

### Build from Source

```bash
cd taskquest
cargo build --release
```

The binary will be available at `target/release/taskquest`

### Install System-wide

```bash
cargo install --path .
```

Or copy the binary:

```bash
sudo cp target/release/taskquest /usr/local/bin/
```

## Usage

Simply run:

```bash
taskquest
```

Or if installed:

```bash
./target/release/taskquest
```

## Keyboard Shortcuts

### Navigation
- `↑` or `k` - Move selection up
- `↓` or `j` - Move selection down
- `1` - Switch to Task List view
- `2` - Switch to Stats view
- `3` or `?` - Switch to Help view
- `q` or `Esc` - Quit application

### Task Management (Task List View)
- `a` - Add new task
- `e` - Edit selected task
- `d` - Delete selected task
- `Space` - Start/Pause task
- `x` - Complete task (mark as done)
- `c` - Toggle completed tasks visibility

### Input Mode
When adding or editing tasks:
- `Tab` - Switch between title and difficulty fields
- `Enter` - Submit task
- `Esc` - Cancel
- **Visual Feedback**: Active field is highlighted with green borders and a cursor indicator (█)
  - Title field shows "► Task Title" when active
  - Difficulty field shows "► Difficulty (1-10)" when active

### Mouse Support
- Scroll wheel - Navigate task list

## Data Storage

All data is stored locally in an SQLite database at:
- Linux/macOS: `~/.local/share/taskquest/tasks.db`
- Windows: `%USERPROFILE%\.local\share\taskquest\tasks.db`

Your tasks, stats, and progress are automatically saved and will persist across sessions.

## Scoring System Details

### How Points Are Calculated

When you complete a task, the system calculates your points based on:

1. **Base Points** = Difficulty × 10
   - A difficulty 5 task gives 50 base points
   - A difficulty 10 task gives 100 base points

2. **Time Efficiency Bonus** (up to 50% of base)
   - If you complete faster than your average for that difficulty
   - First task at a difficulty level gets a small completion bonus

3. **Streak Multiplier** (up to 50% bonus)
   - Complete tasks daily to build your streak
   - Each day adds 5% to your multiplier
   - Gradual decay system prevents harsh penalties

4. **Focus Bonus** (up to 20% of base)
   - Based on active time vs total time
   - Fewer pauses = higher bonus

### Streak System

- Complete at least one task per day to maintain your streak
- Missing 1 day: No penalty
- Missing 2-3 days: Gradual decay (70% bonus pool, 50% streak)
- Missing 4+ days: Significant reset (30% bonus pool, streak reset)

This forgiveness mechanism is based on research showing harsh resets lead to burnout and disengagement.

### Milestones

Earn bonus points when reaching these milestones:
- 10 tasks: +100 points
- 25 tasks: +250 points
- 50 tasks: +500 points
- 100 tasks: +1000 points
- 250 tasks: +2500 points
- 500 tasks: +5000 points

## Screenshots

The application features:
- A clean, colorful task list with status indicators
- Task details showing active time and points
- Performance gauges showing focus and efficiency scores
- Charts visualizing your daily progress
- A comprehensive help screen

## Development

### Project Structure

```
taskquest/
├── src/
│   ├── main.rs          # Main event loop and input handling
│   ├── app.rs           # Application state and business logic
│   ├── db.rs            # SQLite database layer
│   ├── models.rs        # Data structures
│   ├── scoring.rs       # Intelligent scoring algorithms
│   └── ui.rs            # TUI rendering
├── Cargo.toml
└── README.md
```

### Technologies Used

- **Rust**: Systems programming language
- **Ratatui**: Terminal UI framework
- **Crossterm**: Cross-platform terminal manipulation
- **SQLite**: Embedded database for persistence
- **Chrono**: Date and time handling
- **Serde**: Serialization framework

## Research-Based Design

TaskQuest's gamification system is based on research findings:

- 83% of employees report higher motivation with gamified elements
- 43% increase in task completion rates with reward systems
- Streak mechanics drive engagement but require forgiveness mechanisms
- Visual progress representation (charts, graphs) increases engagement by 67%
- Multiple reward factors (difficulty, time, focus) are more effective than single-factor systems

## License

MIT License - feel free to use, modify, and distribute!

## Contributing

Contributions are welcome! Some ideas for enhancements:
- Additional chart types and visualizations
- Export functionality (CSV, JSON)
- Task categories/tags
- Recurring tasks
- Cloud sync options
- Custom themes and color schemes

## Acknowledgments

Built with Rust and powered by the amazing Ratatui library!
