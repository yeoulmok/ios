#!/usr/bin/env bash
# Build the app and run unit tests on an iOS simulator.
# Usage: ./scripts/check.sh            (a booted iPhone simulator, else the first available one)
#        SIMULATOR_ID=<udid> ./scripts/check.sh
set -euo pipefail

cd "$(dirname "$0")/../yeoulmok"

if [[ ! -f Config.xcconfig ]]; then
  echo "Config.xcconfig is missing. Run: cp yeoulmok/Config.example.xcconfig yeoulmok/Config.xcconfig" >&2
  exit 1
fi

find_iphone() {
  xcrun simctl list devices available | grep -E '^\s+iPhone' | grep -E "$1" | grep -m1 -oE '[0-9A-F-]{36}' || true
}

SIMULATOR_ID="${SIMULATOR_ID:-$(find_iphone 'Booted')}"
SIMULATOR_ID="${SIMULATOR_ID:-$(find_iphone '.')}"
if [[ -z "$SIMULATOR_ID" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 1
fi

# Boot and wait until the simulator is ready. Letting xcodebuild boot it
# sometimes fails with "Failed to create a bundle instance" for the test bundle.
xcrun simctl bootstatus "$SIMULATOR_ID" -b > /dev/null

LOG="$(mktemp -t check)"
trap 'rm -f "$LOG"' EXIT

run_tests() {
  xcodebuild test \
    -scheme yeoulmok \
    -destination "id=$SIMULATOR_ID" \
    -only-testing:yeoulmokTests \
    -quiet 2>&1 | tee "$LOG"
  return "${PIPESTATUS[0]}"
}

# Sometimes the simulator cannot load the test bundle ("Failed to create a bundle
# instance"); running again always passes. The cause is unknown (#39), so retry once
# for that exact error only. Build errors and failing tests are never retried.
status=0
run_tests || status=$?
if [[ $status -ne 0 ]] && grep -q "Failed to create a bundle instance" "$LOG"; then
  echo "check.sh: the simulator could not load the test bundle (known flaky error, #39). Retrying once..." >&2
  status=0
  run_tests || status=$?
fi
if [[ $status -ne 0 ]]; then
  exit "$status"
fi
echo "check.sh: build and unit tests passed"
