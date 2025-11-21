FROM alpine:latest
RUN apk add --no-cache sudo
# Use BuildKit --mount syntax to trigger auto-detection
RUN --mount=type=tmpfs,target=/tmp echo "BuildKit enabled" > /tmp/test
