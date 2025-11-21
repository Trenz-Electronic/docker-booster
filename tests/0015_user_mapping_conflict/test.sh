#!/bin/sh
# Test: Group name conflict - host group name exists with different GID

set -e

host_group=$(id -gn)
host_gid=$(id -g)
conflict_gid=9999

# Generate Dockerfile with conflicting group
cat > Dockerfile.tmp <<EOF
FROM alpine:latest
RUN apk add --no-cache sudo
RUN echo "$host_group:x:$conflict_gid::" >> /etc/group
EOF

# Build image with conflicting group
docker build -f Dockerfile.tmp -t 0015_user_mapping_conflict . >/dev/null 2>&1

# Run and check group name (should be renamed)
container_group=$(./run id -gn)
container_gid=$(./run id -g)

# Cleanup
rm -f Dockerfile.tmp

fail=0

# Group should be renamed to avoid conflict
expected_group="${host_group}_${host_gid}"
if [ "$container_group" != "$expected_group" ]; then
    echo "FAIL: Expected group '$expected_group', got '$container_group'"
    fail=1
fi

# GID should still match host
if [ "$container_gid" != "$host_gid" ]; then
    echo "FAIL: GID mismatch: expected $host_gid, got $container_gid"
    fail=1
fi

if [ "$fail" = 0 ]; then
    echo "PASS: Group conflict handled (renamed to $container_group, gid=$container_gid)"
fi

exit $fail
