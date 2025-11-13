use crate::models::{Task, UserStats};
use chrono::Utc;

const BASE_POINTS_MULTIPLIER: i32 = 10;
const MILESTONE_THRESHOLDS: &[i32] = &[10, 25, 50, 100, 250, 500];
const MILESTONE_BONUS: i32 = 100;

/// Calculate points for a completed task based on multiple factors
pub fn calculate_task_points(
    task: &Task,
    user_stats: &UserStats,
    avg_time_for_difficulty: Option<f64>,
) -> i32 {
    // Base points from difficulty
    let base_points = task.difficulty * BASE_POINTS_MULTIPLIER;

    // Time efficiency bonus
    let time_bonus = calculate_time_bonus(task, avg_time_for_difficulty);

    // Streak multiplier (with gradual decay)
    let streak_multiplier = calculate_streak_multiplier(user_stats);

    // Focus bonus (fewer pauses = higher bonus)
    let focus_bonus = calculate_focus_bonus(task);

    // Apply multipliers and bonuses
    let total_points = ((base_points as f32 * streak_multiplier) + time_bonus + focus_bonus) as i32;

    total_points.max(base_points / 2) // Minimum 50% of base points
}

/// Calculate bonus for completing task quickly
fn calculate_time_bonus(task: &Task, avg_time: Option<f64>) -> f32 {
    if let (Some(started), Some(completed)) = (task.started_at, task.completed_at) {
        let actual_time = (completed - started).num_seconds() as f64 - task.total_pause_duration as f64;

        if let Some(avg) = avg_time {
            if actual_time < avg {
                // Faster than average: bonus up to 50% of base points
                let speed_ratio = ((avg - actual_time) / avg) as f32;
                return (task.difficulty * BASE_POINTS_MULTIPLIER) as f32 * speed_ratio.min(0.5);
            }
        } else {
            // First task of this difficulty: small completion bonus
            return (task.difficulty * 2) as f32;
        }
    }
    0.0
}

/// Calculate streak multiplier with forgiveness mechanism
fn calculate_streak_multiplier(stats: &UserStats) -> f32 {
    // Base multiplier from streak
    let streak_mult = 1.0 + (stats.current_streak as f32 * 0.05).min(0.5); // Max 50% bonus

    // Apply bonus pool (decays gradually instead of instant reset)
    streak_mult * stats.streak_bonus_pool
}

/// Calculate focus bonus based on task interruptions (pauses)
fn calculate_focus_bonus(task: &Task) -> f32 {
    if let (Some(started), Some(completed)) = (task.started_at, task.completed_at) {
        let total_time = (completed - started).num_seconds();
        let active_time = total_time - task.total_pause_duration;

        if total_time > 0 {
            let focus_ratio = active_time as f32 / total_time as f32;
            // Higher focus ratio = more bonus (up to 20% of base points)
            return (task.difficulty * BASE_POINTS_MULTIPLIER) as f32 * (focus_ratio - 0.8).max(0.0) * 0.5;
        }
    }
    0.0
}

/// Update user stats after completing a task
pub fn update_stats_on_completion(stats: &mut UserStats, task: &Task, points: i32) {
    stats.total_points += points;
    stats.tasks_completed += 1;

    // Update focus time
    if let (Some(started), Some(completed)) = (task.started_at, task.completed_at) {
        let active_time = (completed - started).num_seconds() - task.total_pause_duration;
        stats.total_focus_time += active_time;
    }

    // Update streaks
    update_streak(stats);

    // Check for milestone bonuses
    if MILESTONE_THRESHOLDS.contains(&stats.tasks_completed) {
        stats.total_points += MILESTONE_BONUS * (stats.tasks_completed / 10).max(1);
    }
}

/// Update streak with forgiveness mechanism
fn update_streak(stats: &mut UserStats) {
    let now = Utc::now();

    if let Some(last_completion) = stats.last_completion_date {
        let days_since = (now - last_completion).num_days();

        match days_since {
            0 => {
                // Same day, continue streak
            }
            1 => {
                // Next day, increment streak
                stats.current_streak += 1;
                stats.streak_bonus_pool = (stats.streak_bonus_pool + 0.1).min(1.0); // Recover bonus pool

                if stats.current_streak > stats.longest_streak {
                    stats.longest_streak = stats.current_streak;
                }
            }
            2..=3 => {
                // 2-3 days gap: Gradual decay instead of reset
                stats.streak_bonus_pool *= 0.7;
                stats.current_streak = (stats.current_streak as f32 * 0.5) as i32;
            }
            _ => {
                // More than 3 days: Reset streak but keep some bonus pool
                stats.streak_bonus_pool *= 0.3;
                stats.current_streak = 0;
            }
        }
    } else {
        // First task ever
        stats.current_streak = 1;
    }

    stats.last_completion_date = Some(now);
}

/// Calculate focus score (0-100) based on recent task completion patterns
pub fn calculate_focus_score(tasks: &[Task]) -> f32 {
    if tasks.is_empty() {
        return 0.0;
    }

    let total_focus_ratio: f32 = tasks
        .iter()
        .filter_map(|task| {
            if let (Some(started), Some(completed)) = (task.started_at, task.completed_at) {
                let total_time = (completed - started).num_seconds();
                if total_time > 0 {
                    let active_time = total_time - task.total_pause_duration;
                    return Some(active_time as f32 / total_time as f32);
                }
            }
            None
        })
        .sum();

    let completed_count = tasks.iter().filter(|t| matches!(t.status, crate::models::TaskStatus::Completed)).count();

    if completed_count > 0 {
        (total_focus_ratio / completed_count as f32 * 100.0).min(100.0)
    } else {
        0.0
    }
}

/// Calculate efficiency score (0-100) based on time vs. expected time
pub fn calculate_efficiency_score(
    tasks: &[Task],
    avg_times: &[(i32, f64)], // (difficulty, avg_time)
) -> f32 {
    if tasks.is_empty() {
        return 0.0;
    }

    let efficiency_sum: f32 = tasks
        .iter()
        .filter_map(|task| {
            if let (Some(started), Some(completed)) = (task.started_at, task.completed_at) {
                let actual_time = (completed - started).num_seconds() as f64 - task.total_pause_duration as f64;

                if let Some(&(_, avg_time)) = avg_times.iter().find(|(diff, _)| *diff == task.difficulty) {
                    if actual_time > 0.0 {
                        // Better efficiency if actual < average
                        let efficiency = (avg_time / actual_time).min(2.0); // Cap at 2x
                        return Some(efficiency as f32);
                    }
                }
            }
            None
        })
        .sum();

    let completed_count = tasks.iter().filter(|t| matches!(t.status, crate::models::TaskStatus::Completed)).count();

    if completed_count > 0 {
        ((efficiency_sum / completed_count as f32) * 50.0).min(100.0)
    } else {
        0.0
    }
}
