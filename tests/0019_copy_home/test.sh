#!/bin/sh
# Test: Copy home files directive (#copy.home:)
# Verifies that:
# - Single file copying works
# - Multiple files copying works
# - Missing files cause error
# - Files are extracted to correct location

set -e

fail=0

# Setup test files in $HOME
echo "test license content" > "$HOME/.test-license-0019.dat"
mkdir -p "$HOME/.config/test-tool-0019"
echo "test config" > "$HOME/.config/test-tool-0019/config.json"

# Clean up any existing images
docker rmi -f 0019_copy_single 2>/dev/null || true
docker rmi -f 0019_copy_multiple 2>/dev/null || true

echo "=== Test 1: Copy single file from home ==="
mkdir -p test_single
cd test_single
cat > Dockerfile <<'EOF'
#copy.home: .test-license-0019.dat
FROM ubuntu:22.04
EOF
ln -sf ../../../build-and-run run
output=$(./run cat ~/.test-license-0019.dat 2>&1)
case "$output" in
    *"test license content"*)
        echo "PASS: Single file copied successfully"
        ;;
    *)
        echo "FAIL: File not found in container"
        echo "Output: $output"
        fail=1
        ;;
esac
# Check that the message about collecting files was shown
if echo "$output" | grep -q "Collected home files for container"; then
    echo "PASS: Informative message shown"
else
    echo "FAIL: Expected 'Collected home files' message"
    fail=1
fi
cd ..

echo ""
echo "=== Test 2: Copy multiple files from home ==="
mkdir -p test_multiple
cd test_multiple
cat > Dockerfile <<'EOF'
#copy.home: .test-license-0019.dat
#copy.home: .config/test-tool-0019/config.json
FROM ubuntu:22.04
EOF
ln -sf ../../../build-and-run run
output=$(./run sh -c 'cat ~/.test-license-0019.dat && cat ~/.config/test-tool-0019/config.json' 2>&1)
if echo "$output" | grep -q "test license content" && echo "$output" | grep -q "test config"; then
    echo "PASS: Multiple files copied successfully"
else
    echo "FAIL: Not all files found in container"
    echo "Output: $output"
    fail=1
fi
cd ..

echo ""
echo "=== Test 3: Missing file causes error ==="
mkdir -p test_missing
cd test_missing
cat > Dockerfile <<'EOF'
#copy.home: .nonexistent-file-0019.dat
FROM ubuntu:22.04
EOF
ln -sf ../../../build-and-run run
if ./run echo "should not run" 2>&1 | grep -q "ERROR: Failed to collect files"; then
    echo "PASS: Missing file error detected correctly"
else
    echo "FAIL: Expected error for missing file"
    fail=1
fi
cd ..

# Cleanup
rm -f "$HOME/.test-license-0019.dat"
rm -rf "$HOME/.config/test-tool-0019"
rm -rf test_single test_multiple test_missing
docker rmi -f 0019_copy_single 0019_copy_multiple 2>/dev/null || true

if [ "$fail" = 0 ]; then
    echo ""
    echo "PASS: All copy.home directive tests passed"
fi

exit $fail
