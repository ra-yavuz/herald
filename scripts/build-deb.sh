#!/usr/bin/env bash
# Build herald.deb without debhelper. Mirrors inhibit-charge's portable
# build-deb pattern.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION=$(sed -nE '1 s/^[^(]*\(([^)]+)\).*/\1/p' "$ROOT/debian/changelog")
[ -n "$VERSION" ] || { echo "could not parse version" >&2; exit 1; }

PKG_DIR="$ROOT/dist/herald_${VERSION}_all"
DEB_OUT="$ROOT/dist/herald_${VERSION}_all.deb"

rm -rf "$PKG_DIR" "$DEB_OUT"
mkdir -p "$PKG_DIR/DEBIAN" \
         "$PKG_DIR/usr/bin" \
         "$PKG_DIR/usr/share/herald" \
         "$PKG_DIR/usr/share/doc/herald" \
         "$PKG_DIR/etc/profile.d" \
         "$PKG_DIR/etc/update-motd.d" \
         "$PKG_DIR/lib/systemd/system"

install -m 0755 "$ROOT/bin/herald"                          "$PKG_DIR/usr/bin/herald"
install -m 0644 "$ROOT/lib/herald/quotes.json"              "$PKG_DIR/usr/share/herald/quotes.json"
# Greeting + MOTD shipped non-executable so they're disabled by default.
install -m 0644 "$ROOT/profile.d/50-herald.sh"              "$PKG_DIR/etc/profile.d/50-herald.sh"
install -m 0644 "$ROOT/update-motd.d/95-herald"             "$PKG_DIR/etc/update-motd.d/95-herald"
install -m 0644 "$ROOT/systemd/herald-refresh.service"      "$PKG_DIR/lib/systemd/system/herald-refresh.service"
install -m 0644 "$ROOT/systemd/herald-refresh.timer"        "$PKG_DIR/lib/systemd/system/herald-refresh.timer"
install -m 0644 "$ROOT/README.md"                           "$PKG_DIR/usr/share/doc/herald/README.md"
install -m 0644 "$ROOT/LICENSE"                             "$PKG_DIR/usr/share/doc/herald/copyright"
install -m 0755 "$ROOT/debian/postinst"                     "$PKG_DIR/DEBIAN/postinst"
install -m 0755 "$ROOT/debian/postrm"                       "$PKG_DIR/DEBIAN/postrm"

cat > "$PKG_DIR/DEBIAN/control" <<EOF
Package: herald
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: all
Depends: bash (>= 4.0), systemd, curl, python3, coreutils
Suggests: update-motd
Maintainer: Ramazan Yavuz <yavuzramazan1994@gmail.com>
Homepage: https://github.com/ra-yavuz/herald
Description: print a quote at the top of every new terminal and at login
 herald is a small Linux daemon and CLI that prints a daily quote. It
 supports two display surfaces: a terminal greeting at the top of every
 new interactive shell (/etc/profile.d/), and a login MOTD via
 /etc/update-motd.d/. Both are off by default; toggle with 'herald
 terminal', 'herald motd', or 'herald all'.
 .
 Quotes are fetched from zenquotes.io with a 1.5s timeout, with a
 fallback to a bundled local pool of about 30 curated quotes. The
 cache is refreshed by a systemd timer every three hours by default;
 configurable via 'herald set-refresh <hours>'.
 .
 An optional /etc/herald.prefix file lets you prepend custom text
 above the quote.
 .
 DISCLAIMER: provided AS IS, no warranty. Quotes are fetched from a
 third-party service. The author is not liable for the content of
 fetched quotes, for events outside the author's control, or for any
 damage caused by installing or running this software. See README for
 full text.
EOF
: > "$PKG_DIR/DEBIAN/conffiles"

dpkg-deb --build --root-owner-group "$PKG_DIR" "$DEB_OUT"
echo
echo "Built: $DEB_OUT"
ls -la "$DEB_OUT"
