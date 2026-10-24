#!/bin/sh
# Run checks in the container filesystem to avoid slow Windows bind-mount I/O.
# Source files stay on the host. Only the successful APK is copied back.
set -eu
task_dir=$(mktemp -d /tmp/pawshots-check.XXXXXX)
tar -C /workspace \
  --exclude=android/.gradle --exclude=android/local.properties \
  --exclude=android/.kotlin \
  -cf "$task_dir/source.tar" lib test android web assets pubspec.yaml pubspec.lock l10n.yaml \
  analysis_options.yaml .metadata
tar -C "$task_dir" -xf "$task_dir/source.tar"
cd "$task_dir"
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
mkdir -p /workspace/build/app/outputs/flutter-apk
cp build/app/outputs/flutter-apk/app-debug.apk /workspace/build/app/outputs/flutter-apk/app-debug.apk
echo 'Verified debug APK copied to build/app/outputs/flutter-apk/app-debug.apk'
