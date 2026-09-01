#!/usr/bin/env bash
# Backfill the `state` record of a freshly written snapshot.
#
# Wired in via `set -g @resurrect-hook-post-save-layout`, which save.sh calls
# with the snapshot path after dump_state and before it relinks `last`, so the
# file can still be corrected in place.
#
# The problem: dump_state (save.sh:217) is `tmux display-message -p` over
# #{client_session}. That needs an attached client. Every save made against a
# detached server - the 15-minute timer, the shutdown save - therefore writes
# `state<TAB><TAB>`, and restore_state (restore.sh:208) has nothing to switch
# to. 12 of 84 snapshots here were empty that way.
#
# The fix: when no client is attached, fall back to the most recently used
# session. session_last_attached is the honest answer but is empty for sessions
# that were never attached, so session_activity backs it up.
#
# Only ever fills in a blank; a state written by a real attached client wins.

set -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/snapshot-lib.sh"

snapshot="${1:-}"

main() {
	[ -n "$snapshot" ] && [ -f "$snapshot" ] || return 0
	tmux has-session 2>/dev/null || return 0

	local current
	current="$(awk -F'\t' '$1=="state" { print $2; exit }' "$snapshot")"
	if [ -n "$current" ]; then
		return 0            # a real client already answered this
	fi

	# Most recently used session wins. Sessions the snapshot does not contain
	# are excluded, so we never point restore at something it will not create.
	#
	# The fields are pipe-delimited and normalised in awk rather than split on
	# whitespace: session_last_attached is EMPTY for a session that has never
	# been attached, which silently shifts every field left and yields an empty
	# name. awk also folds the two timestamps into one key, so a never-attached
	# but recently active session still sorts sensibly. Reading the name as the
	# final field keeps it intact even if it contains a pipe; a tab is safe as
	# the output separator because the snapshot format is itself tab-delimited,
	# so a session name containing one could never round-trip anyway.
	local recorded want
	recorded="$(snapshot_sessions "$snapshot")"
	want="$(tmux list-sessions -F '#{session_last_attached}|#{session_activity}|#{session_name}' 2>/dev/null |
		awk -F'|' '{
			la = ($1 == "" ? 0 : $1)
			ac = ($2 == "" ? 0 : $2)
			key = (la > ac ? la : ac)
			name = $3
			for (i = 4; i <= NF; i++) name = name "|" $i
			if (name != "") print key "\t" name
		}' |
		sort -t"$(printf '\t')" -k1,1nr |
		cut -f2- |
		while IFS= read -r name; do
			case ",$recorded," in
				*",$name,"*) echo "$name"; break ;;
			esac
		done)"

	[ -n "$want" ] || return 0

	# Rewrite in place via a temp file in the same dir, then rename(2) over the
	# original: a half-written snapshot here would be indistinguishable from the
	# truncation validate_snapshot exists to catch.
	local tmp="$snapshot.state.$$"
	if awk -F'\t' -v OFS='\t' -v s="$want" \
		'$1=="state" { $2 = s; print; next } { print }' "$snapshot" > "$tmp" 2>/dev/null &&
		[ -s "$tmp" ]; then
		mv -T "$tmp" "$snapshot" 2>/dev/null ||
			{ rm -f "$tmp"; log "state backfill: could not replace $snapshot"; return 0; }
		log "state backfill: recorded active session '$want'"
	else
		rm -f "$tmp"
		log "state backfill: rewrite failed for $snapshot"
	fi
}

main "$@"
