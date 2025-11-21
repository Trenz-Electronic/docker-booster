#!/bin/sh
# Test: TTY present - tty detected when run with pseudo-terminal

set -e

output=$(script -q -c "./run tty" /dev/null 2>&1) || true

case "$output" in
    */dev/pts/*|*/dev/tty*)
        echo "PASS: TTY detected: $output"
        exit 0
        ;;
    *"not a tty"*)
        echo "FAIL: Expected TTY device, got 'not a tty'"
        exit 1
        ;;
    *)
        echo "FAIL: Unexpected output: $output"
        exit 1
        ;;
esac
