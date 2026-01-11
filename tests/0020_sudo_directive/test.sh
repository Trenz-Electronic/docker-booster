#!/bin/sh
# Test: #sudo: directive for sudoers configuration
# Verifies that:
# - Without #sudo: directive, no sudoers entry is created
# - With #sudo: all, sudoers entry is created and sudo works
# - su-based privilege drop works without sudo installed

set -e

fail=0

# Clean up any existing images
docker rmi -f 0020_no_sudo 2>/dev/null || true
docker rmi -f 0020_sudo_all 2>/dev/null || true

echo "=== Test 1: Without #sudo: directive, su works but sudo not configured ==="
mkdir -p test_no_sudo
cd test_no_sudo
cat > Dockerfile <<'EOF'
FROM alpine:latest
EOF
ln -sf ../../../build-and-run run
# Test that basic commands work (su-based privilege drop)
output=$(./run whoami 2>&1)
expected_user=$(whoami)
if echo "$output" | grep -q "$expected_user"; then
    echo "PASS: Container runs as correct user via su"
else
    echo "FAIL: User mapping not working"
    echo "Output: $output"
    fail=1
fi
cd ..

echo ""
echo "=== Test 2: With #sudo: all, sudoers entry is created ==="
mkdir -p test_sudo_all
cd test_sudo_all
cat > Dockerfile <<'EOF'
#sudo: all
FROM alpine:latest
RUN apk add --no-cache sudo
EOF
ln -sf ../../../build-and-run run
# Test that sudo works
output=$(./run sudo whoami 2>&1)
if echo "$output" | grep -q "root"; then
    echo "PASS: sudo works with #sudo: all directive"
else
    echo "FAIL: sudo not working"
    echo "Output: $output"
    fail=1
fi
cd ..

echo ""
echo "=== Test 3: Without #sudo: directive, sudo fails (not configured) ==="
mkdir -p test_sudo_fail
cd test_sudo_fail
cat > Dockerfile <<'EOF'
FROM alpine:latest
RUN apk add --no-cache sudo
EOF
ln -sf ../../../build-and-run run
# Test that sudo fails because sudoers is not configured
# Use || true since we expect this command to fail
output=$(./run sudo whoami 2>&1 || true)
# Accept various failure messages: password required, not allowed, not in sudoers
if echo "$output" | grep -qE "(not allowed|not in the sudoers|permission denied|is not allowed|password is required|a terminal is required)"; then
    echo "PASS: sudo correctly fails without #sudo: directive"
elif echo "$output" | grep -q "root"; then
    echo "FAIL: sudo should not work without #sudo: directive"
    echo "Output: $output"
    fail=1
else
    echo "PASS: sudo fails without #sudo: directive (error: different message)"
fi
cd ..

# Cleanup
rm -rf test_no_sudo test_sudo_all test_sudo_fail
docker rmi -f 0020_no_sudo 0020_sudo_all 2>/dev/null || true

if [ "$fail" = 0 ]; then
    echo ""
    echo "PASS: All #sudo: directive tests passed"
fi

exit $fail
