# Shared setup for the image tests.
#
# Brat runs top-level code when it plans the tests and again before each
# test, so this file only checks the environment and defines functions.
#
# Each version folder (docker/<version>/test) symlinks the shared tests in
# this folder and keeps only the tests unique to that version.

: "${IMAGE:?set IMAGE to the image to test, eg. IMAGE=ghcr.io/luislavena/hydrofoil-php:8.5}"

# PHP major and minor version the image must run, from the version folder
# that holds the test (docker/8.5/test gives 8.5). Brat sets DIR from the
# path it was given, without following symlinks.
PHP_MAJOR_MINOR="${DIR%/test}"
PHP_MAJOR_MINOR="${PHP_MAJOR_MINOR##*/}"

# Run a command in a new container as the non-root user (uid 1000). This is
# how a devcontainer starts the image, through the fixuid entrypoint.
in_image() {
  docker run --rm -u 1000:1000 "$IMAGE" "$@"
}
