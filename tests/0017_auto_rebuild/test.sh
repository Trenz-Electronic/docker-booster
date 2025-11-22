#!/bin/sh
# Test: Automatic rebuild detection with context hash
# Verifies that:
# - Initial build creates hash label
# - Subsequent runs skip rebuild when nothing changed
# - Changes to Dockerfile trigger rebuild
# - Changes to context files trigger rebuild

set -e

fail=0

# Clean up any existing image
docker rmi -f 0017_auto_rebuild 2>/dev/null || true

# Change to container subdirectory (so test.sh isn't in build context)
cd 0017_auto_rebuild

echo "=== Test 1: First build (image not found) ==="
output=$(./run echo "first build" 2>&1)
case "$output" in
    *"not found, rebuilding"*"first build"*)
        echo "PASS: Initial build triggered"
        ;;
    *)
        echo "FAIL: Expected rebuild message not found"
        echo "Output: $output"
        fail=1
        ;;
esac

echo ""
echo "=== Test 2: Verify hash label was stored ==="
hash_label=$(docker inspect --format='{{index .Config.Labels "docker-booster.context-hash"}}' 0017_auto_rebuild 2>/dev/null)
hash_length=$(echo "$hash_label" | wc -c)
if [ -n "$hash_label" ] && [ "$hash_length" -eq 65 ]; then
    short_hash=$(echo "$hash_label" | cut -c1-12)
    echo "PASS: Hash label stored (${short_hash}...)"
else
    echo "FAIL: Hash label missing or invalid: '$hash_label' (length: $hash_length)"
    fail=1
fi

echo ""
echo "=== Test 3: Second run with no changes (should skip rebuild) ==="
output=$(./run echo "no rebuild" 2>&1)
case "$output" in
    *"up-to-date"*"no rebuild"*)
        echo "PASS: Rebuild skipped when no changes"
        ;;
    *"rebuilding"*)
        echo "FAIL: Unexpected rebuild when nothing changed"
        echo "Output: $output"
        fail=1
        ;;
    *)
        echo "FAIL: Expected 'up-to-date' message not found"
        echo "Output: $output"
        fail=1
        ;;
esac

echo ""
echo "=== Test 4: Modify Dockerfile (should trigger rebuild) ==="
# Save original Dockerfile
cp Dockerfile Dockerfile.backup
echo "# test comment" >> Dockerfile
output=$(./run echo "after dockerfile change" 2>&1)
case "$output" in
    *"changes detected"*"after dockerfile change"*)
        echo "PASS: Dockerfile change triggered rebuild"
        ;;
    *"up-to-date"*)
        echo "FAIL: Change not detected, rebuild was skipped"
        echo "Output: $output"
        fail=1
        ;;
    *)
        echo "FAIL: Expected rebuild message not found"
        echo "Output: $output"
        fail=1
        ;;
esac

# Restore original Dockerfile
mv Dockerfile.backup Dockerfile

echo ""
echo "=== Test 5: Add context file (should trigger rebuild) ==="
echo "test content" > test_file.txt
output=$(./run echo "after context change" 2>&1)
case "$output" in
    *"changes detected"*"after context change"*)
        echo "PASS: Context file change triggered rebuild"
        ;;
    *"up-to-date"*)
        echo "FAIL: Context change not detected"
        echo "Output: $output"
        fail=1
        ;;
    *)
        echo "FAIL: Expected rebuild message not found"
        echo "Output: $output"
        fail=1
        ;;
esac

# Cleanup
rm -f test_file.txt

echo ""
echo "=== Test 6: Rebuild to get new hash after file removed ==="
# After test 5, we removed test_file.txt, so context is different from the current image
# The current image was built with test_file.txt present
# We need to rebuild to match the new context (file removed)
output=$(./run echo "rebuild after removal" 2>&1)
# This should rebuild because test_file.txt was removed
echo "Rebuild triggered (expected): $?"

echo ""
echo "=== Test 7: Verify no further rebuilds ==="
output=$(./run echo "final run" 2>&1)
case "$output" in
    *"up-to-date"*"final run"*)
        echo "PASS: No rebuild when context stable"
        ;;
    *)
        echo "FAIL: Expected 'up-to-date' message"
        echo "Output: $output"
        fail=1
        ;;
esac

if [ "$fail" = 0 ]; then
    echo ""
    echo "PASS: All automatic rebuild detection tests passed"
fi

exit $fail
