#!/bin/sh
set -eu
task_dir=$(mktemp -d /tmp/pawshots-ui.XXXXXX)
tar -C /workspace --exclude=android/.gradle --exclude=android/.kotlin \
  --exclude=android/local.properties -cf "$task_dir/source.tar" \
  lib test tool web assets android pubspec.yaml pubspec.lock l10n.yaml analysis_options.yaml .metadata
tar -C "$task_dir" -xf "$task_dir/source.tar"
cd "$task_dir"
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub tool/ui_preview_test.dart
mkdir -p /workspace/build/ui_preview
cp build/ui_preview/*.png /workspace/build/ui_preview/
if [ "${BUILD_ANDROID:-0}" = "1" ]; then
  flutter build apk --debug --no-pub
  mkdir -p /workspace/build/app/outputs/flutter-apk
  cp build/app/outputs/flutter-apk/app-debug.apk /workspace/build/app/outputs/flutter-apk/app-debug.apk
fi
