use crate::db::Database;
use crate::models::{Task, TaskStatus, UserStats};
use crate::scoring;
use anyhow::Result;
use chrono::Utc;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum View {
    TaskList,
    Stats,
    Help,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputMode {
    Normal,
    AddingTask,
    EditingTask,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputFocus {
    Title,
    Difficulty,
}

pub struct App {
    pub db: Database,
    pub tasks: Vec<Task>,
    pub user_stats: UserStats,
    pub current_view: View,
    pub input_mode: InputMode,
    pub input_focus: InputFocus,
    pub selected_task_index: usize,
    pub show_completed: bool,
    pub input_buffer: String,
    pub difficulty_input: String,
    pub should_quit: bool,
    pub status_message: Option<String>,
    pub editing_task_id: Option<i64>,
}

impl App {
    pub fn new() -> Result<Self> {
        let db = Database::new()?;
        let tasks = db.get_all_tasks()?;
        let user_stats = db.get_user_stats()?;

        Ok(Self {
            db,
            tasks,
            user_stats,
            current_view: View::TaskList,
            input_mode: InputMode::Normal,
            input_focus: InputFocus::Title,
            selected_task_index: 0,
            show_completed: false,
            input_buffer: String::new(),
            difficulty_input: String::new(),
            should_quit: false,
            status_message: None,
            editing_task_id: None,
        })
    }

    pub fn refresh_tasks(&mut self) -> Result<()> {
        self.tasks = if self.show_completed {
            self.db.get_all_tasks()?
        } else {
            self.db.get_pending_tasks()?
        };
        Ok(())
    }

    pub fn refresh_stats(&mut self) -> Result<()> {
        self.user_stats = self.db.get_user_stats()?;
        Ok(())
    }

    pub fn visible_tasks(&self) -> Vec<&Task> {
        self.tasks.iter().collect()
    }

    pub fn selected_task(&self) -> Option<&Task> {
        self.visible_tasks().get(self.selected_task_index).copied()
    }

    pub fn move_selection_up(&mut self) {
        if self.selected_task_index > 0 {
            self.selected_task_index -= 1;
        }
    }

    pub fn move_selection_down(&mut self) {
        let max_index = self.visible_tasks().len().saturating_sub(1);
        if self.selected_task_index < max_index {
            self.selected_task_index += 1;
        }
    }

    pub fn start_add_task(&mut self) {
        self.input_mode = InputMode::AddingTask;
        self.input_focus = InputFocus::Title;
        self.input_buffer.clear();
        self.difficulty_input = String::from("5");
    }

    pub fn start_edit_task(&mut self) {
        if self.selected_task_index < self.tasks.len() {
            let task = &self.tasks[self.selected_task_index];
            let title = task.title.clone();
            let difficulty = task.difficulty;
            let id = task.id;

            self.input_mode = InputMode::EditingTask;
            self.input_focus = InputFocus::Title;
            self.input_buffer = title;
            self.difficulty_input = difficulty.to_string();
            self.editing_task_id = Some(id);
        }
    }

    pub fn cancel_input(&mut self) {
        self.input_mode = InputMode::Normal;
        self.input_focus = InputFocus::Title;
        self.input_buffer.clear();
        self.difficulty_input.clear();
        self.editing_task_id = None;
    }

    pub fn toggle_input_focus(&mut self) {
        self.input_focus = match self.input_focus {
            InputFocus::Title => InputFocus::Difficulty,
            InputFocus::Difficulty => InputFocus::Title,
        };
    }

    pub fn handle_input_char(&mut self, c: char) {
        match self.input_focus {
            InputFocus::Title => self.input_buffer.push(c),
            InputFocus::Difficulty => {
                if c.is_ascii_digit() && self.difficulty_input.len() < 2 {
                    self.difficulty_input.push(c);
                }
            }
        }
    }

    pub fn handle_input_backspace(&mut self) {
        match self.input_focus {
            InputFocus::Title => {
                self.input_buffer.pop();
            }
            InputFocus::Difficulty => {
                self.difficulty_input.pop();
            }
        }
    }

    pub fn submit_task(&mut self) -> Result<()> {
        let title = self.input_buffer.trim().to_string();
        if title.is_empty() {
            self.status_message = Some("Task title cannot be empty".to_string());
            return Ok(());
        }

        let difficulty = self.difficulty_input.parse::<i32>().unwrap_or(5).clamp(1, 10);

        match self.input_mode {
            InputMode::AddingTask => {
                let task = self.db.create_task(title, difficulty)?;
                self.status_message = Some(format!("Task '{}' added!", task.title));
                self.refresh_tasks()?;
            }
            InputMode::EditingTask => {
                if let Some(task_id) = self.editing_task_id {
                    if let Some(task) = self.tasks.iter_mut().find(|t| t.id == task_id) {
                        task.title = title.clone();
                        task.difficulty = difficulty;
                        self.db.update_task(task)?;
                        self.status_message = Some(format!("Task '{}' updated!", title));
                    }
                }
            }
            _ => {}
        }

        self.cancel_input();
        Ok(())
    }

    pub fn delete_selected_task(&mut self) -> Result<()> {
        if let Some(task) = self.selected_task() {
            let task_id = task.id;
            let task_title = task.title.clone();

            self.db.delete_task(task_id)?;
            self.status_message = Some(format!("Task '{}' deleted", task_title));
            self.refresh_tasks()?;

            // Adjust selection
            if self.selected_task_index >= self.tasks.len() && !self.tasks.is_empty() {
                self.selected_task_index = self.tasks.len() - 1;
            }
        }
        Ok(())
    }

    pub fn toggle_task(&mut self) -> Result<()> {
        if self.selected_task_index >= self.tasks.len() {
            return Ok(());
        }

        let task = &mut self.tasks[self.selected_task_index];
        let status_msg = match task.status {
            TaskStatus::Pending => {
                task.status = TaskStatus::InProgress;
                task.started_at = Some(Utc::now());
                "Task started!"
            }
            TaskStatus::InProgress => {
                task.status = TaskStatus::Paused;
                task.paused_at = Some(Utc::now());
                "Task paused"
            }
            TaskStatus::Paused => {
                if let Some(paused_at) = task.paused_at {
                    let pause_duration = (Utc::now() - paused_at).num_seconds();
                    task.total_pause_duration += pause_duration;
                }
                task.status = TaskStatus::InProgress;
                task.paused_at = None;
                "Task resumed!"
            }
            TaskStatus::Completed => {
                return Ok(());
            }
        };

        let task_clone = task.clone();
        self.db.update_task(&task_clone)?;
        self.status_message = Some(status_msg.to_string());

        Ok(())
    }

    pub fn complete_task(&mut self) -> Result<()> {
        if self.selected_task_index >= self.tasks.len() {
            return Ok(());
        }

        let task = &mut self.tasks[self.selected_task_index];

        if task.status == TaskStatus::Completed {
            self.status_message = Some("Task already completed!".to_string());
            return Ok(());
        }

        // Handle paused state
        if task.status == TaskStatus::Paused {
            if let Some(paused_at) = task.paused_at {
                let pause_duration = (Utc::now() - paused_at).num_seconds();
                task.total_pause_duration += pause_duration;
            }
        }

        // Mark as completed
        task.status = TaskStatus::Completed;
        task.completed_at = Some(Utc::now());

        // Get task data before releasing borrow
        let task_difficulty = task.difficulty;
        let mut task_clone = task.clone();

        // Calculate points
        let avg_times = self.db.get_avg_time_by_difficulty()?;
        let avg_time = avg_times
            .iter()
            .find(|(diff, _)| *diff == task_difficulty)
            .map(|(_, time)| *time);

        let points = scoring::calculate_task_points(&task_clone, &self.user_stats, avg_time);
        task_clone.points_earned = points;

        // Update stats
        scoring::update_stats_on_completion(&mut self.user_stats, &task_clone, points);

        // Update the task in our vector
        self.tasks[self.selected_task_index] = task_clone.clone();

        // Save to database
        self.db.update_task(&task_clone)?;
        self.db.update_user_stats(&self.user_stats)?;

        self.status_message = Some(format!("Task completed! +{} points", points));
        self.refresh_tasks()?;
        self.refresh_stats()?;

        // Move selection if we're hiding completed tasks
        if !self.show_completed && self.selected_task_index >= self.tasks.len() && !self.tasks.is_empty() {
            self.selected_task_index = self.tasks.len() - 1;
        }

        Ok(())
    }

    pub fn toggle_completed_view(&mut self) -> Result<()> {
        self.show_completed = !self.show_completed;
        self.refresh_tasks()?;
        self.selected_task_index = 0;
        Ok(())
    }

    pub fn switch_view(&mut self, view: View) {
        self.current_view = view;
    }
}
