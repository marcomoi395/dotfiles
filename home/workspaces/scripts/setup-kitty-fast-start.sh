#!/bin/sh
set -eu

binds=${XDG_CONFIG_HOME:-"$HOME/.config"}/niri/dms/binds.kdl
cache=${XDG_CACHE_HOME:-"$HOME/.cache"}/kitty-pycache
if printf '%s' "$cache" | grep -Eq '[\\"]'; then
    echo 'Cache path cannot contain quotes or backslashes' >&2
    exit 1
fi
old='    Mod+T hotkey-overlay-title="Open Terminal" { spawn "kitty" "--single-instance"; }'
new="    Mod+Return hotkey-overlay-title=\"Open Terminal\" { spawn \"env\" \"PYTHONPYCACHEPREFIX=$cache\" \"kitty\" \"--single-instance\"; }"

command -v kitty >/dev/null || { echo 'Kitty is required' >&2; exit 1; }
command -v niri >/dev/null || { echo 'Niri is required' >&2; exit 1; }
[ -f "$binds" ] || { echo "Missing DMS bindings: $binds" >&2; exit 1; }

# ponytail: Matches the standard DMS Kitty binding; extend this for other layouts.
if grep -Fxq "$new" "$binds"; then
    :
elif grep -Eq '^[[:space:]]*Mod\+Return[[:space:]]' "$binds"; then
    echo 'Mod+Return is already assigned; no changes made' >&2
    exit 1
elif grep -Fxq "$old" "$binds"; then
    tmp=$(mktemp "${binds}.XXXXXX")
    backup=$(mktemp "${binds}.backup.XXXXXX")
    trap 'rm -f "$tmp" "$backup"' EXIT HUP INT TERM
    cp -p "$binds" "$backup"
    awk -v old="$old" -v new="$new" '$0 == old {$0 = new} {print}' "$binds" > "$tmp"
    chmod --reference="$binds" "$tmp"
    mv "$tmp" "$binds"
    if ! niri validate; then
        mv "$backup" "$binds"
        echo 'Niri validation failed; original bindings restored' >&2
        exit 1
    fi
else
    echo 'Expected Mod+T Kitty binding not found; no changes made' >&2
    exit 1
fi

mkdir -p "$cache"
PYTHONPYCACHEPREFIX=$cache kitty --help >/dev/null
niri validate
echo "Configured Mod+Return and Kitty cache: $cache"
