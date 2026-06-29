#!/usr/bin/env bash
# Generate Flutter platform folders (android, ios, ...) if missing.
# Requires Flutter SDK: https://docs.flutter.dev/get-started/install
set -e
cd "$(dirname "$0")"
if [ ! -d android ]; then
  flutter create . --org org.makekeralaclean --project-name make_kerala_clean
  echo "Platform folders created."
else
  echo "Platform folders already exist."
fi
flutter pub get
