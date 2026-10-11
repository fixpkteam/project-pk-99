#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
flutter --version --machine | python3 -c 'import json,sys; v=json.load(sys.stdin); assert v["frameworkVersion"] == "3.47.7", v["frameworkVersion"]; assert v["dartSdkVersion"].startswith("3.13.5"), v["dartSdkVersion"]'
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
flutter build web --dart-define-from-file=config/development.example.json
