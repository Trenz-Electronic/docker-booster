#!/bin/sh
# Test: Command-line docker options are passed through

set -e

fail=0

# Test --network host (verify by checking hostname matches host)
host_hostname=$(hostname)
output=$(./run --network host hostname)
if [ "$output" = "$host_hostname" ]; then
    echo "PASS: --network host"
else
    echo "FAIL: --network host - expected $host_hostname, got: $output"
    fail=1
fi

# Test -v volume mount
test_file="/tmp/docker-booster-test-$$"
echo "test_content_$$" > "$test_file"
output=$(./run -v "$test_file:/test_mount:ro" cat /test_mount)
rm -f "$test_file"
if [ "$output" = "test_content_$$" ]; then
    echo "PASS: -v volume mount"
else
    echo "FAIL: -v volume mount - got: $output"
    fail=1
fi

# Test --cpus (verify cgroup limit is set)
output=$(./run --cpus 2 cat /sys/fs/cgroup/cpu.max 2>/dev/null || ./run --cpus 2 cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us 2>/dev/null)
case "$output" in
    200000*)
        echo "PASS: --cpus 2"
        ;;
    *)
        echo "FAIL: --cpus 2 - unexpected limit: $output"
        fail=1
        ;;
esac

exit $fail
