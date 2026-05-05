#!/usr/bin/env bash
# From-source installer for herald. Used when you don't want to add the
# apt source. For most users the apt repo is easier; see README.
set -euo pipefail

PREFIX=${PREFIX:-/usr}
ROOT=$(cd "$(dirname "$0")" && pwd)

log()  { printf '[install.sh] %s\n' "$*"; }
fail() { printf '[install.sh] ERROR: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "must be run as root (sudo bash $0)"

for f in bin/herald lib/herald/quotes.json profile.d/50-herald.sh update-motd.d/95-herald systemd/herald-refresh.service systemd/herald-refresh.timer; do
    [ -f "$ROOT/$f" ] || fail "expected '$f' is missing - run from the repo root"
done

cmd_install() {
    log "installing herald from $ROOT"
    install -d "$PREFIX/bin" "$PREFIX/share/herald" "$PREFIX/share/doc/herald" /etc/profile.d /etc/update-motd.d /lib/systemd/system /var/cache/herald
    install -m 0755 "$ROOT/bin/herald"                       "$PREFIX/bin/herald"
    install -m 0644 "$ROOT/lib/herald/quotes.json"           "$PREFIX/share/herald/quotes.json"
    install -m 0644 "$ROOT/profile.d/50-herald.sh"           /etc/profile.d/50-herald.sh
    install -m 0644 "$ROOT/update-motd.d/95-herald"          /etc/update-motd.d/95-herald
    install -m 0644 "$ROOT/systemd/herald-refresh.service"   /lib/systemd/system/herald-refresh.service
    install -m 0644 "$ROOT/systemd/herald-refresh.timer"     /lib/systemd/system/herald-refresh.timer
    if [ -f "$ROOT/README.md" ]; then install -m 0644 "$ROOT/README.md" "$PREFIX/share/doc/herald/README.md"; fi
    if [ -f "$ROOT/LICENSE"   ]; then install -m 0644 "$ROOT/LICENSE"   "$PREFIX/share/doc/herald/copyright"; fi
    if [ -d /run/systemd/system ]; then
        systemctl daemon-reload
        systemctl enable --now herald-refresh.timer || true
        systemctl start herald-refresh.service || true
    fi
    log "done. Run 'herald status' to see state, 'sudo herald all on' to enable."
}

cmd_uninstall() {
    log "uninstalling herald (state preserved unless --purge)"
    if [ -d /run/systemd/system ]; then
        systemctl stop    herald-refresh.timer 2>/dev/null || true
        systemctl disable herald-refresh.timer 2>/dev/null || true
    fi
    rm -f "$PREFIX/bin/herald"
    rm -rf "$PREFIX/share/herald"
    rm -f /etc/profile.d/50-herald.sh /etc/update-motd.d/95-herald
    rm -f /lib/systemd/system/herald-refresh.service /lib/systemd/system/herald-refresh.timer
    rm -rf "$PREFIX/share/doc/herald"
    systemctl daemon-reload 2>/dev/null || true
    log "done."
}

cmd_purge() {
    cmd_uninstall
    rm -rf /var/cache/herald
    rm -f /etc/herald.prefix /etc/herald.conf
    rm -rf /etc/systemd/system/herald-refresh.timer.d
}

case "${1:-install}" in
    install)   cmd_install ;;
    uninstall) cmd_uninstall ;;
    purge)     cmd_purge ;;
    -h|--help|help) echo "Usage: sudo bash $0 [install|uninstall|purge]" ;;
    *)         fail "unknown subcommand: $1" ;;
esac
