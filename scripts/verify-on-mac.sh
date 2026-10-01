#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
exec > >(tee build/verification.log) 2>&1
if ! command -v xcodebuild >/dev/null; then
  echo "This step requires a macOS build machine with Xcode (e.g. Codemagic)."
  exit 1
fi
xcodebuild -version
xcodebuild -list -project AutoDealerPro.xcodeproj
simulator_id=$(xcrun simctl list devices available -j | python3 scripts/select-simulator.py)
if [ -z "$simulator_id" ]; then
  echo "No iPhone simulator runtime is installed on the selected machine."
  exit 1
fi
result_path=".build/TestResults-$(date +%s).xcresult"
xcodebuild test \
  -project AutoDealerPro.xcodeproj \
  -scheme AutoDealerPro \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -destination-timeout 120 \
  -parallel-testing-enabled NO \
  -derivedDataPath .build \
  -resultBundlePath "$result_path" \
  CODE_SIGNING_ALLOWED=NO
