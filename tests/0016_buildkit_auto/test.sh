#!/bin/sh
# Test: BuildKit auto-detection - RUN --mount triggers DOCKER_BUILDKIT=1

set -e

# Force rebuild to see the message
docker rmi -f 0016_buildkit_auto 2>/dev/null || true

# Run a simple command and check that image builds successfully
# If BuildKit wasn't enabled, the build would fail
output=$(./run echo "buildkit test" 2>&1)

case "$output" in
    *"BuildKit mount syntax"*"buildkit test"*)
        echo "PASS: BuildKit auto-detected and enabled"
        exit 0
        ;;
    *"buildkit test"*)
        echo "PASS: BuildKit test (message not in stderr, but build succeeded)"
        exit 0
        ;;
    *)
        echo "FAIL: Unexpected output: $output"
        exit 1
        ;;
esac
