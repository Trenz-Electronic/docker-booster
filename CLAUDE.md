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
| `#env: VAR1,VAR2` | First 20 lines | Preserve env vars across sudo |
| `#http.static: KEY=/path` | First 20 lines | Serve local dirs during build |

## Architecture

The script operates in two modes based on `$0`:
1. **Normal mode** - Parses Dockerfile, builds image if needed, runs container
2. **user-command mode** - Runs inside container, creates user matching host UID/GID, executes command

## Testing

No automated tests. Test manually by:
1. Creating a test container directory with a simple Dockerfile
2. Symlinking `build-and-run` as `run`
3. Running commands and verifying behavior
