#!/usr/bin/env bash
# Inspect and repair tmux-resurrect snapshots.
#
#   snapshot-doctor.sh              report on `last` and every stored snapshot
#   snapshot-doctor.sh --rollback   repoint `last` at the newest valid snapshot

set -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/snapshot-lib.sh"

report() {
	local reason target
	echo "resurrect dir: $RESURRECT_DIR"
	echo

	target="$(readlink "$LAST_LINK" 2>/dev/null)"
	reason="$(validate_snapshot "$LAST_LINK")"
	if [ $? -eq 0 ]; then
		echo "last -> ${target:-<not a symlink>}"
		echo "  status: VALID - $reason"
	else
		echo "last -> ${target:-<missing>}"
		echo "  status: INVALID - $reason"
		echo "  fix:    $0 --rollback"
	fi
	echo

	echo "stored snapshots (newest first):"
	local f base reason rc
	local total=0 good=0 bad=0
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		total=$((total + 1))
		base="$(basename "$f")"
		reason="$(validate_snapshot "$f")"; rc=$?
		if [ $rc -eq 0 ]; then
			good=$((good + 1))
			printf '  VALID    %s  %s\n' "$base" "$reason"
		else
			bad=$((bad + 1))
			printf '  INVALID  %s  %s\n' "$base" "$reason"
		fi
	done < <(ls -1t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null)
	echo
	echo "  $total snapshot(s): $good valid, $bad invalid"
	echo

	reason="$(validate_archive "$ARCHIVE_FILE")"
	if [ $? -eq 0 ]; then
		echo "pane contents archive: VALID - $reason"
	else
		echo "pane contents archive: INVALID - $reason"
	fi
}

rollback() {
	local f base reason
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		reason="$(validate_snapshot "$f")"
		if [ $? -eq 0 ]; then
			base="$(basename "$f")"
			if promote_last "$base"; then
				echo "last -> $base ($reason)"
				log "rollback: last -> $base"
				return 0
			fi
			echo "error: failed to repoint last -> $base" >&2
			return 1
		fi
	done < <(ls -1t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null)

	echo "error: no valid snapshot found to roll back to" >&2
	return 1
}

case "${1:-}" in
	--rollback) rollback ;;
	""|--report) report ;;
	*) echo "usage: $(basename "$0") [--report|--rollback]" >&2; exit 2 ;;
esac
