#!/usr/bin/env bash
# Remove tmux-continuum's save interpolation from the status line.
#
# continuum.tmux's add_resurrect_save_interpolation() unconditionally prepends
# #(.../continuum_save.sh) to status-right, which is how saves used to be
# triggered. Saves are now driven by tmux-save.timer, so this both removes a
# fork on every status redraw and eliminates the load-order fragility where a
# plugin that overwrites status-right could silently disable saving forever.

set -uo pipefail

marker="continuum_save.sh"

for opt in status-right status-left; do
	value="$(tmux show-options -gv "$opt" 2>/dev/null)" || continue
	case "$value" in
		*"$marker"*) ;;
		*) continue ;;
	esac
	# Strip "#(<anything>continuum_save.sh)" wherever it appears.
	cleaned="$(printf '%s' "$value" | sed 's|#([^)]*continuum_save\.sh)||g')"
	tmux set-option -g "$opt" "$cleaned"
done
