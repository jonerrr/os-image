#!/usr/bin/env bash
set -euo pipefail

UUID="fullscreen-avoider@noobsai.github.com"
DEST="/usr/share/gnome-shell/extensions/${UUID}"
GNOME_VERSION=$(gnome-shell --version | grep -oE '[0-9]+' | head -n1)

# Use the officially supported release if available.
# Temporarily fall back to GNOME 50 on GNOME 51.
VERSION=$(curl -fsSL --retry 5 \
    "https://extensions.gnome.org/extension-info/?pk=4362" |
    jq -er --arg v "$GNOME_VERSION" '
        .shell_version_map |
        .[$v].version //
        (if $v == "51" then .["50"].version else null end)
    ')

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL --retry 5 \
    "https://extensions.gnome.org/extension-data/${UUID//@/}.v${VERSION}.shell-extension.zip" \
    -o "$TMP/extension.zip"

unzip -q "$TMP/extension.zip" -d "$TMP/extension"

cd "$TMP/extension"

# Only bypass compatibility validation for GNOME 51.
if ! jq -e --arg v "$GNOME_VERSION" \
    '."shell-version" | index($v) != null' metadata.json >/dev/null; then

    [[ "$GNOME_VERSION" == "51" ]]

    echo "Patching Fullscreen Avoider for GNOME 51"

    jq '."shell-version" += ["51"]' \
        metadata.json > metadata.json.tmp

    mv metadata.json.tmp metadata.json
fi

# Install the extension system-wide.
mkdir -p "$DEST"
cp -a . "$DEST/"

# Compile the extension's GSettings schemas.
if [[ -d schemas ]]; then
    glib-compile-schemas --strict "$DEST/schemas"
fi
