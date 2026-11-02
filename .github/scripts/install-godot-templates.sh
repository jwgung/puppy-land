#!/usr/bin/env bash
# Installs the Android export templates of the pinned Godot (the release workflow's Play bundle).
# Usage: .github/scripts/install-godot-templates.sh <download dir>
#   -> ~/.local/share/godot/export_templates/4.7.2.stable/ (android_source.zip, android_*.apk, version.txt)
# The .tpz comes from the official GitHub release and must match the pinned SHA-512 (the release's
# SHA512-SUMS.txt). A .tpz already in <download dir> (the CI cache) is re-verified before use.
set -euo pipefail
VERSION=4.7.2-stable
TPZ=Godot_v${VERSION}_export_templates.tpz
SHA512=ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079
URL=https://github.com/godotengine/godot/releases/download/${VERSION}/${TPZ}

dir=${1:?usage: install-godot-templates.sh <download dir>}
mkdir -p "$dir"
cd "$dir"
if [[ ! -f $TPZ ]]; then
  curl -fsSL --retry 3 -o "$TPZ.part" "$URL"
  mv "$TPZ.part" "$TPZ"
fi
echo "$SHA512  $TPZ" | sha512sum -c - >&2
out=${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${VERSION/-/.}
mkdir -p "$out"
unzip -q -o -j "$TPZ" 'templates/android_*' 'templates/version.txt' -d "$out"
ls "$out" >&2
