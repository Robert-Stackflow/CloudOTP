#!/bin/sh
set -eu
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
mkdir -p "$REPO_ROOT/build"
TEST_DIR=$(mktemp -d "$REPO_ROOT/build/ios-oauth-tests.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT
cat "$REPO_ROOT/third-party/tool/flutter_web_auth_2/ios/Classes/OAuthCallback.swift" > "$TEST_DIR/main.swift"
sed '/^@main$/d' "$REPO_ROOT/test/ios/oauth_callback_vectors.swift" >> "$TEST_DIR/main.swift"
printf '\nCallbackTests.main()\n' >> "$TEST_DIR/main.swift"
xcrun swift "$TEST_DIR/main.swift"
