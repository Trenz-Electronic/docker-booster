#!/bin/sh
# Test: #http.static: pragma serves files during build

set -e

http_dir="/tmp/docker-booster-http-test"
expected="http-static-test-content-$$"

# Setup: create directory with marker file
mkdir -p "$http_dir"
echo "$expected" > "$http_dir/marker.txt"

# Force rebuild by removing image
docker rmi -f 0008_pragma_http_static 2>/dev/null || true

# Run (triggers build which fetches via HTTP)
output=$(./run cat /tmp/fetched.txt) || {
    rm -rf "$http_dir"
    echo "FAIL: Build or run failed"
    exit 1
}

# Cleanup
rm -rf "$http_dir"

# Verify
if [ "$output" = "$expected" ]; then
    echo "PASS: HTTP static file served during build"
    exit 0
else
    echo "FAIL: Content mismatch: expected='$expected' got='$output'"
    exit 1
fi
