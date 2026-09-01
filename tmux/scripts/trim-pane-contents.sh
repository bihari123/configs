#!/usr/bin/env bash
# Cap saved pane scrollback at PANE_CONTENTS_MAX_LINES lines per pane.
#
# Wired in via `set -g @resurrect-hook-post-save-all`, which save.sh calls once
# the pane-contents archive has been written - the only seam available, since
# there is no hook between dump_pane_contents and pane_contents_create_archive.
#
# Why this is needed at all: resurrect offers exactly two capture modes,
# "full" and "visible" (variables.sh:38), with no line limit. "full" means
# `capture-pane -S -#{history_size}`, and tmux-sensible raises history-limit to
# 50000, so a busy pane can dump 50k lines of escape-laden text on every save -
# every 15 minutes, plus every detach.
#
# The honest limitation: the expensive capture has already happened by the time
# this runs, so this bounds what is stored and restored, not what is captured.
# Fixing the capture itself would mean patching the plugin, and turning capture
# off is not an option - restore gates on the same @resurrect-capture-pane-
# contents flag (restore.sh:255), so it would stop restoring contents entirely.
#
# Trimming keeps the TAIL, which is the recent end of the scrollback and the
# part worth having back. A cut can land mid-escape-sequence and leave the first
# restored line with inherited colour; that is cosmetic and self-corrects.

set -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/snapshot-lib.sh"

MAX_LINES="${PANE_CONTENTS_MAX_LINES:-1000}"

main() {
	[ -f "$ARCHIVE_FILE" ] || return 0

	case "$MAX_LINES" in
		'' | *[!0-9]*) log "trim skipped: non-numeric line cap '$MAX_LINES'"; return 0 ;;
	esac
	[ "$MAX_LINES" -ge 1 ] || { log "trim skipped: line cap must be at least 1"; return 0; }

	local work
	work="$(mktemp -d "$RESURRECT_DIR/.trim.XXXXXX")" || return 0
	# shellcheck disable=SC2064
	trap "rm -rf '$work'" EXIT

	if ! gzip -dc "$ARCHIVE_FILE" 2>/dev/null | tar xf - -C "$work" 2>/dev/null; then
		log "trim skipped: could not unpack pane contents archive"
		return 0
	fi
	[ -d "$work/pane_contents" ] || return 0

	# Trim only what is actually over the cap, so the common case of small
	# panes costs one wc per file and no repack at all.
	local f lines trimmed=0 saved=0
	for f in "$work"/pane_contents/*; do
		[ -f "$f" ] || continue
		lines="$(wc -l < "$f" 2>/dev/null || echo 0)"
		if [ "$lines" -gt "$MAX_LINES" ]; then
			if tail -n "$MAX_LINES" "$f" > "$f.trim" 2>/dev/null; then
				mv -T "$f.trim" "$f" || { rm -f "$f.trim"; continue; }
				trimmed=$((trimmed + 1))
				saved=$((saved + lines - MAX_LINES))
			else
				rm -f "$f.trim"
			fi
		fi
	done

	if [ "$trimmed" -eq 0 ]; then
		return 0
	fi

	# Repack the same way pane_contents_create_archive does (helpers.sh:83),
	# then rename(2) over the original: a half-written archive here would fail
	# the very validation the save wrapper runs next.
	local tmp="$ARCHIVE_FILE.trim.$$"
	if (cd "$work" && tar cf - ./pane_contents/ 2>/dev/null | gzip > "$tmp") && [ -s "$tmp" ]; then
		mv -T "$tmp" "$ARCHIVE_FILE" 2>/dev/null ||
			{ rm -f "$tmp"; log "trim: could not replace archive"; return 0; }
		log "trimmed $trimmed pane(s) to $MAX_LINES lines ($saved lines dropped)"
	else
		rm -f "$tmp"
		log "trim: repack failed, archive left as-is"
	fi
}

main "$@"
