#!/bin/sh
# Render deployment credentials into a copyparty config at container start.
#
# Why a wrapper: copyparty's config is an ini-like file with no escaping rules,
# so a raw value pasted in could break the section layout or inject directives.
# Credentials are validated here, written to tmpfs under /run, and never shipped
# inside the package or stored next to the shared files.
set -eu

USER_NAME="${COPYARTY_USER:-}"
USER_PASS="${COPYARTY_PASS:-}"

fail() {
    echo "[copyparty] refusing to start: $1" >&2
    # Never echo the offending value itself.
    exit 1
}

[ -n "$USER_NAME" ] || fail "COPYARTY_USER must be set"
[ -n "$USER_PASS" ] || fail "COPYARTY_PASS must be set"

case "$USER_NAME" in
    *[!A-Za-z0-9_.@-]*) fail "COPYARTY_USER may only contain letters, digits and _ . @ -" ;;
esac
case "$USER_PASS" in
    *[!A-Za-z0-9_.~!@#%^+=-]*) fail "COPYARTY_PASS contains unsupported characters" ;;
esac

[ "${#USER_PASS}" -ge 12 ] || fail "COPYARTY_PASS must be at least 12 characters"

CONF_DIR=/run/copyparty
CONF="$CONF_DIR/copyparty.conf"
mkdir -p "$CONF_DIR"
chmod 700 "$CONF_DIR"

{
    printf '%s\n' '# generated at container start; not persisted'
    printf '%s\n' '[global]'
    printf '%s\n' '  e2dsa'
    printf '%s\n' '  e2ts'
    printf '%s\n' '  ansi'
    printf '%s\n' '  vc-exit'
    printf '%s\n' '  no-robots'
    printf '%s\n' '  force-js'
    printf '%s\n' '  df: 1'
    printf '%s\n' ''
    printf '%s\n' '[accounts]'
    printf '  %s: %s\n' "$USER_NAME" "$USER_PASS"
    printf '%s\n' ''
    printf '%s\n' '[/]'
    printf '%s\n' '  /w'
    printf '%s\n' '  accs:'
    printf '    rwmd: %s\n' "$USER_NAME"
    printf '%s\n' '  flags:'
    printf '%s\n' '    e2d'
    printf '%s\n' '    nodupe'
} > "$CONF"
chmod 600 "$CONF"

# Prefer the packaged console script; fall back to the module entrypoint.
if command -v copyparty >/dev/null 2>&1; then
    exec copyparty -c "$CONF"
fi
exec python3 -m copyparty -c "$CONF"
