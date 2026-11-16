#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ]; then echo 'Native SwiftUI verification requires macOS and Xcode.' >&2; exit 1; fi
npm run generate:lesson
xcodebuild -project apple/SmallestAgent.xcodeproj -scheme SmallestAgent -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test
xcodebuild -project apple/SmallestAgent.xcodeproj -scheme SmallestAgent -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
