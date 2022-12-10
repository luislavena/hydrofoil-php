# Hydrofoil (PHP)
> Opinionated, PHP environment tailored for development

## Features

* Use Debian as base for dev/prod environment parity (following [Twelve-Factor App][twelve-factor-app])
* Use Docker's official PHP images
* Promote non-root container usage and proper file/directory ownership
* Provide simple tools to certain dev related tasks (Eg. watch changes, process monitoring, etc)
* Be continuously updated using GitHub Actions

This project does **not** aim to:

* Be compatible with [Visual Studio Code devcontainer][devcontainer], [GitHub Codespaces][codespaces] or similar
* Be _everything but the kitchen sink_

## Overview

This project aims to be used **only for development**, replacing the local
installation of tools for something consistent across OS and configurations.

It includes a base set of PHP extensions for development of average web 
applications, specially for using frameworks like Laravel and
[Twill CMS][twill-cms], leaving to you the option to add additional
ones by using the offered image as base.

To be a functional image, it includes the following packages:

* [Composer](https://getcomposer.org/): PHP defacto package manager, aligned with PHP releases
* [NodeJS](https://nodejs.org/en/): the LTS version at the moment that aligned with PHP's release (Eg. v14 for PHP 7.4, v16 for PHP 8.0, etc)
* [pnpm](https://pnpm.io/): alternate NodeJS package manager (recommended by newer tooling like Vue 3, Vite 4, etc)
* [Classic Yarn](https://classic.yarnpkg.com/lang/en/): to allow bootstrapping on projects that haven't switched to Yarn 2

Additionally, it includes the following packages:

* [fixuid](https://github.com/boxboat/fixuid): tweaks container UID/GID to avoid ownership issues on mounted volumes
* [Overmind](https://github.com/DarthSim/overmind): Advanced Procfile-based process manager
* [watchexec](https://github.com/watchexec/watchexec): simple tool that watches a path and runs a command whenever it detects modifications

## Support matrix

This project will continuously build container images only for the supported
versions listed below:

| Status      | Versions |
| ----------- | -------- |
| Supported   | [![](https://img.shields.io/static/v1?label=&message=8.2&color=green)](https://github.com/luislavena/hydrofoil-php/pkgs/container/hydrofoil-php) [![](https://img.shields.io/static/v1?label=&message=8.1&color=green)](https://github.com/luislavena/hydrofoil-php/pkgs/container/hydrofoil-php) [![](https://img.shields.io/static/v1?label=&message=8.0&color=green)](https://github.com/luislavena/hydrofoil-php/pkgs/container/hydrofoil-php) |
| Unsupported | [![](https://img.shields.io/static/v1?label=&message=7.4&color=red)](https://github.com/luislavena/hydrofoil-php/pkgs/container/hydrofoil-php) [![](https://img.shields.io/static/v1?label=&message=7.3&color=red)](https://github.com/luislavena/hydrofoil-php/pkgs/container/hydrofoil-php) |

Note that unsupported means no new builds will be produced for these versions
as those might have reached EOL (End Of Life) support by PHP developers.

## Requirements

The container images can be used directly with [Docker][docker], but is
recommended to use in combination with [docker-compose][docker-compose].

See below for usage examples.

## Usage

To take full advantage of this container image, you need to adjust your
[`docker-compose.yml`][docker-compose-yml] primary service to use it:

```yaml
services:
  app:
    image: ghcr.io/luislavena/hydrofoil-php:8.2
    command: overmind start -f Procfile.dev
    working_dir: /app

    # Set these env variables using `export FIXUID=$(id -u) FIXGID=$(id -g)`
    user: ${FIXUID:-1000}:${FIXGID:-1000}

    volumes:
      - .:/app:cached
```

Let's break down each element:

```yaml
command: overmind start -f Procfile.dev
```

The container will execute Overmind process manager and start the processes
indicated in the `Procfile.dev` file.

```yaml
working_dir: /app
```

It adjusts the container working directory to be anything other than the
default. This `/app` location will be used to _mount_ our application code.

```yaml
user: ${FIXUID:-1000}:${FIXGID:-1000}
```

This sets the user that will be used within the container to something other
than `root`. A sudoers `user` has been setup and this instructions uses
Docker's compose [variable substitution][variable-substitution] to read your
current user's UID/GID values and map correctly to the container user.

This technique helps eliminate root/non-root permission issues when working
with mounted directories.

Is recommended you `export` these two variables (perhaps in your
bash profile):

```bash
export FIXUID=$(id -u) FIXGID=$(id -g)
```

Finally, we have the mounted directories:

```yaml
volumes:
  .:/app:cached
```

This mounts your current directory as `/app` within the container. Combined
with `working_dir` makes it the working directory for all operations.

### Other examples

For a complete example on how this is being used, check out the
[Laravel + Twill][laravel-twill] template repository.

## Contribution Policy

This project is open to code contributions for bug fixes only. Features carry
a long-term maintenance burden so they will not be accepted at this time.
Please [submit an issue][new-issue] if you have a feature you'd like to
request or discuss.

[twelve-factor-app]: https://12factor.net/dev-prod-parity
[devcontainer]: https://code.visualstudio.com/docs/remote/containers
[codespaces]: https://github.com/features/codespaces
[twill-cms]: https://twill.io
[new-issue]: https://github.com/luislavena/hydrofoil-php/issues/new
[docker]: https://docs.docker.com/get-docker/
[docker-compose]: https://docs.docker.com/compose/
[docker-compose-yml]: https://docs.docker.com/compose/compose-file/compose-file-v3/
[variable-substitution]: https://docs.docker.com/compose/compose-file/compose-file-v3/#variable-substitution
[laravel-twill]: https://github.com/luislavena/template-laravel-twill
