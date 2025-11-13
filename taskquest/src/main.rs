mod app;
mod db;
mod models;
mod scoring;
mod ui;

use app::{App, InputMode, View};
use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEvent, MouseEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    Terminal,
};
use std::io;
use std::time::{Duration, Instant};

fn main() -> Result<()> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Create app
    let mut app = App::new()?;
    let tick_rate = Duration::from_millis(250);
    let res = run_app(&mut terminal, &mut app, tick_rate);

    // Restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("Error: {:?}", err);
    }

    Ok(())
}

fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
    tick_rate: Duration,
) -> Result<()> {
    let mut last_tick = Instant::now();

    loop {
        terminal.draw(|f| ui::render(f, app))?;

        let timeout = tick_rate
            .checked_sub(last_tick.elapsed())
            .unwrap_or_else(|| Duration::from_secs(0));

        if event::poll(timeout)? {
            match event::read()? {
                Event::Key(key) => handle_key_event(app, key)?,
                Event::Mouse(mouse) => handle_mouse_event(app, mouse)?,
                _ => {}
            }
        }

        if last_tick.elapsed() >= tick_rate {
            last_tick = Instant::now();
            // Clear status message after a few seconds
            if app.status_message.is_some() {
                app.status_message = None;
            }
        }

        if app.should_quit {
            return Ok(());
        }
    }
}

fn handle_key_event(app: &mut App, key: KeyEvent) -> Result<()> {
    match app.input_mode {
        InputMode::Normal => handle_normal_mode(app, key)?,
        InputMode::AddingTask | InputMode::EditingTask => handle_input_mode(app, key)?,
    }
    Ok(())
}

fn handle_normal_mode(app: &mut App, key: KeyEvent) -> Result<()> {
    match key.code {
        // Quit
        KeyCode::Char('q') | KeyCode::Esc => {
            app.should_quit = true;
        }

        // Navigation
        KeyCode::Up | KeyCode::Char('k') => {
            app.move_selection_up();
        }
        KeyCode::Down | KeyCode::Char('j') => {
            app.move_selection_down();
        }

        // View switching
        KeyCode::Char('1') => {
            app.switch_view(View::TaskList);
        }
        KeyCode::Char('2') => {
            app.switch_view(View::Stats);
        }
        KeyCode::Char('3') | KeyCode::Char('?') => {
            app.switch_view(View::Help);
        }

        // Task operations (only in task list view)
        KeyCode::Char('a') if app.current_view == View::TaskList => {
            app.start_add_task();
        }
        KeyCode::Char('e') if app.current_view == View::TaskList => {
            app.start_edit_task();
        }
        KeyCode::Char('d') if app.current_view == View::TaskList => {
            app.delete_selected_task()?;
        }
        KeyCode::Char(' ') if app.current_view == View::TaskList => {
            app.toggle_task()?;
        }
        KeyCode::Char('x') if app.current_view == View::TaskList => {
            app.complete_task()?;
        }
        KeyCode::Char('c') if app.current_view == View::TaskList => {
            app.toggle_completed_view()?;
        }

        _ => {}
    }
    Ok(())
}

fn handle_input_mode(app: &mut App, key: KeyEvent) -> Result<()> {
    match key.code {
        KeyCode::Esc => {
            app.cancel_input();
        }
        KeyCode::Enter => {
            app.submit_task()?;
        }
        KeyCode::Tab => {
            app.toggle_input_focus();
        }
        KeyCode::Char(c) => {
            app.handle_input_char(c);
        }
        KeyCode::Backspace => {
            app.handle_input_backspace();
        }
        _ => {}
    }
    Ok(())
}

fn handle_mouse_event(app: &mut App, mouse: event::MouseEvent) -> Result<()> {
    match mouse.kind {
        MouseEventKind::ScrollDown => {
            if app.input_mode == InputMode::Normal && app.current_view == View::TaskList {
                app.move_selection_down();
            }
        }
        MouseEventKind::ScrollUp => {
            if app.input_mode == InputMode::Normal && app.current_view == View::TaskList {
                app.move_selection_up();
            }
        }
        MouseEventKind::Down(_button) => {
            // Could implement click-to-select here
            // For now, keep it simple
        }
        _ => {}
    }
    Ok(())
}
