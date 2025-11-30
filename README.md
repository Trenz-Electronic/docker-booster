# docker-booster

[![Test Suite](https://github.com/Trenz-Electronic/docker-booster/actions/workflows/test.yml/badge.svg)](https://github.com/Trenz-Electronic/docker-booster/actions/workflows/test.yml)

Run your Docker containers, command line or GUI, painlessly from the command line by forgetting about:

- **User/group mapping** - No more permission headaches with mounted volumes
- **Volume mounting** - Your project files are automatically available
- **Image management** - Containers are built and rebuilt automatically as needed
- **TTY handling** - Interactive sessions just work
- **Common options** - Do not type them every time, tuck them away in the Dockerfile
- **Cross-compiling complications** - Build successfully on first try with native compilers and zero effort
- **Large source files outside build context** - Easily incorporated into your Dockerfile

docker-booster handles all of this automatically, virtually converting your Dockerfiles into ready to run applications.

Sounds complicated? When confused, you can still use your familiar docker run options directly on the command line.

## Quick Start

Follow these steps

1. **Create a container directory** with your desired name and Dockerfile
   ```bash
   mkdir -p containers/my-container
   echo 'FROM ubuntu:22.04' > containers/my-container/Dockerfile
   ```

2. **Add docker-booster** as a submodule to your project:
   ```bash
   git submodule add https://github.com/Trenz-Electronic/docker-booster.git docker-booster
   ```
   Or clone it directly:
   ```bash
   git clone https://github.com/Trenz-Electronic/docker-booster.git
   ```

3. **Create a symlink** to the build-and-run script:
   ```bash
   cd containers/my-container && ln -s ../../docker-booster/build-and-run run
   ```
   This is the crucial step. The docker-booster follows this link back to your docker context directory in order to be able to perform its automation magic.

4. **Reap the benefits** by running commands inside the container with no command line wizardry:
   ```bash
   # verify that the local directory is mapped by listing the files
   ./containers/my-container/run ls -l .
   # verify my user inside the container
   ./containers/my-container/run whoami
   # verify the CPU architecture the container is running on:
   ./containers/my-container/run uname -m
   # only now start the build, which might invoke foreign CPU architecture compilers with QEMU fully automatically.
   ./containers/my-container/run make -j$(nproc)
   ```

The image will be built automatically on the first run and rebuilt upon Dockerfile changes, get accustomed to it.

**Important:** Create your container directories in your project (not inside the `docker-booster/` submodule) so they can be version-controlled with your code.

You are starting to see, it is everything a lazy developer can wish for.

## Docker options on the command line

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

## Dockerfile Directives

docker-booster extends Dockerfiles with special comment directives.

### Docker options in the Dockerfile

For any options you want to always be present on the command line, but don't bother to type them in every time, use the `#option:` pragma in your Dockerfile:

```dockerfile
#option: --security-opt seccomp=unconfined
#option: --cap-add SYS_PTRACE
#option: --network host
FROM ubuntu:22.04
```

### Fine-tune volume mapping

The default behaviour of docker-booster is to search for the root of the git repository and volume mount it; failing that, it will volume mount the current directory. The default behaviour corresponds to the directive "#mount: .git pwd" and it is already pretty sensible.

The directive "#mount" accepts a list of one of the following:
- `.git` - Root of the git repository (searches upward from current directory)
- `pwd` - Current working directory
- `home` - Home directory, do not use with untrusted containers
The list is searched and the first available directory will be mounted; if none are available, it will exit with error.

**Example**: Restrict container to git repository only, to avoid any security lapses:
```dockerfile
#mount: .git
FROM ubuntu:22.04
# Only git repo is mounted, not entire $HOME
```

Multiple #mount directives are also supported. Duplicates detected will be silently skipped.

### Select the files to be in your home directory

To have files copied over to your home directory in the container, use the "#copy.home:" directive. It takes just a single path to a file relative to your home directory. For multiple files, simply use the directive multiple times.

In this example, there are two license files copied over using #copy.home:
```dockerfile
#copy.home: .license.dat
#copy.home: .config/my-tool/license.json
FROM ubuntu:22.04
```

Please note that changes made to these files in the container will not be reflected in the host system.

Should the files not exist, it is an error.

### Platform Selection

Specify the target platform in the first 10 lines:

```dockerfile
# platform: arm64
FROM ubuntu:22.04
```

Supported values: Any Docker platform string (e.g., `arm64`, `amd64`, `linux/arm/v7`, `linux/arm64`)

This feature can be handy when you want to avoid the hassle of cross-compiling and use native compiling on some foreign CPU architecture. It is very easy to use, but note that compilation speed will be significantly slower.

### HTTP Static File Serving

Serve local directories via HTTP during image builds (useful for large installers):

```dockerfile
#http.static: INSTALLER=../installers
FROM ubuntu:22.04

ARG HTTP_INSTALLER
# note the cleanup step - the purpose of this is to keep the docker layers small.
RUN wget ${HTTP_INSTALLER}/large-sdk-installer.run && sh ./large-sdk-installer.run && rm ./large-sdk-installer.run
```

**Note:** Relative paths are resolved from the Dockerfile's directory. The directory must exist before build.

The script automatically:
- Starts a temporary HTTP server on a random port
- Passes the URL as `HTTP_<KEY>` build argument
- Cleans up the server after build completes

**Caveat:** Changes to files in directories served by `#http.static:` do not trigger automatic rebuilds. Use `docker rmi <image-name>` to force a rebuild.

### Sudo Configuration

If you need `sudo` access inside the container, use the `#sudo:` directive and make sure sudo has been installed, as in the following example:

```dockerfile
#sudo: all
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y sudo
```

With `#sudo: all`, docker-booster creates a sudoers entry allowing passwordless sudo for the container user. Without this directive, even if sudo is installed, it won't be configured for the container user.

### GUI Applications (X11)

docker-booster can run X11 applications with minimal configuration:

```dockerfile
# X11 Application Container
#copy.home: .Xauthority
#option: -e DISPLAY=$DISPLAY
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    x11-apps \
    freecad \
    kicad \
    && rm -rf /var/lib/apt/lists/*

# FreeCAD alone installs ~150 packages and 500MB of dependencies!
```

Usage:
```bash
# Test with simple X11 app
./containers/x11-apps/run xclock

# Run FreeCAD for mechanical design
./containers/x11-apps/run freecad

# Run KiCad for PCB design
./containers/x11-apps/run kicad
```

**Why `#copy.home: .Xauthority`?** This securely copies only the X11 authentication file instead of mounting your entire home directory, following the principle of least privilege.

## Project Structure

docker-booster is flexible about where you place your container directories. The example structure, which is in no way enforced, is:

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

As long as symlinks in your docker containers point to your docker-booster/build-and-run script, it works.

## Technical Details

- Creates a temporary user inside the container matching your host UID/GID/group
- Uses `su` for privilege de-escalation (no sudo requirement)
- Optionally configures sudoers with `#sudo: all` directive
- Preserves your working directory inside the container
- Auto-detects TTY for interactive sessions
- Automatically enables Docker BuildKit when Dockerfiles use `RUN --mount` syntax
- Automatically rebuilds the image when detecting changes to Dockerfile and build context using the hash stored as a label in the Docker image

## Security Considerations

docker-booster is **secure by default**:

- ✅ No $HOME exposure - SSH keys, GPG keys, AWS credentials stay protected
- ✅ Git-aware - automatically mounts only your repository root
- ✅ Minimal access - falls back to current directory if not in git repo

**When you need $HOME access** (e.g., for shell configurations, SSH keys):

```dockerfile
#mount: home
FROM ubuntu:22.04
```

**When you need specific files only** (most secure):

```dockerfile
#copy.home: .license.dat
#copy.home: .ssh/config
FROM ubuntu:22.04
```

The default behavior makes docker-booster safe for CI/CD pipelines and untrusted containers without any configuration.

## Testing

Run `tests/run --all` to execute the test suite. See `CLAUDE.md` for details.

## License

MIT License - See [LICENSE](LICENSE) for details.
