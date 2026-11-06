#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
mkdir -p "$REPO_ROOT/build"
TEST_DIR=$(mktemp -d "$REPO_ROOT/build/ios-privacy-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT
cat "$REPO_ROOT/ios/Runner/PrivacyCoverPolicy.swift" > "$TEST_DIR/main.swift"
sed '/^@main$/d' "$REPO_ROOT/test/ios/privacy_cover_vectors.swift" >> "$TEST_DIR/main.swift"
printf '\nPrivacyTests.main()\n' >> "$TEST_DIR/main.swift"
xcrun swift "$TEST_DIR/main.swift"
