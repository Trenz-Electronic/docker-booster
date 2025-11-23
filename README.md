# docker-booster

[![Test Suite](https://github.com/Trenz-Electronic/docker-booster/actions/workflows/test.yml/badge.svg)](https://github.com/Trenz-Electronic/docker-booster/actions/workflows/test.yml)

Run your Docker containers, old or new, painlessly from the command line by forgetting about:

- **User/group mapping** - No more permission headaches with mounted volumes
- **Volume mounting** - Your files and folders are available as if container were your home
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

**Caveat:** Changes to files in directories served by `#http.static:` do not trigger automatic rebuilds. Use `docker rmi <image-name>` to force a rebuild.

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
- Automatically rebuilds the image when detecting changes to Dockerfile and build context using the hash stored as a label in the Docker image

## One very important caveat

Almost last, but not least.

Very important: The automatic volume mapping, which makes it incredibly easy to use, can also be very dangerous when you have no control or little control over the Docker containers. The whole point of Docker container is to isolate, and, people are relying on it. However, having your home directory mounted inside your docker container exposes your data to everything inside the container. Be aware what are you using it to run.

## Testing

Run `tests/run --all` to execute the test suite. See `CLAUDE.md` for details.

### Features not covered by tests

- `/mnt/*` volume mounting (requires root access to `/mnt`)

## TODO

1. How to specify that the $HOME is not to be mounted, but $PWD only? #nohome:true or #home:true? People would probably prefer the more safe option. Better ideas - search for the .git directory?

## License

MIT License - See [LICENSE](LICENSE) for details.
