# docker-booster

Integrate Docker containers seamlessly into your development workflow by forgetting about:

- **User/group mapping** - No more permission headaches with mounted volumes
- **Volume mounting** - Your files and folders are automatically available
- **Image management** - Containers are built automatically when needed
- **TTY handling** - Interactive sessions just work
- **Docker compatibility** - Use familiar docker run options directly

docker-booster handles all of this automatically.

## Boosted Dockerfile Syntax

Your Dockerfiles gain new powers via simple comment pragmas:

- **Cross-platform builds** - Specify target CPU architecture, with transparent QEMU emulation
- **External file access** - Include files outside the build context via automatic HTTP serving
- **Docker options** - Pass network, device, resource limits and other docker run flags

## Installation

Add docker-booster as a submodule to your project:

```bash
git submodule add https://github.com/Trenz-Electronic/docker-booster.git docker-booster
```

Or clone it directly:

```bash
git clone https://github.com/Trenz-Electronic/docker-booster.git
```

## Quick Start

1. **Create a container directory** with your desired name:
   ```bash
   mkdir -p containers/my-container
   ```

2. **Add a Dockerfile**:
   ```bash
   echo 'FROM ubuntu:22.04' > containers/my-container/Dockerfile
   ```

3. **Create a symlink** to the build-and-run script:
   ```bash
   cd containers/my-container && ln -s ../../docker-booster/build-and-run run
   ```

4. **Run commands** inside the container:
   ```bash
   # verify that the local directory is mapped by listing the files
   ./containers/my-container/run ls -l .
   # verify my user inside the container
   ./containers/my-container/run whoami
   # only now start the build, which might invoke foreign CPU architecture compilers with QEMU fully automatically.
   ./containers/my-container/run make -j$(nproc)
   ```

The image will be built automatically on first run, get accustomed to it.

**Important:** Create your container directories in your project (not inside the `docker-booster/` submodule) so they can be version-controlled with your code.


## Dockerfile Directives

docker-booster extends Dockerfiles with special comment directives.

### Platform Selection

Specify the target platform in the first 10 lines:

```dockerfile
# platform: arm64
FROM ubuntu:22.04
```

Supported values: Any Docker platform string (e.g., `arm64`, `amd64`, `linux/arm/v7`, `linux/arm64`)

**Technical note:** Environment variables defined via `ENV` in your Dockerfile are automatically preserved across sudo inside the container - no pragma needed.

This feature can be handy when you want to avoid the hassle of cross-compiling and use native compiling on some foreign CPU architecture. It is very easy to use, but obviously compilation speed suffers significantly.

### HTTP Static File Serving

Serve local directories via HTTP during image builds (useful for large installers):

```dockerfile
#http.static: INSTALLER=/absolute/path/to/installers
FROM ubuntu:22.04

ARG HTTP_INSTALLER
# not the cleanup step - the purpose of this is to keep the docker layers small.
RUN wget ${HTTP_INSTALLER}/large-sdk-installer.run && sh ./large-sdk-installer.run && rm ./large-sdk-installer.run
```

**Note:** Path must be absolute and the directory must exist before build.

The script automatically:
- Starts a temporary HTTP server on a random port
- Passes the URL as `HTTP_<KEY>` build argument
- Cleans up the server after build completes

### Docker options in the Dockerfile

For any options you want to always be present on the command line, use the `#option:` pragma in your Dockerfile:

```dockerfile
#option: --security-opt seccomp=unconfined
#option: --cap-add SYS_PTRACE
#option: --network host
FROM ubuntu:22.04
```

### Docker options on the command line

Pass docker run options directly on the command line:

```bash
./containers/build-env/run -e CC=clang make          # Environment variables
./containers/build-env/run -v /data:/data make       # Volume mounts
./containers/build-env/run -p 8080:80 nginx          # Port mapping
./containers/build-env/run --network host curl ...   # Network mode
./containers/build-env/run --cpus 4 --memory 8g ...  # Resource limits
```

**Supported command-line options:**
- `-e`/`--env` - Environment variables
- `-v`/`--volume` - Volume mounts
- `-p`/`--publish` - Port mapping
- `-w`/`--workdir` - Working directory
- `--network`/`--net` - Network mode
- `--device` - Device access
- `--cpus` - CPU limit
- `-m`/`--memory` - Memory limit
- `--gpus` - GPU access
- `--name` - Container name
- `--privileged`, `--read-only` - Boolean flags

Important: only the above listed options are supported on the command line.

## Project Structure

docker-booster is flexible about where you place your container directories. The recommended structure is:

```
my-project/
├── docker-booster/          # git submodule
│   ├── build-and-run
│   └── ...
├── containers/              # your container definitions
│   ├── build-env/
│   │   ├── Dockerfile
│   │   └── run -> ../../docker-booster/build-and-run
│   └── test-env/
│       ├── Dockerfile
│       └── run -> ../../docker-booster/build-and-run
└── src/
    └── ...
```

**Key points:**
- Place containers in your project, **not** inside the `docker-booster/` submodule
- Use symlinks to point to `build-and-run` from each container directory
- The container name is determined by the directory name
- All containers can share the same `build-and-run` script via symlinks

You can also place containers directly in your project root or use any other directory structure - just adjust the symlink paths accordingly.

## Volume Mounting

Volumes are automatically mounted based on your working directory:

| Working Directory | Mounts |
|-------------------|--------|
| `$HOME/*` | `$HOME` only |
| `/mnt/*` | `/mnt` + `$HOME` |
| Other paths | Current directory + `$HOME` |

## Technical Details

- Creates a temporary user inside the container matching your host UID/GID/group
- Grants sudo access to the created user
- Preserves your working directory inside the container
- Auto-detects TTY for interactive sessions
- Automatically enables Docker BuildKit when Dockerfiles use `RUN --mount` syntax

## Troubleshooting

**Permission Issues**: The script automatically maps your host user/group into the container.

**Platform Mismatches**: Ensure the Dockerfile has the correct `# platform:` directive.

**Build Failures**: Check that the Dockerfile is valid and package repositories are accessible.

**Container Not Found**: Images are built automatically. For manual builds: `docker build -t <name> <directory>`

## Testing

Run `tests/run --all` to execute the test suite. See `CLAUDE.md` for details.

### Features not covered by tests

- `/mnt/*` volume mounting (requires root access to `/mnt`)

## License

MIT License - See [LICENSE](LICENSE) for details.
