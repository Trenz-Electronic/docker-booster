#!/bin/sh
# Test: TTY absent - no tty when run without interactive terminal

set -e

output=$(./run tty 2>&1) || true

case "$output" in
    *"not a tty"*)
        echo "PASS: No TTY detected as expected"
        exit 0
        ;;
    *)
        echo "FAIL: Expected 'not a tty', got: $output"
        exit 1
        ;;
esac
