# docker-booster

Integrate Docker containers seamlessly into your development workflow by forgetting about:

- **User/group mapping** - No more permission headaches with mounted volumes
- **Volume mounting** - Your files and folders are automatically available
- **Image management** - Containers are built automatically when needed
- **TTY handling** - Interactive sessions just work

docker-booster handles all of this automatically.

## Boosted Dockerfile Syntax

Your Dockerfiles gain new powers via simple comment pragmas:

- **Cross-platform builds** - Specify target CPU architecture, with transparent QEMU emulation
- **Environment preservation** - Keep SDK variables available for your mapped user
- **External file access** - Include files outside the build context via automatic HTTP serving

## Installation

Add docker-booster as a submodule to your project:

```bash
git submodule add https://github.com/YOUR_ORG/docker-booster.git docker
```

Or clone it directly:

```bash
git clone https://github.com/YOUR_ORG/docker-booster.git
```

## Quick Start

1. **Create a container directory** with your desired name:
   ```bash
   mkdir docker/my-container
   ```

2. **Add a Dockerfile**:
   ```bash
   echo 'FROM ubuntu:22.04' > docker/my-container/Dockerfile
   ```

3. **Create a symlink** to the build-and-run script:
   ```bash
   cd docker/my-container && ln -s ../build-and-run run
   ```

4. **Run commands** inside the container:
   ```bash
   ./docker/my-container/run bash
   ./docker/my-container/run make
   ./docker/my-container/run python3 script.py
   ```

The image will be built automatically on first run.

## Usage Examples

```bash
# Start interactive bash session
./docker/build-env/run bash

# Run make inside the container
./docker/build-env/run make -j$(nproc)

# Run a specific command
./docker/build-env/run python3 setup.py install
```

## Dockerfile Directives

docker-booster extends Dockerfiles with special comment directives.

### Platform Selection

Specify target platform in the first 10 lines:

```dockerfile
# platform: arm64
FROM ubuntu:22.04
```

Supported values: `arm64`, `amd64`

### Environment Variable Preservation

Preserve environment variables when switching to the mapped user:

```dockerfile
#env: PATH,MY_SDK_ROOT,MY_SDK_VERSION
FROM ubuntu:22.04

ENV MY_SDK_ROOT=/opt/sdk
ENV MY_SDK_VERSION=1.0
ENV PATH="${MY_SDK_ROOT}/bin:${PATH}"
```

### HTTP Static File Serving

Serve local directories via HTTP during image builds (useful for large installers):

```dockerfile
#http.static: INSTALLER=/path/to/local/installers
FROM ubuntu:22.04

ARG HTTP_INSTALLER
RUN wget ${HTTP_INSTALLER}/large-sdk-installer.run && ./large-sdk-installer.run
```

The script automatically:
- Starts a temporary HTTP server on a random port
- Passes the URL as `HTTP_<KEY>` build argument
- Cleans up the server after build completes

## Volume Mounting

Volumes are automatically mounted based on your working directory:

| Working Directory | Mounts |
|-------------------|--------|
| `$HOME/*` | `$HOME` only |
| `/mnt/*` | `/mnt` + `$HOME` |
| Other paths | Current directory + `$HOME` |

## Technical Details

- Creates a temporary user inside the container matching your host UID/GID
- Grants sudo access to the created user
- Preserves your working directory inside the container
- Auto-detects TTY for interactive sessions
- Enables BuildKit automatically when Dockerfiles use `RUN --mount` syntax

## Troubleshooting

**Permission Issues**: The script automatically maps your host user/group into the container.

**Platform Mismatches**: Ensure the Dockerfile has the correct `# platform:` directive.

**Build Failures**: Check that the Dockerfile is valid and package repositories are accessible.

**Container Not Found**: Images are built automatically. For manual builds: `docker build -t <name> <directory>`

## License

MIT License - See [LICENSE](LICENSE) for details.
