#!/bin/sh
# Test: User mapping - container user matches host UID/GID
# Note: group name is not preserved (uses "mygroup"), only GID matters

set -e

host_user=$(id -un)
host_uid=$(id -u)
host_gid=$(id -g)

container_user=$(./run id -un)
container_uid=$(./run id -u)
container_gid=$(./run id -g)

fail=0

if [ "$host_user" != "$container_user" ]; then
    echo "FAIL: username mismatch: host=$host_user container=$container_user"
    fail=1
fi

if [ "$host_uid" != "$container_uid" ]; then
    echo "FAIL: UID mismatch: host=$host_uid container=$container_uid"
    fail=1
fi

if [ "$host_gid" != "$container_gid" ]; then
    echo "FAIL: GID mismatch: host=$host_gid container=$container_gid"
    fail=1
fi

if [ "$fail" = 0 ]; then
    echo "PASS: User mapping correct (user=$host_user uid=$host_uid gid=$host_gid)"
fi

exit $fail
