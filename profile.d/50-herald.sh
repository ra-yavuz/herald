# shellcheck shell=sh
# Print today's herald quote at the top of every new interactive shell.
# This file is shipped non-executable; 'herald terminal on' chmods +x.
#
# Sourced by /etc/profile (login shells) and by ~/.bashrc on demand
# (the 'herald terminal on' command adds a source line to the invoking
# user's ~/.bashrc, since /etc/bash.bashrc on Ubuntu does NOT source
# /etc/profile.d/).

# Run only in interactive shells.
case $- in
    *i*) ;;
    *)   return 0 ;;
esac

# Don't run twice in nested shells.
[ -n "${HERALD_GREETED:-}" ] && return 0
HERALD_GREETED=1
export HERALD_GREETED

if command -v herald >/dev/null 2>&1; then
    herald render 2>/dev/null
fi
