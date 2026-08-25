#!/usr/bin/env bash
# tmux "welcome screen": a picker shown INSIDE tmux at startup, mirroring
# zellij's session-manager. Attach to a live session, start a fresh one, or
# resurrect a saved snapshot (latest, or a chosen point-in-time).
#
# Two modes in one file:
#   (outer, no args)  Run from bash when NOT in tmux. Drops you into a throwaway
#                     `__welcome__` tmux session whose only pane runs this script
#                     again with --inside. So the menu appears *within* tmux.
#   --inside          Runs as that pane's program (inside tmux). Shows the fzf
#                     menu and acts via tmux client commands, then removes the
#                     scratch session so it never lingers.
#
# Why a scratch session: tmux-resurrect restores the WHOLE server into one
# timestamped snapshot (no per-session revival like zellij). Restoring needs a
# live server to recreate sessions into - the scratch session IS that server,
# and it is thrown away once you land on a real session.
#
# Every restore still routes through resurrect-restore.sh, so its validation and
# rollback guarantees are untouched. Esc / no selection is always a safe no-op.

set -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/snapshot-lib.sh"

RESTORE_WRAPPER="$CURRENT_DIR/resurrect-restore.sh"
WELCOME="__welcome__"

command -v tmux >/dev/null 2>&1 || exit 0

# ---------------------------------------------------------------------------
# OUTER: called from bash. Enter tmux and run the picker inside a scratch
# session, then tidy that session up when the client detaches/exits.
# ---------------------------------------------------------------------------
if [ "${1:-}" != "--inside" ]; then
	# Already inside tmux, or no fzf: get out of the way.
	[ -n "${TMUX:-}" ] && exit 0
	if ! command -v fzf >/dev/null 2>&1; then
		tmux attach 2>/dev/null || tmux new-session
		exit 0
	fi
	# -A: attach if the scratch session somehow still exists, else create it
	# running this script in --inside mode as the pane program.
	tmux new-session -A -s "$WELCOME" "$0 --inside"
	# Back in bash (client detached or tmux exited): drop the scratch session
	# if it lingered. Only ever touches our own throwaway session.
	tmux kill-session -t "$WELCOME" 2>/dev/null || true
	exit 0
fi

# ---------------------------------------------------------------------------
# INSIDE: running as the scratch session's pane program ($TMUX is set).
# ---------------------------------------------------------------------------

# Human-readable time for tmux_resurrect_YYYYMMDDTHHMMSS.txt
snap_time() {
	local base ts
	base="$(basename "$1")"
	ts="${base#tmux_resurrect_}"; ts="${ts%.txt}"
	if [[ "$ts" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2}) ]]; then
		printf '%s-%s-%s %s:%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" \
			"${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}"
	else
		printf '%s' "$ts"
	fi
}

# Land on a real session and discard the scratch one. Runs after a restore or a
# "new" choice has created the target session.
land_on() {
	local target="$1"
	tmux switch-client -t "$target" || return 1
	# Killing the scratch session destroys this very pane, so it must be last.
	tmux kill-session -t "$WELCOME" 2>/dev/null || true
}

# Restore whatever `last` points at (already repointed by the caller for a
# picked snapshot), then jump to a restored session.
do_restore() {
	"$RESTORE_WRAPPER"
	local target
	target="$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -vx "$WELCOME" | head -1)"
	if [ -n "$target" ]; then
		land_on "$target"
	else
		tmux display-message "resurrect: nothing restored - back to menu"
		sleep 1
		exec "$0" --inside
	fi
}

# fzf over every timestamped snapshot, newest first, then restore the choice.
restore_pick() {
	local files=() base choice menu=""
	mapfile -t files < <(find "$RESURRECT_DIR" -maxdepth 1 -name 'tmux_resurrect_*.txt' \
		-printf '%f\n' 2>/dev/null | sort -r)
	if [ "${#files[@]}" -eq 0 ]; then
		tmux display-message "no snapshots in $RESURRECT_DIR"; sleep 1
		exec "$0" --inside
	fi
	for base in "${files[@]}"; do
		local bytes reason
		bytes=$(stat -c '%s' "$RESURRECT_DIR/$base" 2>/dev/null || echo 0)
		if reason="$(validate_snapshot "$RESURRECT_DIR/$base" 2>/dev/null)"; then :; else
			reason="INVALID: $reason"
		fi
		menu+="$(printf '%s\t%s\t%sB\t%s' "$base" "$(snap_time "$base")" "$bytes" "$reason")"$'\n'
	done
	choice="$(printf '%s' "$menu" | column -t -s $'\t' |
		fzf --prompt='snapshot > ' --height='100%' --reverse \
		    --header='Pick a point-in-time to restore (Esc to go back)')" || exec "$0" --inside
	[ -n "$choice" ] || exec "$0" --inside
	base="${choice%% *}"
	[ -n "$base" ] || exec "$0" --inside
	promote_last "$base" || { tmux display-message "could not select $base"; sleep 1; exec "$0" --inside; }
	do_restore
}

# Create (or, if it already exists, jump to) a session with the given name.
create_named() {
	local name="$1"
	if tmux has-session -t "=$name" 2>/dev/null; then
		land_on "$name"                       # name taken -> just go there
	else
		tmux new-session -d -s "$name" && land_on "$name"
	fi
}

# Ask for a session name in the pane, then create it. Blank -> auto-named.
prompt_new() {
	local name
	printf '\n  New session name (blank = auto-named): '
	IFS= read -r name || true
	name="${name#"${name%%[![:space:]]*}"}"    # trim leading whitespace
	name="${name%"${name##*[![:space:]]}"}"    # trim trailing whitespace
	name="${name//[:. ]/-}"                    # tmux dislikes : . and spaces
	if [ -n "$name" ]; then
		create_named "$name"
	else
		local n; n="$(tmux new-session -dP -F '#{session_name}')"
		land_on "$n"
	fi
}

main() {
	local live=() opts=() latest_label="" s
	mapfile -t live < <(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -vx "$WELCOME")

	for s in "${live[@]}"; do opts+=("attach: $s"); done
	opts+=("new: create a session (asks for a name)…")
	if [ -e "$LAST_LINK" ] && validate_snapshot "$LAST_LINK" >/dev/null 2>&1; then
		latest_label="restore: latest snapshot ($(snap_time "$(readlink -f "$LAST_LINK")"))"
		opts+=("$latest_label")
	fi
	opts+=("restore: pick a snapshot…")
	opts+=("shell: leave tmux, plain shell")

	# --print-query: line 1 is whatever was typed, line 2 (if any) is the chosen
	# row. Typing a name that matches no row and pressing Enter creates a session
	# by that name (fzf exits non-zero then, so we must NOT treat that as cancel).
	local out query pick rc
	out="$(printf '%s\n' "${opts[@]}" | fzf --print-query --height='100%' --reverse \
		--prompt='tmux > ' \
		--header='Enter a row to use it, or TYPE A NAME + Enter to create that session (Esc = leave)')"
	rc=$?
	[ "$rc" -eq 130 ] && { tmux detach-client; exit 0; }   # Esc / Ctrl-C
	query="$(sed -n '1p' <<<"$out")"
	pick="$(sed -n '2p' <<<"$out")"

	# No row chosen: create a named session if something was typed, else leave.
	if [ -z "$pick" ]; then
		if [ -n "$query" ]; then create_named "$query"; return; fi
		tmux detach-client; exit 0
	fi

	case "$pick" in
		attach:\ *)        land_on "${pick#attach: }" ;;
		new:*)             prompt_new ;;
		"$latest_label")   do_restore ;;
		restore:\ latest*) do_restore ;;
		restore:\ pick*)   restore_pick ;;
		shell:*)           tmux detach-client ;;
		*)                 tmux detach-client ;;
	esac
}

main "$@"
