#!/usr/bin/env bash
# Rebuilds the Hangul UI fonts in assets/fonts/ from Noto Sans CJK KR (SIL OFL 1.1, Regular + Bold).
# Each face holds all of Hangul (11,172 syllables + Jamo + compatibility Jamo), ASCII/Latin-1, general
# punctuation, CJK symbols/punctuation, fullwidth forms, arrows, geometric shapes and misc symbols
# (unicodes below; Hanja is left out), plus every character used in scripts/**/*.gd, experiments/**/*.gd
# and content/**/*.json (tools/used_chars.py), so UI text can change without rebuilding the font and
# every build (Android, later Web) renders Korean without system fonts.
# The file names keep "Lab3dSubset" because assets/fonts/*.import and the references use them; the
# faces are no longer text-only subsets. Japanese/Chinese text or Hanja would need its own glyphs.
# Run again only when a non-Hangul symbol outside the unicodes range is newly used; tests/run_tests.gd fails when
# a used character is missing, and when any of the 11,172 syllables is missing.
# Symbols Noto Sans CJK lacks (subscripts such as x₀ in the experiment texts, ⚖ ⌁ ▰ list icons) come
# from a DejaVu Sans subset (Bitstream Vera licence, assets/fonts/DejaVu-LICENSE.txt) that UiTheme
# sets as the fallback of both faces; it holds only the used non-ASCII characters (Hangul is not in DejaVu).
# Needs: pyftsubset (fonttools; falls back to `uvx --from fonttools pyftsubset`), fonts-noto-cjk
# and fonts-dejavu-core.
set -euo pipefail
cd "$(dirname "$0")/.."
noto_dir=${NOTO_CJK_DIR:-/usr/share/fonts/opentype/noto}
if command -v pyftsubset >/dev/null; then subset=(pyftsubset); else subset=(uvx --from fonttools pyftsubset); fi
chars=$(python3 -I tools/used_chars.py)
unicodes="U+0020-007E,U+00A0-00FF,U+2000-206F,U+3000-303F,U+1100-11FF,U+3130-318F,U+AC00-D7A3,U+FF00-FFEF,U+2190-21FF,U+25A0-25FF,U+2600-26FF"
for weight in Regular Bold; do
  # Font number 1 in the Noto Sans CJK collection is the KR face.
  "${subset[@]}" "$noto_dir/NotoSansCJK-$weight.ttc" --font-number=1 --text="$chars" --unicodes="$unicodes" \
    --layout-features='*' --output-file="assets/fonts/NotoSansKR-Lab3dSubset-$weight.otf"
done
dejavu_dir=${DEJAVU_DIR:-/usr/share/fonts/truetype/dejavu}
for face in "DejaVuSans Regular" "DejaVuSans-Bold Bold"; do
  set -- $face
  "${subset[@]}" "$dejavu_dir/$1.ttf" --text="$chars" --layout-features='*' \
    --output-file="assets/fonts/Lab3dSymbols-$2.ttf"
done
ls -l assets/fonts/*.otf assets/fonts/*.ttf
