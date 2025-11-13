use crate::app::{App, InputFocus, InputMode, View};
use crate::models::TaskStatus;
use crate::scoring;
use ratatui::{
    layout::{Alignment, Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{
        Axis, BarChart, Block, Borders, Chart, Dataset, Gauge, GraphType, List, ListItem,
        Paragraph, Wrap,
    },
    Frame,
};

const TASK_LIST_TAB: &str = " [1] Tasks ";
const STATS_TAB: &str = " [2] Stats ";
const HELP_TAB: &str = " [3] Help ";

pub fn render(f: &mut Frame, app: &mut App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3), // Header
            Constraint::Min(0),     // Content
            Constraint::Length(3),  // Footer
        ])
        .split(f.area());

    render_header(f, chunks[0], app);
    render_content(f, chunks[1], app);
    render_footer(f, chunks[2], app);
}

fn render_header(f: &mut Frame, area: Rect, app: &App) {
    let header_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(area);

    // Tabs
    let tabs = vec![
        Span::styled(
            TASK_LIST_TAB,
            if app.current_view == View::TaskList {
                Style::default()
                    .fg(Color::Black)
                    .bg(Color::Cyan)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::Gray)
            },
        ),
        Span::styled(
            STATS_TAB,
            if app.current_view == View::Stats {
                Style::default()
                    .fg(Color::Black)
                    .bg(Color::Cyan)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::Gray)
            },
        ),
        Span::styled(
            HELP_TAB,
            if app.current_view == View::Help {
                Style::default()
                    .fg(Color::Black)
                    .bg(Color::Cyan)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::Gray)
            },
        ),
    ];

    let tabs_widget = Paragraph::new(Line::from(tabs))
        .block(Block::default().borders(Borders::ALL).title(" TaskQuest "));
    f.render_widget(tabs_widget, header_chunks[0]);

    // Stats summary
    let stats_text = format!(
        " Points: {} | Streak: {}🔥 | Completed: {} ",
        app.user_stats.total_points, app.user_stats.current_streak, app.user_stats.tasks_completed
    );
    let stats_widget = Paragraph::new(stats_text)
        .block(Block::default().borders(Borders::ALL))
        .style(Style::default().fg(Color::Green))
        .alignment(Alignment::Right);
    f.render_widget(stats_widget, header_chunks[1]);
}

fn render_content(f: &mut Frame, area: Rect, app: &mut App) {
    match app.current_view {
        View::TaskList => render_task_list(f, area, app),
        View::Stats => render_stats(f, area, app),
        View::Help => render_help(f, area),
    }
}

fn render_task_list(f: &mut Frame, area: Rect, app: &mut App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(5), Constraint::Length(10)])
        .split(area);

    // Task list
    let tasks = app.visible_tasks();
    let items: Vec<ListItem> = tasks
        .iter()
        .enumerate()
        .map(|(i, task)| {
            let status_symbol = match task.status {
                TaskStatus::Pending => "○",
                TaskStatus::InProgress => "▶",
                TaskStatus::Paused => "❚❚",
                TaskStatus::Completed => "✓",
            };

            let status_color = match task.status {
                TaskStatus::Pending => Color::Gray,
                TaskStatus::InProgress => Color::Green,
                TaskStatus::Paused => Color::Yellow,
                TaskStatus::Completed => Color::Blue,
            };

            let difficulty_bar = "▰".repeat(task.difficulty as usize);
            let difficulty_color = match task.difficulty {
                1..=3 => Color::Green,
                4..=6 => Color::Yellow,
                7..=8 => Color::LightRed,
                _ => Color::Red,
            };

            let content = vec![Line::from(vec![
                Span::styled(
                    format!("{} ", status_symbol),
                    Style::default().fg(status_color).add_modifier(Modifier::BOLD),
                ),
                Span::styled(&task.title, Style::default().fg(Color::White)),
                Span::raw(" "),
                Span::styled(
                    format!("[{}]", difficulty_bar),
                    Style::default().fg(difficulty_color),
                ),
                Span::styled(
                    format!(" ({})", task.difficulty),
                    Style::default().fg(Color::DarkGray),
                ),
            ])];

            let style = if i == app.selected_task_index {
                Style::default()
                    .bg(Color::DarkGray)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default()
            };

            ListItem::new(content).style(style)
        })
        .collect();

    let title = if app.show_completed {
        " All Tasks (Press 'c' to hide completed) "
    } else {
        " Active Tasks (Press 'c' to show completed) "
    };

    let list = List::new(items)
        .block(Block::default().borders(Borders::ALL).title(title))
        .highlight_style(Style::default().bg(Color::DarkGray));

    f.render_widget(list, chunks[0]);

    // Task details
    if let Some(task) = app.selected_task() {
        render_task_details(f, chunks[1], task);
    } else {
        let empty = Paragraph::new("No tasks yet! Press 'a' to add one.")
            .block(Block::default().borders(Borders::ALL).title(" Details "))
            .style(Style::default().fg(Color::Gray))
            .alignment(Alignment::Center);
        f.render_widget(empty, chunks[1]);
    }

    // Input overlay
    if app.input_mode != InputMode::Normal {
        render_input_popup(f, f.area(), app);
    }
}

fn render_task_details(f: &mut Frame, area: Rect, task: &crate::models::Task) {
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(60), Constraint::Percentage(40)])
        .split(area);

    // Left: Task info
    let mut info_lines = vec![
        Line::from(vec![
            Span::styled("Title: ", Style::default().fg(Color::Cyan)),
            Span::raw(&task.title),
        ]),
        Line::from(vec![
            Span::styled("Difficulty: ", Style::default().fg(Color::Cyan)),
            Span::raw(format!("{}/10", task.difficulty)),
        ]),
        Line::from(vec![
            Span::styled("Status: ", Style::default().fg(Color::Cyan)),
            Span::raw(task.status.as_str()),
        ]),
    ];

    if let Some(started) = task.started_at {
        info_lines.push(Line::from(vec![
            Span::styled("Started: ", Style::default().fg(Color::Cyan)),
            Span::raw(started.format("%Y-%m-%d %H:%M:%S").to_string()),
        ]));

        if task.status == TaskStatus::InProgress || task.status == TaskStatus::Paused {
            let elapsed = if task.status == TaskStatus::Paused {
                task.paused_at.unwrap_or_else(chrono::Utc::now) - started
            } else {
                chrono::Utc::now() - started
            };
            let active_seconds = elapsed.num_seconds() - task.total_pause_duration;
            let hours = active_seconds / 3600;
            let minutes = (active_seconds % 3600) / 60;
            let seconds = active_seconds % 60;

            info_lines.push(Line::from(vec![
                Span::styled("Active Time: ", Style::default().fg(Color::Cyan)),
                Span::raw(format!("{}h {}m {}s", hours, minutes, seconds)),
            ]));
        }
    }

    if task.status == TaskStatus::Completed {
        info_lines.push(Line::from(vec![
            Span::styled("Points: ", Style::default().fg(Color::Cyan)),
            Span::styled(
                format!("+{}", task.points_earned),
                Style::default()
                    .fg(Color::Green)
                    .add_modifier(Modifier::BOLD),
            ),
        ]));
    }

    let info = Paragraph::new(info_lines)
        .block(Block::default().borders(Borders::ALL).title(" Details "))
        .wrap(Wrap { trim: true });
    f.render_widget(info, chunks[0]);

    // Right: Quick actions
    let actions = vec![
        "Space - Start/Pause",
        "x - Complete",
        "e - Edit",
        "d - Delete",
    ];
    let actions_text: Vec<Line> = actions.iter().map(|s| Line::from(*s)).collect();

    let actions_widget = Paragraph::new(actions_text)
        .block(Block::default().borders(Borders::ALL).title(" Actions "))
        .style(Style::default().fg(Color::Gray));
    f.render_widget(actions_widget, chunks[1]);
}

fn render_input_popup(f: &mut Frame, area: Rect, app: &App) {
    let popup_area = centered_rect(60, 40, area);

    // Background
    let bg = Block::default()
        .borders(Borders::ALL)
        .style(Style::default().bg(Color::Black));
    f.render_widget(bg, popup_area);

    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .margin(2)
        .constraints([
            Constraint::Length(3),
            Constraint::Length(3),
            Constraint::Length(3),
        ])
        .split(popup_area);

    let title = match app.input_mode {
        InputMode::AddingTask => " Add New Task ",
        InputMode::EditingTask => " Edit Task ",
        _ => " Input ",
    };

    // Title input (highlight if active)
    let title_active = app.input_focus == InputFocus::Title;
    let title_input = Paragraph::new(format!("{}{}", app.input_buffer.as_str(), if title_active { "█" } else { "" }))
        .style(Style::default().fg(Color::Yellow))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(if title_active { "► Task Title" } else { "Task Title" })
                .border_style(if title_active {
                    Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)
                } else {
                    Style::default().fg(Color::DarkGray)
                }),
        );
    f.render_widget(title_input, chunks[0]);

    // Difficulty input (highlight if active)
    let difficulty_active = app.input_focus == InputFocus::Difficulty;
    let difficulty_input = Paragraph::new(format!("{}{}", app.difficulty_input.as_str(), if difficulty_active { "█" } else { "" }))
        .style(Style::default().fg(Color::Yellow))
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(if difficulty_active { "► Difficulty (1-10)" } else { "Difficulty (1-10)" })
                .border_style(if difficulty_active {
                    Style::default().fg(Color::Green).add_modifier(Modifier::BOLD)
                } else {
                    Style::default().fg(Color::DarkGray)
                }),
        );
    f.render_widget(difficulty_input, chunks[1]);

    // Instructions
    let instructions = Paragraph::new("Tab: Switch field | Enter: Submit | Esc: Cancel")
        .style(Style::default().fg(Color::Gray))
        .alignment(Alignment::Center);
    f.render_widget(instructions, chunks[2]);

    // Title
    let title_block = Block::default()
        .borders(Borders::ALL)
        .title(title)
        .style(Style::default().fg(Color::Cyan));
    f.render_widget(title_block, popup_area);
}

fn render_stats(f: &mut Frame, area: Rect, app: &mut App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(8),  // Stats overview
            Constraint::Length(15), // Charts
            Constraint::Min(5),     // Recent tasks
        ])
        .split(area);

    // Stats overview
    render_stats_overview(f, chunks[0], app);

    // Charts
    render_charts(f, chunks[1], app);

    // Recent completed tasks
    render_recent_tasks(f, chunks[2], app);
}

fn render_stats_overview(f: &mut Frame, area: Rect, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(area);

    // Left: General stats
    let hours = app.user_stats.total_focus_time / 3600;
    let minutes = (app.user_stats.total_focus_time % 3600) / 60;

    let stats_text = vec![
        Line::from(vec![
            Span::styled("Total Points: ", Style::default().fg(Color::Cyan)),
            Span::styled(
                app.user_stats.total_points.to_string(),
                Style::default()
                    .fg(Color::Green)
                    .add_modifier(Modifier::BOLD),
            ),
        ]),
        Line::from(vec![
            Span::styled("Tasks Completed: ", Style::default().fg(Color::Cyan)),
            Span::raw(app.user_stats.tasks_completed.to_string()),
        ]),
        Line::from(vec![
            Span::styled("Total Focus Time: ", Style::default().fg(Color::Cyan)),
            Span::raw(format!("{}h {}m", hours, minutes)),
        ]),
        Line::from(vec![
            Span::styled("Current Streak: ", Style::default().fg(Color::Cyan)),
            Span::styled(
                format!("{} days 🔥", app.user_stats.current_streak),
                Style::default().fg(Color::Yellow),
            ),
        ]),
        Line::from(vec![
            Span::styled("Longest Streak: ", Style::default().fg(Color::Cyan)),
            Span::raw(format!("{} days", app.user_stats.longest_streak)),
        ]),
    ];

    let stats_widget = Paragraph::new(stats_text)
        .block(Block::default().borders(Borders::ALL).title(" Overview "));
    f.render_widget(stats_widget, chunks[0]);

    // Right: Performance scores
    let completed_tasks = app
        .db
        .get_completed_tasks(50)
        .unwrap_or_default();
    let avg_times = app.db.get_avg_time_by_difficulty().unwrap_or_default();

    let focus_score = scoring::calculate_focus_score(&completed_tasks);
    let efficiency_score = scoring::calculate_efficiency_score(&completed_tasks, &avg_times);

    let gauge_area = Block::default().borders(Borders::ALL).title(" Performance ");
    let inner_area = gauge_area.inner(chunks[1]);
    f.render_widget(gauge_area, chunks[1]);

    let inner_chunks = Layout::default()
        .direction(Direction::Vertical)
        .margin(1)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(inner_area);

    let focus_gauge = Gauge::default()
        .block(Block::default().title("Focus Score"))
        .gauge_style(Style::default().fg(Color::Green))
        .ratio(focus_score as f64 / 100.0);

    let efficiency_gauge = Gauge::default()
        .block(Block::default().title("Efficiency Score"))
        .gauge_style(Style::default().fg(Color::Cyan))
        .ratio(efficiency_score as f64 / 100.0);

    f.render_widget(focus_gauge, inner_chunks[0]);
    f.render_widget(efficiency_gauge, inner_chunks[1]);
}

fn render_charts(f: &mut Frame, area: Rect, app: &mut App) {
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(area);

    // Left: Daily points chart
    if let Ok(daily_stats) = app.db.get_daily_stats(14) {
        let data: Vec<(&str, u64)> = daily_stats
            .iter()
            .rev()
            .take(7)
            .map(|stat| {
                let label = stat.date.format("%m/%d").to_string();
                let label_static: &'static str = Box::leak(label.into_boxed_str());
                (label_static, stat.points_earned.max(0) as u64)
            })
            .collect();

        if !data.is_empty() {
            let chart = BarChart::default()
                .block(Block::default().borders(Borders::ALL).title(" Points (Last 7 Days) "))
                .data(&data)
                .bar_width(5)
                .bar_gap(1)
                .bar_style(Style::default().fg(Color::Green))
                .value_style(Style::default().fg(Color::White));

            f.render_widget(chart, chunks[0]);
        }
    }

    // Right: Focus time chart
    if let Ok(daily_stats) = app.db.get_daily_stats(14) {
        let chart_data: Vec<(f64, f64)> = daily_stats
            .iter()
            .rev()
            .take(7)
            .enumerate()
            .map(|(i, stat)| (i as f64, (stat.focus_time as f64 / 3600.0)))
            .collect();

        if !chart_data.is_empty() {
            let dataset = Dataset::default()
                .name("Hours")
                .marker(ratatui::symbols::Marker::Braille)
                .graph_type(GraphType::Line)
                .style(Style::default().fg(Color::Cyan))
                .data(&chart_data);

            let max_hours = chart_data
                .iter()
                .map(|(_, h)| *h)
                .fold(0.0, f64::max)
                .ceil()
                .max(1.0);

            let x_labels: Vec<Line> = vec![
                Line::from(""),
                Line::from(""),
                Line::from(""),
                Line::from(""),
                Line::from(""),
                Line::from(""),
                Line::from(""),
            ];

            let y_labels: Vec<Line> = vec![
                Line::from("0"),
                Line::from(format!("{:.1}", max_hours / 2.0)),
                Line::from(format!("{:.1}", max_hours)),
            ];

            let chart = Chart::new(vec![dataset])
                .block(Block::default().borders(Borders::ALL).title(" Focus Time (Hours) "))
                .x_axis(
                    Axis::default()
                        .bounds([0.0, 6.0])
                        .labels(x_labels),
                )
                .y_axis(
                    Axis::default()
                        .bounds([0.0, max_hours])
                        .labels(y_labels),
                );

            f.render_widget(chart, chunks[1]);
        }
    }
}

fn render_recent_tasks(f: &mut Frame, area: Rect, app: &App) {
    if let Ok(recent) = app.db.get_completed_tasks(10) {
        let items: Vec<ListItem> = recent
            .iter()
            .map(|task| {
                let line = Line::from(vec![
                    Span::styled("✓ ", Style::default().fg(Color::Green)),
                    Span::raw(&task.title),
                    Span::raw(" "),
                    Span::styled(
                        format!("+{}", task.points_earned),
                        Style::default().fg(Color::Yellow),
                    ),
                ]);
                ListItem::new(line)
            })
            .collect();

        let list = List::new(items).block(
            Block::default()
                .borders(Borders::ALL)
                .title(" Recently Completed "),
        );

        f.render_widget(list, area);
    }
}

fn render_help(f: &mut Frame, area: Rect) {
    let help_text = vec![
        Line::from(vec![
            Span::styled("Task Management", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        ]),
        Line::from("  a         - Add new task"),
        Line::from("  e         - Edit selected task"),
        Line::from("  d         - Delete selected task"),
        Line::from("  Space     - Start/Pause task"),
        Line::from("  x         - Complete task (mark as done)"),
        Line::from("  c         - Toggle completed tasks view"),
        Line::from(""),
        Line::from(vec![
            Span::styled("Navigation", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        ]),
        Line::from("  ↑/k       - Move selection up"),
        Line::from("  ↓/j       - Move selection down"),
        Line::from("  1         - Task List view"),
        Line::from("  2         - Stats view"),
        Line::from("  3         - Help view"),
        Line::from("  q/Esc     - Quit"),
        Line::from(""),
        Line::from(vec![
            Span::styled("Scoring System", Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD)),
        ]),
        Line::from("  • Base points = Difficulty × 10"),
        Line::from("  • Time bonus for fast completion"),
        Line::from("  • Streak multiplier (up to 50% bonus)"),
        Line::from("  • Focus bonus for fewer interruptions"),
        Line::from("  • Milestone rewards at 10, 25, 50, 100+ tasks"),
        Line::from("  • Gradual streak decay (not instant reset!)"),
    ];

    let help = Paragraph::new(help_text)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(" Keyboard Shortcuts & Info "),
        )
        .wrap(Wrap { trim: true });

    f.render_widget(help, area);
}

fn render_footer(f: &mut Frame, area: Rect, app: &App) {
    let status_text = if let Some(msg) = &app.status_message {
        msg.clone()
    } else {
        match app.input_mode {
            InputMode::Normal => "Press 'a' to add task | '?' for help | 'q' to quit".to_string(),
            InputMode::AddingTask | InputMode::EditingTask => {
                "Tab: Switch field | Enter: Submit | Esc: Cancel".to_string()
            }
        }
    };

    let footer = Paragraph::new(status_text)
        .block(Block::default().borders(Borders::ALL))
        .style(Style::default().fg(Color::Gray))
        .alignment(Alignment::Center);

    f.render_widget(footer, area);
}

fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}
