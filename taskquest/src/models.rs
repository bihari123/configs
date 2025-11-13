use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    pub id: i64,
    pub title: String,
    pub difficulty: i32, // 1-10
    pub status: TaskStatus,
    pub created_at: DateTime<Utc>,
    pub started_at: Option<DateTime<Utc>>,
    pub completed_at: Option<DateTime<Utc>>,
    pub paused_at: Option<DateTime<Utc>>,
    pub total_pause_duration: i64, // seconds
    pub points_earned: i32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum TaskStatus {
    Pending,
    InProgress,
    Paused,
    Completed,
}

impl TaskStatus {
    pub fn as_str(&self) -> &str {
        match self {
            TaskStatus::Pending => "Pending",
            TaskStatus::InProgress => "In Progress",
            TaskStatus::Paused => "Paused",
            TaskStatus::Completed => "Completed",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserStats {
    pub total_points: i32,
    pub current_streak: i32,
    pub longest_streak: i32,
    pub last_completion_date: Option<DateTime<Utc>>,
    pub tasks_completed: i32,
    pub total_focus_time: i64, // seconds
    pub streak_bonus_pool: f32, // Gradual decay instead of instant reset
}

impl Default for UserStats {
    fn default() -> Self {
        Self {
            total_points: 0,
            current_streak: 0,
            longest_streak: 0,
            last_completion_date: None,
            tasks_completed: 0,
            total_focus_time: 0,
            streak_bonus_pool: 1.0,
        }
    }
}

#[derive(Debug, Clone)]
pub struct DailyStats {
    pub date: DateTime<Utc>,
    #[allow(dead_code)]
    pub tasks_completed: i32,
    pub points_earned: i32,
    pub focus_time: i64, // seconds
}

// Reserved for future use - comprehensive performance analytics
#[allow(dead_code)]
#[derive(Debug, Clone)]
pub struct PerformanceMetrics {
    pub avg_completion_time_by_difficulty: Vec<(i32, f64)>, // (difficulty, avg_seconds)
    pub daily_stats: Vec<DailyStats>,
    pub focus_score: f32, // 0-100, based on task interruptions
    pub efficiency_score: f32, // 0-100, based on time vs. expected time
}
