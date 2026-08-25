#!/usr/bin/env bash
# Kill tmux sessions that have been idle longer than a threshold.
# Idle = now - #{session_activity} (epoch of last activity in that session).
#
# Safety rules:
#   - never kills a session that currently has a client attached
#   - dry-run by default via DRY_RUN=1 (prints what it would do, kills nothing)
#
# Env:
#   IDLE_DAYS   idle threshold in days (default 7)
#   DRY_RUN     if "1", only report; do not kill

set -euo pipefail

IDLE_DAYS="${IDLE_DAYS:-7}"
DRY_RUN="${DRY_RUN:-0}"
threshold=$(( IDLE_DAYS * 86400 ))
now=$(date +%s)

# No server running => nothing to do (exit clean so the timer stays green).
if ! tmux has-session 2>/dev/null; then
	echo "prune: no tmux server running; nothing to do"
	exit 0
fi

# Fields: activity-epoch <TAB> attached-count <TAB> name
tmux list-sessions -F '#{session_activity}	#{session_attached}	#{session_name}' \
| while IFS=$'\t' read -r activity attached name; do
	idle=$(( now - activity ))
	if (( attached > 0 )); then
		echo "prune: keep '$name' (attached, idle ${idle}s)"
		continue
	fi
	if (( idle > threshold )); then
		if [[ "$DRY_RUN" == "1" ]]; then
			echo "prune: WOULD kill '$name' (idle ${idle}s > ${threshold}s)"
		else
			echo "prune: killing '$name' (idle ${idle}s > ${threshold}s)"
			tmux kill-session -t "$name"
		fi
	else
		echo "prune: keep '$name' (idle ${idle}s <= ${threshold}s)"
	fi
done
