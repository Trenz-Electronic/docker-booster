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
| `#option: <docker-args>` | First 20 lines | Pass additional args to `docker run` |

Note: `ENV` vars defined in the Dockerfile (after the last `FROM`) are automatically preserved across sudo inside the container.

## Architecture

The script operates in two modes based on `$0`:
1. **Normal mode** - Parses Dockerfile, builds image if needed, runs container
2. **user-command mode** - Runs inside container, creates user matching host UID/GID/group, executes command

User/group mapping preserves host username, UID, GID, and group name. If the group name already exists in the container with a different GID, it's renamed to `${groupname}_${gid}`.

## Testing

Run tests:
```sh
tests/run --all                    # Run all tests
tests/run 0001                     # Run single test by prefix
tests/run 0001 0003                # Run multiple tests
tests/run --no-cleanup --all       # Run all, keep containers for debugging
tests/run --cleanup                # Only cleanup, no tests
```

### Test Structure

Tests live in `tests/NNNN_name/` directories (numbered for ordering):
- `Dockerfile` - Test container definition
- `run` - Symlink to `../../build-and-run`
- `test.sh` - Test script (exit 0 = pass, non-zero = fail)

### Test Cases

- `0001_preserve_env` - Tests ENV vars from Dockerfile are preserved across sudo
- `0002_pragma_platform_aarch64` - Tests `# platform: arm64` runs container on aarch64
- `0003_pragma_platform_amd64` - Tests `# platform: amd64` runs container on x86_64
- `0004_pragma_platform_armv7` - Tests `# platform: arm/v7` runs container on armv7l (Zynq, RPi)
- `0005_user_mapping` - Tests container user matches host UID/GID
- `0006_volume_mount_home` - Tests `$HOME` is accessible inside container
- `0007_volume_mount_pwd` - Tests `$PWD` is accessible inside container
- `0008_pragma_http_static` - Tests `#http.static:` serves files during build
- `0009_tty_absent` - Tests no TTY when run without interactive terminal
- `0010_tty_present` - Tests TTY detected when run with pseudo-terminal
- `0011_pragma_option` - Tests `#option:` passes args to docker run
- `0012_cmdline_env` - Tests `-e` command-line option passes env vars
- `0013_pragma_option_env` - Tests `#option: -e` passes env vars
- `0014_cmdline_options` - Tests common docker options (-v, --network, --cpus)
- `0015_user_mapping_conflict` - Tests group name conflict handling (rename with GID suffix)
