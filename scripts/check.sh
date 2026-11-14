#!/usr/bin/env bash
# Build the app and run unit tests on an iOS simulator.
# Usage: ./scripts/check.sh            (first available iPhone simulator)
#        SIMULATOR_ID=<udid> ./scripts/check.sh
set -euo pipefail

cd "$(dirname "$0")/../yeoulmok"

if [[ ! -f Config.xcconfig ]]; then
  echo "Config.xcconfig is missing. Run: cp yeoulmok/Config.example.xcconfig yeoulmok/Config.xcconfig" >&2
  exit 1
fi

SIMULATOR_ID="${SIMULATOR_ID:-$(xcrun simctl list devices available | grep -m1 -E '^\s+iPhone' | grep -oE '[0-9A-F-]{36}')}"
if [[ -z "$SIMULATOR_ID" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 1
fi

xcodebuild test \
  -scheme yeoulmok \
  -destination "id=$SIMULATOR_ID" \
  -only-testing:yeoulmokTests \
  -quiet
echo "check.sh: build and unit tests passed"
