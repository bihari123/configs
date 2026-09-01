#!/usr/bin/env bash
# Shared helpers for validated, atomic tmux-resurrect snapshots.
#
# Sourced by resurrect-save.sh, resurrect-restore.sh and snapshot-doctor.sh.
# Nothing here calls tmux-resurrect directly; it only inspects and moves files.

RESURRECT_DIR="${RESURRECT_DIR:-$HOME/.local/share/tmux/resurrect}"
LAST_LINK="$RESURRECT_DIR/last"
ARCHIVE_FILE="$RESURRECT_DIR/pane_contents.tar.gz"
ARCHIVE_BACKUP="$RESURRECT_DIR/.pane_contents.prev.tar.gz"
LOCK_FILE="$RESURRECT_DIR/.save.lock"
LOG_TAG="tmux-snapshot"
# Retention. Upstream save.sh has a cleanup (remove_old_backups: everything past
# the newest 5, older than @resurrect-delete-backup-after, default 30 days) but
# it is purely age-based, so a busy fortnight piles up unboundedly - 84 files by
# 2026-09-01, none yet old enough for upstream to touch.
#
# The policy here is per-session instead of per-file: keep the newest snapshot
# containing each session name, and let a session go once its newest snapshot is
# older than SNAPSHOT_MAX_AGE_DAYS. That keeps every session you actually use
# restorable at its latest state, while one-off sessions age out instead of
# pinning a file forever.
SNAPSHOT_MAX_AGE_DAYS="${SNAPSHOT_MAX_AGE_DAYS:-30}"

# Log to the journal when available, always echo to stderr so interactive runs
# and `journalctl --user -t tmux-snapshot` both work.
log() {
	local msg="$*"
	echo "$LOG_TAG: $msg" >&2
	if command -v systemd-cat >/dev/null 2>&1; then
		echo "$msg" | systemd-cat -t "$LOG_TAG" 2>/dev/null || true
	fi
}

# A snapshot must describe at least one pane and one window, and every line
# must be a known record type. Field counts use minimums rather than exact
# matches so a future resurrect format that adds columns does not break saves;
# they still catch the truncation case, which is what actually corrupts files.
#
# Usage: validate_snapshot <file>  -> 0 = good, 1 = bad (reason on stdout)
validate_snapshot() {
	local file="$1"

	if [ -z "$file" ]; then
		echo "no path given"; return 1
	fi
	if [ ! -e "$file" ]; then
		echo "missing"; return 1
	fi
	# Resolve through the `last` symlink; a dangling link is a hard fail.
	local real
	real="$(readlink -f "$file" 2>/dev/null)"
	if [ -z "$real" ] || [ ! -f "$real" ]; then
		echo "dangling symlink or not a regular file"; return 1
	fi
	if [ ! -s "$real" ]; then
		echo "empty (0 bytes)"; return 1
	fi

	local panes windows bad
	panes=$(awk -F'\t' '$1=="pane"   && NF>=8 {n++} END{print n+0}' "$real")
	windows=$(awk -F'\t' '$1=="window" && NF>=6 {n++} END{print n+0}' "$real")
	bad=$(awk -F'\t' '
		$1!="pane" && $1!="window" && $1!="state" && $1!="grouped_session" {n++}
		END{print n+0}' "$real")

	if [ "$bad" -gt 0 ]; then
		echo "$bad line(s) with unknown record type"; return 1
	fi
	if [ "$panes" -eq 0 ]; then
		echo "no valid pane records"; return 1
	fi
	if [ "$windows" -eq 0 ]; then
		echo "no valid window records"; return 1
	fi

	echo "ok (${panes} panes, ${windows} windows)"
	return 0
}

# Pane-contents tarball: must decompress and contain at least one member.
# Usage: validate_archive <file> -> 0 = good, 1 = bad (reason on stdout)
validate_archive() {
	local file="$1"

	if [ ! -f "$file" ]; then
		echo "missing"; return 1
	fi
	if ! gzip -t "$file" 2>/dev/null; then
		echo "failed gzip integrity check"; return 1
	fi
	local members
	members=$(gzip -dc "$file" 2>/dev/null | tar tf - 2>/dev/null | grep -c 'pane_contents/.' || true)
	if [ "${members:-0}" -eq 0 ]; then
		echo "no pane_contents members"; return 1
	fi

	echo "ok (${members} panes)"
	return 0
}

# Atomically repoint `last` at a file in the same directory.
# ln -sfn on an existing symlink is not atomic; create a temp link and
# rename(2) it over the target instead.
promote_last() {
	local basename="$1"
	local tmplink="$RESURRECT_DIR/.last.$$"
	ln -sfn "$basename" "$tmplink" || return 1
	mv -T "$tmplink" "$LAST_LINK" || { rm -f "$tmplink"; return 1; }
}

# Retention pass: keep the newest snapshot holding each still-current session.
#
# Walking newest-first, the first file to mention a session name is by
# definition that session's latest state, so it is pinned. A session whose
# latest state is already older than the age cap is treated as gone and pins
# nothing - that is what stops one-off sessions from holding a file forever.
#
# The file `last` points at is never deleted, whatever its age: it is the one
# snapshot a restore still depends on. Ordering is by mtime, which matches the
# filename timestamp and copes with a clock that moved backwards better than a
# lexical sort would.
#
# Usage: prune_snapshots [max_age_days]  -> prints the number removed
prune_snapshots() {
	local max_age="${1:-$SNAPSHOT_MAX_AGE_DAYS}"

	case "$max_age" in
		'' | *[!0-9]*)
			log "prune skipped: non-numeric age cap '$max_age'"
			echo 0; return 1 ;;
	esac
	if [ "$max_age" -lt 1 ]; then
		log "prune skipped: age cap must be at least 1 day"
		echo 0; return 1
	fi

	local current cutoff removed=0
	current="$(basename "$(readlink -f "$LAST_LINK" 2>/dev/null || true)" 2>/dev/null || true)"
	cutoff=$(( $(date +%s) - max_age * 86400 ))

	# Associative arrays rather than a delimited string: session names may
	# contain almost anything, including whatever separator we would pick.
	local -A seen=() keepers=()
	local f base mtime session pins

	while IFS= read -r f; do
		[ -n "$f" ] || continue
		base="$(basename "$f")"
		mtime="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
		pins=0
		while IFS= read -r session; do
			[ -n "$session" ] || continue
			if [ -z "${seen[$session]:-}" ]; then
				seen[$session]=1
				# First sighting = this session's latest state. It only
				# earns its file a reprieve if it is still recent.
				[ "$mtime" -ge "$cutoff" ] && pins=1
			fi
		done < <(awk -F'\t' '$1=="pane" && $2!="" && !x[$2]++ { print $2 }' "$f")
		[ "$pins" -eq 1 ] && keepers[$base]=1
	done < <(ls -1t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null)

	while IFS= read -r f; do
		[ -n "$f" ] || continue
		base="$(basename "$f")"
		[ "$base" = "$current" ] && continue
		[ -n "${keepers[$base]:-}" ] && continue
		rm -f "$f" && removed=$((removed + 1))
	done < <(ls -1t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null)

	echo "$removed"
	return 0
}

# Session names recorded in a snapshot, comma-separated, in file order so the
# first one is the first session resurrect will recreate.
#
# Field 2 of every pane/window record is the session name; validate_snapshot
# only ever counts records and never looks here, which is why the welcome
# picker used to be able to show timestamps but not names.
#
# Usage: snapshot_sessions <file>  -> "work,notes,0"
snapshot_sessions() {
	local real
	real="$(readlink -f "$1" 2>/dev/null)" || return 1
	[ -n "$real" ] && [ -f "$real" ] || return 1
	awk -F'\t' '$1=="pane" && $2!="" && !seen[$2]++ { printf "%s%s", (n++ ? "," : ""), $2 }' "$real"
}

# The session that was active when the snapshot was taken, from the `state`
# record. Empty for any save made while no client was attached - see
# record-active-session.sh, which backfills it.
#
# Usage: snapshot_active_session <file>
snapshot_active_session() {
	local real
	real="$(readlink -f "$1" 2>/dev/null)" || return 1
	[ -n "$real" ] && [ -f "$real" ] || return 1
	awk -F'\t' '$1=="state" { print $2; exit }' "$real"
}
