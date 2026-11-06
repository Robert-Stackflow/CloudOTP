#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
mkdir -p "$REPO_ROOT/build"
TEST_DIR=$(mktemp -d "$REPO_ROOT/build/ios-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT
xcrun swiftc "$REPO_ROOT/ios/AutoFill/OTPGenerator.swift" "$REPO_ROOT/test/ios/otp_vectors.swift" -o "$TEST_DIR/otp-vectors"
/usr/bin/codesign --force --sign - "$TEST_DIR/otp-vectors"
"$TEST_DIR/otp-vectors"
