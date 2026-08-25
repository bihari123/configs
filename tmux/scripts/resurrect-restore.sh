#!/usr/bin/env bash
# Validating wrapper around tmux-resurrect's restore.sh.
#
# Wired in via `set -g @resurrect-restore-script-path` so tmux-continuum's
# auto-restore and the prefix+Ctrl-r binding both route through here.
#
# The bug this exists to prevent: restore.sh's only guard,
# check_saved_session_exists() (restore.sh:30-36), tests for file *existence*
# only. A 0-byte `last` passed it, nothing got restored, and handle_session_0()
# (restore.sh:277-285) then ran `kill-session -t 0` — destroying the only
# session and taking the server down with it.
#
# Here an unusable snapshot means we simply never invoke restore.sh.

set -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/snapshot-lib.sh"

REAL_RESTORE="$HOME/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh"

notify() {
	tmux display-message "$1" 2>/dev/null || true
}

main() {
	if [ ! -x "$REAL_RESTORE" ]; then
		log "restore aborted: $REAL_RESTORE not found or not executable"
		return 0
	fi

	local reason
	reason="$(validate_snapshot "$LAST_LINK")"
	if [ $? -ne 0 ]; then
		log "restore SKIPPED: invalid snapshot - $reason (existing sessions left intact)"
		notify "tmux-resurrect: snapshot invalid ($reason) - restore skipped"
		# Exit 0 on purpose: a bad snapshot is a no-op, not a service failure.
		return 0
	fi

	# Pane contents are optional. A broken tarball must not block the restore of
	# layout, cwd and processes, so warn and carry on rather than bailing.
	if [ "$(tmux show-option -gqv @resurrect-capture-pane-contents)" = "on" ]; then
		local arc
		arc="$(validate_archive "$ARCHIVE_FILE")"
		if [ $? -ne 0 ]; then
			log "restore warning: pane contents archive unusable - $arc (restoring layout only)"
		fi
	fi

	log "restoring from $(basename "$(readlink -f "$LAST_LINK")") - $reason"
	"$REAL_RESTORE"
	local rc=$?
	if [ $rc -ne 0 ]; then
		log "restore: resurrect restore.sh exited $rc"
	else
		log "restore complete"
	fi
	return 0
}

main "$@"
