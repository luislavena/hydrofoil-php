# Shared setup for the image tests.
#
# Brat runs top-level code when it plans the tests and again before each
# test, so this file only checks the environment and defines functions.

: "${IMAGE:?set IMAGE to the image to test, eg. IMAGE=ghcr.io/luislavena/hydrofoil-php:8.5}"

# Run a command in a new container as the non-root user (uid 1000). This is
# how a devcontainer starts the image, through the fixuid entrypoint.
in_image() {
  docker run --rm -u 1000:1000 "$IMAGE" "$@"
}
