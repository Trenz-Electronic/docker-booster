#!/bin/sh
# Test: User mapping - container user matches host UID/GID/group
# Note: group name may be renamed if it conflicts (e.g., "users" -> "users_1000")

set -e

host_user=$(id -un)
host_group=$(id -gn)
host_uid=$(id -u)
host_gid=$(id -g)

container_user=$(./run id -un)
container_group=$(./run id -gn)
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

# Group name should match or be prefixed with host group name (if conflict)
case "$container_group" in
    "$host_group"|"${host_group}_"*)
        # OK - exact match or conflict rename
        ;;
    *)
        echo "FAIL: group name mismatch: host=$host_group container=$container_group"
        fail=1
        ;;
esac

if [ "$fail" = 0 ]; then
    echo "PASS: User mapping correct (user=$host_user group=$container_group uid=$host_uid gid=$host_gid)"
fi

exit $fail
