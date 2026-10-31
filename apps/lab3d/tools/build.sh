#!/usr/bin/env bash
# Headless pipeline for the 3D app: import -> tests -> Android builds.
# Usage: apps/lab3d/tools/build.sh [test|android|play|all]   (default: all = test + android)
#   android: a release APK signed with the Android debug keystore (device checks only, never for the Play Store).
#   play:    the Play Store bundle (AAB, Gradle build) signed with the upload key; refuses to run without it
#            (docs/release/README.md). versionCode = commits up to HEAD, versionName = the nearest v* tag
#            (v0.1.1 -> 0.1.1, none: 0.1.0); VERSION_CODE / VERSION_NAME override them.
# Godot 4.7.2 + export templates: spikes/godot/tools/setup_editor.sh. GODOT overrides the binary
# (CI: .github/scripts/install-godot.sh). GODOT_TEST_TIMEOUT (s, default 900) stops a hung test run.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-$HOME/.local/share/godot-spike/godot}
what=${1:-all}
mkdir -p exports && touch exports/.gdignore   # keep export output out of the Godot import scan

"$GODOT" --headless --path . --import >/dev/null 2>&1 || true   # fresh checkout: class cache + font import

if [[ $what == test || $what == all ]]; then
  log=exports/test.log
  status=0
  # A script error inside a coroutine can leave the SceneTree running: the timeout turns that into a failure.
  timeout "${GODOT_TEST_TIMEOUT:-900}" "$GODOT" --headless --path . --fixed-fps 60 -s res://tests/run_tests.gd >"$log" 2>&1 || status=$?
  grep -E '^(PASS|FAIL|RESULT|==)' "$log" || true
  # A script that fails to compile can leave checks unrun or vacuous: treat any SCRIPT ERROR (or engine ERROR line) as a failure.
  if [[ $status -ne 0 ]] || grep -q '^FAIL' "$log" || grep -q 'SCRIPT ERROR' "$log" || grep -q '^ERROR' "$log" || ! grep -q '^RESULT: PASS' "$log"; then
    echo "lab3d tests failed (exit $status); tail of $log:" >&2
    tail -n 40 "$log" >&2
    exit 1
  fi
fi
if [[ $what == android || $what == all ]]; then
  mkdir -p exports/android
  GODOT_ANDROID_KEYSTORE_RELEASE_PATH=${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:-$HOME/.android/debug.keystore} \
  GODOT_ANDROID_KEYSTORE_RELEASE_USER=${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-androiddebugkey} \
  GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:-android} \
    "$GODOT" --headless --path . --export-release Android exports/android/puppy-land.apk
  ls -l exports/android/puppy-land.apk
fi

if [[ $what == play ]]; then
  # The upload key, never the debug keystore: a bundle signed with it cannot go to the Play Store.
  for v in GODOT_ANDROID_KEYSTORE_RELEASE_PATH GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD; do
    [[ -n ${!v:-} ]] || { echo "play: $v is not set (the upload key, docs/release/README.md)" >&2; exit 1; }
  done
  [[ -f $GODOT_ANDROID_KEYSTORE_RELEASE_PATH ]] || { echo "play: no keystore at $GODOT_ANDROID_KEYSTORE_RELEASE_PATH" >&2; exit 1; }
  [[ $GODOT_ANDROID_KEYSTORE_RELEASE_USER != androiddebugkey ]] || { echo "play: that is the debug key" >&2; exit 1; }
  code=${VERSION_CODE:-$(git rev-list --count HEAD 2>/dev/null || true)}
  name=${VERSION_NAME:-$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || echo v0.1.0)}
  name=${name#v}
  [[ $code =~ ^[1-9][0-9]*$ ]] || { echo "play: no versionCode (build in the git checkout or set VERSION_CODE)" >&2; exit 1; }
  [[ $name =~ ^[0-9]+(\.[0-9]+)*$ ]] || { echo "play: bad versionName '$name'" >&2; exit 1; }
  # The version goes into the "Android Play" preset for this export only; the file is put back after.
  cp export_presets.cfg exports/export_presets.cfg.orig
  trap 'cp exports/export_presets.cfg.orig export_presets.cfg' EXIT
  awk -v code="$code" -v name="$name" '
    /^\[preset\./ { play = ($0 == "[preset.1.options]") }
    play && /^version\/code=/ { $0 = "version/code=" code }
    play && /^version\/name=/ { $0 = "version/name=\"" name "\"" }
    { print }' exports/export_presets.cfg.orig > export_presets.cfg
  grep -q '^name="Android Play"' export_presets.cfg || { echo "play: no \"Android Play\" preset" >&2; exit 1; }
  mkdir -p exports/android
  out=exports/android/puppy-land-$name-v$code.aab
  rm -f "$out"
  "$GODOT" --headless --path . --install-android-build-template --export-release "Android Play" "$out"
  [[ -s $out ]] || { echo "play: the export made no bundle" >&2; exit 1; }
  echo "play: $name $code"
  ls -l "$out"
fi
