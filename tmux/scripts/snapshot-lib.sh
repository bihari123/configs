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
