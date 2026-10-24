#!/bin/sh
# Build inside Linux for fast filesystem access; expose only a loopback port.
set -eu
task_dir=$(mktemp -d /tmp/pawshots-web.XXXXXX)
tar -C /workspace -cf "$task_dir/source.tar" lib test web assets tool \
  pubspec.yaml pubspec.lock l10n.yaml analysis_options.yaml
tar -C "$task_dir" -xf "$task_dir/source.tar"
cd "$task_dir"
flutter pub get
flutter analyze --no-pub
flutter test --no-pub

# Keep SQLite's WASM file compatible with the pinned Drift dependency.
asset_dir=/pub-cache/pawshots-web-assets/drift-2.35.2
mkdir -p "$asset_dir"
if [ ! -s "$asset_dir/sqlite3.wasm" ]; then
  curl --fail --location --retry 3 \
    https://github.com/simolus3/drift/releases/download/drift-2.35.2/sqlite3.wasm \
    --output "$asset_dir/sqlite3.wasm.download"
  mv "$asset_dir/sqlite3.wasm.download" "$asset_dir/sqlite3.wasm"
fi
cp "$asset_dir/sqlite3.wasm" web/sqlite3.wasm
dart compile js -O2 web/drift_worker.dart -o web/drift_worker.dart.js
flutter build web --no-pub --no-web-resources-cdn
echo 'PawShots browser preview ready at http://localhost:8080'
exec python3 tool/serve_preview.py --directory build/web --port 8080
