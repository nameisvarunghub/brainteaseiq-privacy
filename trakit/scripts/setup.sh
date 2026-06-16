#!/usr/bin/env bash
# TrakIt one-shot setup script.
#
#   ./scripts/setup.sh
#
# What it does, in order:
#   1. flutter create .  (scaffolds android/ ios/ for the bare lib/ tree)
#   2. Patches AndroidManifest.xml and Info.plist with camera + photo perms
#   3. flutter pub get
#   4. Generates the app icon PNGs from tool/gen_icon.dart
#   5. Runs flutter_launcher_icons to fan out platform variants
#
# Idempotent — safe to re-run.

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter not found in PATH" >&2
  exit 1
fi

echo "→ flutter create ."
flutter create . \
  --platforms=ios,android,web \
  --org com.trakit \
  --project-name trakit \
  >/dev/null

echo "→ flutter pub get"
flutter pub get >/dev/null

# ── Android permissions ─────────────────────────────────────────
android_manifest="android/app/src/main/AndroidManifest.xml"
if [[ -f "$android_manifest" ]]; then
  for perm in CAMERA INTERNET READ_MEDIA_IMAGES READ_EXTERNAL_STORAGE; do
    if ! grep -q "android.permission.$perm" "$android_manifest"; then
      awk -v p="$perm" '
        /<manifest[^>]*>/ && !done {
          print
          print "    <uses-permission android:name=\"android.permission." p "\"/>"
          done = 1
          next
        }
        { print }
      ' "$android_manifest" > "$android_manifest.tmp" \
        && mv "$android_manifest.tmp" "$android_manifest"
    fi
  done
  echo "→ patched $android_manifest"
fi

# ── iOS permissions ─────────────────────────────────────────────
plist="ios/Runner/Info.plist"
if [[ -f "$plist" ]]; then
  add_plist_key() {
    local key="$1"
    local desc="$2"
    if ! grep -q "<key>$key</key>" "$plist"; then
      # Insert key + string right before the closing </dict>
      awk -v key="$key" -v desc="$desc" '
        /<\/dict>/ && !done {
          print "\t<key>" key "</key>"
          print "\t<string>" desc "</string>"
          done = 1
        }
        { print }
      ' "$plist" > "$plist.new" && mv "$plist.new" "$plist"
    fi
  }
  add_plist_key "NSCameraUsageDescription" \
    "TrakIt uses the camera to scan receipts and turn them into expenses."
  add_plist_key "NSPhotoLibraryUsageDescription" \
    "TrakIt reads payment screenshots from your library to log expenses."
  add_plist_key "NSPhotoLibraryAddUsageDescription" \
    "TrakIt can save processed receipts back to your library."
  echo "→ patched $plist"
fi

# ── App icon ────────────────────────────────────────────────────
echo "→ generating app icon"
dart run tool/gen_icon.dart

if grep -q "flutter_launcher_icons" pubspec.yaml; then
  echo "→ running flutter_launcher_icons"
  dart run flutter_launcher_icons || echo "flutter_launcher_icons failed — re-run after setup"
fi

cat <<EOF

✓ Setup complete.

Next:
  flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...

Omit --dart-define to run with the rule-based parser (no LLM calls).
EOF
