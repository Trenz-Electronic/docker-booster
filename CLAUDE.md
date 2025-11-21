# CLAUDE.md

## Project Overview

docker-booster is a single-script Docker workflow tool that automates image building, user mapping, and volume mounting for development environments.

## Key Files

- `build-and-run` - The main script (POSIX shell). This is the entire tool.
- `README.md` - User documentation

## Dockerfile Directive Syntax

The script parses special comment directives from Dockerfiles:

| Directive | Location | Purpose |
|-----------|----------|---------|
| `# platform: <arch>` | First 10 lines | Cross-platform builds (arm64, amd64) |
| `#http.static: KEY=/path` | First 20 lines | Serve local dirs during build |

Note: `ENV` vars defined in the Dockerfile (after the last `FROM`) are automatically preserved across sudo inside the container.

## Architecture

The script operates in two modes based on `$0`:
1. **Normal mode** - Parses Dockerfile, builds image if needed, runs container
2. **user-command mode** - Runs inside container, creates user matching host UID/GID, executes command

## Testing

Run all tests:
```sh
tests/run-all              # Run tests, cleanup after
tests/run-all --no-cleanup # Run tests, keep containers for debugging
tests/run-all --cleanup    # Only cleanup, no tests
```

### Test Structure

Tests live in `tests/NNNN_name/` directories (numbered for ordering):
- `Dockerfile` - Test container definition
- `run` - Symlink to `../../build-and-run`
- `test.sh` - Test script (exit 0 = pass, non-zero = fail)

### Test Cases

- `0001_preserve_env` - Tests ENV vars from Dockerfile are preserved across sudo
- `0002_pragma_platform_aarch64` - Tests `# platform: arm64` runs container on aarch64
