use crate::models::{DailyStats, Task, TaskStatus, UserStats};
use anyhow::{Context, Result};
use chrono::{DateTime, NaiveDateTime, TimeZone, Utc};
use rusqlite::{params, Connection};
use std::path::PathBuf;

pub struct Database {
    conn: Connection,
}

impl Database {
    pub fn new() -> Result<Self> {
        let db_path = Self::get_db_path()?;

        // Create parent directory if it doesn't exist
        if let Some(parent) = db_path.parent() {
            std::fs::create_dir_all(parent)?;
        }

        let conn = Connection::open(&db_path)
            .context("Failed to open database")?;

        let mut db = Self { conn };
        db.init_schema()?;
        Ok(db)
    }

    fn get_db_path() -> Result<PathBuf> {
        let home = std::env::var("HOME")
            .or_else(|_| std::env::var("USERPROFILE"))
            .context("Could not determine home directory")?;

        let mut path = PathBuf::from(home);
        path.push(".local");
        path.push("share");
        path.push("taskquest");
        path.push("tasks.db");

        Ok(path)
    }

    fn init_schema(&mut self) -> Result<()> {
        self.conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                difficulty INTEGER NOT NULL CHECK(difficulty >= 1 AND difficulty <= 10),
                status TEXT NOT NULL,
                created_at TEXT NOT NULL,
                started_at TEXT,
                completed_at TEXT,
                paused_at TEXT,
                total_pause_duration INTEGER DEFAULT 0,
                points_earned INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS user_stats (
                id INTEGER PRIMARY KEY CHECK(id = 1),
                total_points INTEGER DEFAULT 0,
                current_streak INTEGER DEFAULT 0,
                longest_streak INTEGER DEFAULT 0,
                last_completion_date TEXT,
                tasks_completed INTEGER DEFAULT 0,
                total_focus_time INTEGER DEFAULT 0,
                streak_bonus_pool REAL DEFAULT 1.0
            );

            INSERT OR IGNORE INTO user_stats (id) VALUES (1);

            CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
            CREATE INDEX IF NOT EXISTS idx_tasks_completed_at ON tasks(completed_at);
            ",
        )?;
        Ok(())
    }

    // Task operations
    pub fn create_task(&mut self, title: String, difficulty: i32) -> Result<Task> {
        let now = Utc::now();
        let now_str = now.to_rfc3339();

        self.conn.execute(
            "INSERT INTO tasks (title, difficulty, status, created_at) VALUES (?1, ?2, ?3, ?4)",
            params![title, difficulty, "Pending", now_str],
        )?;

        let id = self.conn.last_insert_rowid();

        Ok(Task {
            id,
            title,
            difficulty,
            status: TaskStatus::Pending,
            created_at: now,
            started_at: None,
            completed_at: None,
            paused_at: None,
            total_pause_duration: 0,
            points_earned: 0,
        })
    }

    pub fn get_all_tasks(&self) -> Result<Vec<Task>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, difficulty, status, created_at, started_at, completed_at,
                    paused_at, total_pause_duration, points_earned
             FROM tasks ORDER BY created_at DESC"
        )?;

        let tasks = stmt
            .query_map([], |row| {
                Ok(Task {
                    id: row.get(0)?,
                    title: row.get(1)?,
                    difficulty: row.get(2)?,
                    status: Self::parse_status(row.get::<_, String>(3)?),
                    created_at: Self::parse_datetime(row.get(4)?),
                    started_at: row.get::<_, Option<String>>(5)?.map(|s| Self::parse_datetime(s)),
                    completed_at: row.get::<_, Option<String>>(6)?.map(|s| Self::parse_datetime(s)),
                    paused_at: row.get::<_, Option<String>>(7)?.map(|s| Self::parse_datetime(s)),
                    total_pause_duration: row.get(8)?,
                    points_earned: row.get(9)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;

        Ok(tasks)
    }

    pub fn get_pending_tasks(&self) -> Result<Vec<Task>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, difficulty, status, created_at, started_at, completed_at,
                    paused_at, total_pause_duration, points_earned
             FROM tasks WHERE status IN ('Pending', 'InProgress', 'Paused')
             ORDER BY created_at DESC"
        )?;

        let tasks = stmt
            .query_map([], |row| {
                Ok(Task {
                    id: row.get(0)?,
                    title: row.get(1)?,
                    difficulty: row.get(2)?,
                    status: Self::parse_status(row.get::<_, String>(3)?),
                    created_at: Self::parse_datetime(row.get(4)?),
                    started_at: row.get::<_, Option<String>>(5)?.map(|s| Self::parse_datetime(s)),
                    completed_at: row.get::<_, Option<String>>(6)?.map(|s| Self::parse_datetime(s)),
                    paused_at: row.get::<_, Option<String>>(7)?.map(|s| Self::parse_datetime(s)),
                    total_pause_duration: row.get(8)?,
                    points_earned: row.get(9)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;

        Ok(tasks)
    }

    pub fn update_task(&mut self, task: &Task) -> Result<()> {
        self.conn.execute(
            "UPDATE tasks SET title = ?1, difficulty = ?2, status = ?3, started_at = ?4,
                    completed_at = ?5, paused_at = ?6, total_pause_duration = ?7, points_earned = ?8
             WHERE id = ?9",
            params![
                task.title,
                task.difficulty,
                Self::status_to_string(&task.status),
                task.started_at.map(|dt| dt.to_rfc3339()),
                task.completed_at.map(|dt| dt.to_rfc3339()),
                task.paused_at.map(|dt| dt.to_rfc3339()),
                task.total_pause_duration,
                task.points_earned,
                task.id,
            ],
        )?;
        Ok(())
    }

    pub fn delete_task(&mut self, task_id: i64) -> Result<()> {
        self.conn.execute("DELETE FROM tasks WHERE id = ?1", params![task_id])?;
        Ok(())
    }

    // User stats operations
    pub fn get_user_stats(&self) -> Result<UserStats> {
        let mut stmt = self.conn.prepare(
            "SELECT total_points, current_streak, longest_streak, last_completion_date,
                    tasks_completed, total_focus_time, streak_bonus_pool
             FROM user_stats WHERE id = 1"
        )?;

        let stats = stmt.query_row([], |row| {
            Ok(UserStats {
                total_points: row.get(0)?,
                current_streak: row.get(1)?,
                longest_streak: row.get(2)?,
                last_completion_date: row.get::<_, Option<String>>(3)?.map(|s| Self::parse_datetime(s)),
                tasks_completed: row.get(4)?,
                total_focus_time: row.get(5)?,
                streak_bonus_pool: row.get(6)?,
            })
        })?;

        Ok(stats)
    }

    pub fn update_user_stats(&mut self, stats: &UserStats) -> Result<()> {
        self.conn.execute(
            "UPDATE user_stats SET total_points = ?1, current_streak = ?2, longest_streak = ?3,
                    last_completion_date = ?4, tasks_completed = ?5, total_focus_time = ?6,
                    streak_bonus_pool = ?7
             WHERE id = 1",
            params![
                stats.total_points,
                stats.current_streak,
                stats.longest_streak,
                stats.last_completion_date.map(|dt| dt.to_rfc3339()),
                stats.tasks_completed,
                stats.total_focus_time,
                stats.streak_bonus_pool,
            ],
        )?;
        Ok(())
    }

    // Analytics
    pub fn get_daily_stats(&self, days: i32) -> Result<Vec<DailyStats>> {
        let cutoff = Utc::now() - chrono::Duration::days(days as i64);
        let cutoff_str = cutoff.to_rfc3339();

        let mut stmt = self.conn.prepare(
            "SELECT DATE(completed_at) as date,
                    COUNT(*) as tasks_completed,
                    SUM(points_earned) as points_earned,
                    SUM((JULIANDAY(completed_at) - JULIANDAY(started_at)) * 86400 - total_pause_duration) as focus_time
             FROM tasks
             WHERE status = 'Completed' AND completed_at >= ?1
             GROUP BY DATE(completed_at)
             ORDER BY date DESC"
        )?;

        let stats = stmt
            .query_map(params![cutoff_str], |row| {
                let date_str: String = row.get(0)?;
                let date = NaiveDateTime::parse_from_str(&format!("{} 00:00:00", date_str), "%Y-%m-%d %H:%M:%S")
                    .ok()
                    .and_then(|naive| Utc.from_local_datetime(&naive).single())
                    .unwrap_or_else(Utc::now);

                Ok(DailyStats {
                    date,
                    tasks_completed: row.get(1)?,
                    points_earned: row.get(2)?,
                    focus_time: row.get::<_, Option<i64>>(3)?.unwrap_or(0),
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;

        Ok(stats)
    }

    pub fn get_avg_time_by_difficulty(&self) -> Result<Vec<(i32, f64)>> {
        let mut stmt = self.conn.prepare(
            "SELECT difficulty,
                    AVG((JULIANDAY(completed_at) - JULIANDAY(started_at)) * 86400 - total_pause_duration) as avg_time
             FROM tasks
             WHERE status = 'Completed' AND started_at IS NOT NULL AND completed_at IS NOT NULL
             GROUP BY difficulty"
        )?;

        let avgs = stmt
            .query_map([], |row| {
                Ok((row.get(0)?, row.get(1)?))
            })?
            .collect::<Result<Vec<_>, _>>()?;

        Ok(avgs)
    }

    pub fn get_completed_tasks(&self, limit: usize) -> Result<Vec<Task>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, title, difficulty, status, created_at, started_at, completed_at,
                    paused_at, total_pause_duration, points_earned
             FROM tasks
             WHERE status = 'Completed'
             ORDER BY completed_at DESC
             LIMIT ?1"
        )?;

        let tasks = stmt
            .query_map(params![limit], |row| {
                Ok(Task {
                    id: row.get(0)?,
                    title: row.get(1)?,
                    difficulty: row.get(2)?,
                    status: Self::parse_status(row.get::<_, String>(3)?),
                    created_at: Self::parse_datetime(row.get(4)?),
                    started_at: row.get::<_, Option<String>>(5)?.map(|s| Self::parse_datetime(s)),
                    completed_at: row.get::<_, Option<String>>(6)?.map(|s| Self::parse_datetime(s)),
                    paused_at: row.get::<_, Option<String>>(7)?.map(|s| Self::parse_datetime(s)),
                    total_pause_duration: row.get(8)?,
                    points_earned: row.get(9)?,
                })
            })?
            .collect::<Result<Vec<_>, _>>()?;

        Ok(tasks)
    }

    // Helper functions
    fn parse_status(s: String) -> TaskStatus {
        match s.as_str() {
            "Pending" => TaskStatus::Pending,
            "InProgress" => TaskStatus::InProgress,
            "Paused" => TaskStatus::Paused,
            "Completed" => TaskStatus::Completed,
            _ => TaskStatus::Pending,
        }
    }

    fn status_to_string(status: &TaskStatus) -> String {
        match status {
            TaskStatus::Pending => "Pending".to_string(),
            TaskStatus::InProgress => "InProgress".to_string(),
            TaskStatus::Paused => "Paused".to_string(),
            TaskStatus::Completed => "Completed".to_string(),
        }
    }

    fn parse_datetime(s: String) -> DateTime<Utc> {
        DateTime::parse_from_rfc3339(&s)
            .map(|dt| dt.with_timezone(&Utc))
            .unwrap_or_else(|_| Utc::now())
    }
}
