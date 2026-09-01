#!/usr/bin/env bash
# Inspect and repair tmux-resurrect snapshots.
#
#   snapshot-doctor.sh              report on `last` and every stored snapshot
#   snapshot-doctor.sh --rollback   repoint `last` at the newest valid snapshot
#   snapshot-doctor.sh --prune [d]  keep the newest snapshot per session, drop
#                                   sessions unseen for d days (default
#                                   SNAPSHOT_MAX_AGE_DAYS), never removing `last`

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
	# Same walk prune_snapshots does, but reporting instead of deleting.
	local cutoff live=0 stale=0 keep=0
	cutoff=$(( $(date +%s) - SNAPSHOT_MAX_AGE_DAYS * 86400 ))
	local -A seen=() keepers=()
	local sess mt bn
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		bn="$(basename "$f")"
		mt="$(stat -c %Y "$f" 2>/dev/null || echo 0)"
		while IFS= read -r sess; do
			[ -n "$sess" ] || continue
			if [ -z "${seen[$sess]:-}" ]; then
				seen[$sess]=1
				if [ "$mt" -ge "$cutoff" ]; then
					live=$((live + 1)); keepers[$bn]=1
				else
					stale=$((stale + 1))
				fi
			fi
		done < <(awk -F'\t' '$1=="pane" && $2!="" && !x[$2]++ { print $2 }' "$f")
	done < <(ls -1t "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null)
	keep=${#keepers[@]}
	echo "  sessions: $live current, $stale older than ${SNAPSHOT_MAX_AGE_DAYS}d"
	if [ "$total" -gt "$keep" ]; then
		echo "  retention: $keep file(s) pinned, $((total - keep)) superseded - run $0 --prune"
	else
		echo "  retention: nothing superseded"
	fi
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

prune() {
	local removed
	removed="$(prune_snapshots "${1:-$SNAPSHOT_MAX_AGE_DAYS}")" || return 1
	echo "pruned $removed snapshot(s); kept the newest per session seen within ${1:-$SNAPSHOT_MAX_AGE_DAYS} days, plus whatever last points at"
}

case "${1:-}" in
	--rollback) rollback ;;
	--prune) prune "${2:-}" ;;
	""|--report) report ;;
	*) echo "usage: $(basename "$0") [--report|--rollback|--prune [n]]" >&2; exit 2 ;;
esac
