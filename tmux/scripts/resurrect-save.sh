#!/usr/bin/env bash
# Validating wrapper around tmux-resurrect's save.sh.
#
# Wired in via `set -g @resurrect-save-script-path` so tmux-continuum, the
# tmux.service ExecStop and tmux-save.timer all route through here.
#
# Note on approach: tmux-resurrect cannot be redirected to a staging directory.
# helpers.sh:11 does `_RESURRECT_DIR=""` unconditionally at source time, which
# wipes any inherited value before resurrect_dir() (helpers.sh:99) ever reads
# it, so the environment-variable seam does not exist. Instead we let save.sh
# write where it normally does, then validate what it produced and roll `last`
# back to the previous good snapshot if it is bad.
#
# Guarantees:
#   - never runs when no tmux server is alive (the case that wrote a 0-byte
#     snapshot on 2026-08-18 and poisoned every subsequent boot)
#   - `last` never comes to rest pointing at an invalid snapshot
#   - a rejected save also restores the previous pane-contents tarball, so the
#     snapshot and the tarball stay in sync
#   - only one save runs at a time
#   - snapshots are pruned to the newest per session, never touching `last`

set -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/snapshot-lib.sh"

# Overridable so the rollback path can be exercised with a stub in tests.
REAL_SAVE="${TMUX_RESURRECT_SAVE:-$HOME/.config/tmux/plugins/tmux-resurrect/scripts/save.sh}"

# Undo a bad save: drop the file resurrect just wrote, put `last` back where it
# was, and restore the tarball we backed up beforehand.
rollback() {
	local bad="$1" prev="$2"

	if [ -n "$bad" ] && [ -f "$bad" ]; then
		rm -f "$bad"
	fi
	if [ -n "$prev" ] && [ -e "$RESURRECT_DIR/$prev" ]; then
		promote_last "$prev" || log "rollback warning: could not repoint last -> $prev"
	fi
	if [ -f "$ARCHIVE_BACKUP" ]; then
		mv -T "$ARCHIVE_BACKUP" "$ARCHIVE_FILE" 2>/dev/null ||
			log "rollback warning: could not restore previous pane contents archive"
	fi
}

run_save() {
	local prev_target prev_snap new_target new_snap reason snap_report
	local want_contents archive_report="not captured"

	# The critical guard. With no server every resurrect dump returns nothing,
	# and the old code promoted the resulting empty file to `last` regardless.
	if ! tmux has-session 2>/dev/null; then
		log "save skipped: no tmux server running (last left untouched)"
		return 0
	fi

	# Only the primary server may write. The snapshot dir and `last` are shared
	# across every socket, so a throwaway server (tmux -L something) inherits
	# this config, fires the client-detached hook on exit, and overwrites the
	# real session state with its own. That is not hypothetical: it clobbered
	# `last` and the pane-contents tarball on 2026-09-01. $TMUX is only set when
	# we are invoked from inside a server (the hook); the timer and the systemd
	# units run outside one and are unaffected.
	if [ -n "${TMUX:-}" ]; then
		local socket="${TMUX%%,*}"
		case "$socket" in
			*/default) ;;
			*)
				log "save skipped: non-default socket ($socket)"
				return 0 ;;
		esac
	fi

	prev_target="$(readlink "$LAST_LINK" 2>/dev/null || true)"
	prev_snap="$(readlink -f "$LAST_LINK" 2>/dev/null || true)"

	# Keep a copy of the tarball so a rejected save can put it back.
	want_contents="$(tmux show-option -gqv @resurrect-capture-pane-contents)"
	rm -f "$ARCHIVE_BACKUP"
	if [ "$want_contents" = "on" ] && [ -f "$ARCHIVE_FILE" ]; then
		cp -f "$ARCHIVE_FILE" "$ARCHIVE_BACKUP" 2>/dev/null || true
	fi

	if ! "$REAL_SAVE" quiet >/dev/null 2>&1; then
		log "save failed: resurrect save.sh exited non-zero"
		rollback "" "$prev_target"
		return 1
	fi

	new_target="$(readlink "$LAST_LINK" 2>/dev/null || true)"
	new_snap="$(readlink -f "$LAST_LINK" 2>/dev/null || true)"

	# save_all() deletes its output and leaves `last` alone when the new dump is
	# byte-identical to the previous one. Nothing changed, so nothing to check.
	if [ -n "$prev_target" ] && [ "$new_target" = "$prev_target" ]; then
		# The layout is unchanged, but save.sh still recaptured the pane
		# contents and the post-save-all trim hook still rewrote the archive,
		# so it needs checking here too. Every other exit path validates it;
		# without this the one path that discards the backup is also the one
		# that never looks at what it is discarding.
		if [ "$want_contents" = "on" ]; then
			reason="$(validate_archive "$ARCHIVE_FILE")"
			if [ $? -ne 0 ]; then
				log "save: no change since $prev_target, but pane contents archive invalid - $reason (restoring previous archive)"
				if [ -f "$ARCHIVE_BACKUP" ]; then
					mv -T "$ARCHIVE_BACKUP" "$ARCHIVE_FILE" 2>/dev/null ||
						log "warning: could not restore previous pane contents archive"
				fi
				return 1
			fi
		fi
		rm -f "$ARCHIVE_BACKUP"
		log "save: no change since $prev_target"
		return 0
	fi

	reason="$(validate_snapshot "$LAST_LINK")"
	if [ $? -ne 0 ]; then
		log "save REJECTED: $new_target invalid - $reason (rolled back to ${prev_target:-nothing})"
		rollback "$new_snap" "$prev_target"
		return 1
	fi
	snap_report="$reason"

	if [ "$want_contents" = "on" ]; then
		reason="$(validate_archive "$ARCHIVE_FILE")"
		if [ $? -ne 0 ]; then
			log "save REJECTED: pane contents archive invalid - $reason (rolled back to ${prev_target:-nothing})"
			rollback "$new_snap" "$prev_target"
			return 1
		fi
		archive_report="$reason"
	fi

	rm -f "$ARCHIVE_BACKUP"
	log "saved $new_target - snapshot $snap_report, contents $archive_report"

	# Only prune once a new snapshot is safely in place, so a run that ends in
	# rollback never also thins the history it might have to roll back into.
	local pruned
	pruned="$(prune_snapshots)"
	if [ "${pruned:-0}" -gt 0 ]; then
		log "pruned $pruned snapshot(s) superseded per session (age cap ${SNAPSHOT_MAX_AGE_DAYS}d)"
	fi
	return 0
}

main() {
	if [ ! -x "$REAL_SAVE" ]; then
		log "save aborted: $REAL_SAVE not found or not executable"
		return 1
	fi
	mkdir -p "$RESURRECT_DIR" || return 1

	# Serialise saves. Two concurrent runs would race over `last` and over the
	# single pane_contents.tar.gz.
	exec 9>"$LOCK_FILE"
	if ! flock -w 30 9; then
		log "save skipped: another save holds the lock"
		return 0
	fi

	run_save
}

main "$@"
