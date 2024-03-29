# syntax = docker/dockerfile:1.3

# ---
# 1. Use Debian 11 (bullseye) version of PHP
FROM php:7.4.30-cli-bullseye AS base

# ---
# 2. Upgrade system and installed dependencies for security patches
#
# Also enable to keep copies of downloaded packages for faster rebuilds
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/log \
    set -eux; \
    apt-get update; \
    apt-get upgrade -y

# ---
# 3. Setup non-root user (fixuid)
#
# TODO: detect arch other than x86_64
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/log \
    set -eux; \
    export USERNAME=user; \
    # install needed packages
    { \
      apt-get update; \
      apt-get install --no-install-recommends -y \
          sudo \
      ; \
    }; \
    # create non-root user & give passwordless sudo
    { \
        groupadd --gid 1000 ${USERNAME}; \
        useradd --uid 1000 --gid 1000 --home-dir /home/${USERNAME} --create-home --shell /bin/bash ${USERNAME}; \
        mkdir -p /etc/sudoers.d; \
        echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}; \
        # cleanup backup copies generated by `groupadd` and `useradd`
        rm -f \
          /etc/gshadow- \
          /etc/subgid- \
          /etc/subuid- \
        ; \
    }; \
    # Install fixuid
    { \
        cd /tmp; \
        export FIXUID_VERSION=0.5.1 \
            FIXUID_SHA256=1077e7af13596e6e3902230d7260290fe21b2ee4fffcea1eb548e5c465a34800; \
        curl --fail -Lo fixuid.tar.gz https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-amd64.tar.gz; \
        echo "${FIXUID_SHA256} *fixuid.tar.gz" | sha256sum -c - >/dev/null 2>&1; \
        tar -xf fixuid.tar.gz; \
        mv fixuid /usr/local/bin/; \
        chmod u+s /usr/local/bin/fixuid; \
        rm fixuid.tar.gz; \
    }; \
    # Generate fixuid config
    mkdir -p /etc/fixuid; \
    { \
        echo "user: ${USERNAME}"; \
        echo "group: ${USERNAME}"; \
    } | tee /etc/fixuid/config.yml

# Adjust ENTRYPOINT
ENTRYPOINT [ "/usr/local/bin/fixuid", "-q" ]
CMD [ "/bin/bash", "-i" ]

# ---
# 4. Install dependencies and common packages
#
# TODO
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/log \
    set -eux; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
        git \
        openssh-client \
        tzdata \
    ;

# ---
# 5. Install PHP extensions and tweak configuration
#
# ---
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/log \
    set -eux; \
    # ---
    # Configure PHP in development mode
    cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"; \
    # ---
    # Use `docker-php-ext-install` to ease installation of PHP
    # extensions
    #
    # Ref: https://github.com/mlocati/docker-php-extension-installer
    export \
      PHP_EXT_INSTALLER_VERSION=1.5.46 \
      PHP_EXT_INSTALLER_SHA256SUM=471423f98535ea97b5108100c3096a3546019311e3fc8be58bec834329e723cb \
    ; \
    cd /tmp; \
    { \
      curl --fail -Lo install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/download/${PHP_EXT_INSTALLER_VERSION}/install-php-extensions; \
      echo "${PHP_EXT_INSTALLER_SHA256SUM} *install-php-extensions" | sha256sum -c - >/dev/null 2>&1; \
      chmod +x install-php-extensions; \
    }; \
    # ---
    # Install common PHP extensions
    #
    # (no need to install mbstring, pdo, tokenizer or xml as they are already part of base image)
    ./install-php-extensions \
      bcmath \
      blackfire \
      calendar \
      exif \
      gd \
      intl \
      memcached-stable \
      pcntl \
      pdo_mysql \
      pdo_pgsql \
      redis-stable \
      sockets \
      xdebug-stable \
      xsl \
      zip \
    ; \
    # opcache already installed, just enable extension
    docker-php-ext-enable opcache; \
    # remove PHP extension installer
    rm -f ./install-php-extensions

# ---
# 6. Install NodeJS LTS and Yarn
#
# TODO: Support arch other than x86_64
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/log \
    set -eux; \
    cd /tmp; \
    # ---
    # NodeJS (needs python3 for installing extensions)
    #
    # Use NodeSource debian package directly from their repository
    # Ref: https://deb.nodesource.com/node_16.x/pool/main/n/nodejs/
    { \
      apt-get update; \
      apt-get install --no-install-recommends -y \
          python3-minimal \
      ; \
      export \
        NODEJS_MAJOR=14 \
        NODEJS_VERSION=14.21.1 \
        NODEJS_SHA256=6a3f087ad2e363f1c05dc4e1bc4748d90ffebdbe552d4b06b18b5e09b55b934b \
      ; \
      curl --fail -Lo nodejs.deb https://deb.nodesource.com/node_${NODEJS_MAJOR}.x/pool/main/n/nodejs/nodejs_${NODEJS_VERSION}-deb-1nodesource1_amd64.deb; \
      echo "${NODEJS_SHA256} *nodejs.deb" | sha256sum -c - >/dev/null 2>&1; \
      dpkg --install nodejs.deb; \
      rm -f nodejs.deb; \
    }; \
    # ---
    # Yarn
    { \
      export \
        YARN_VERSION=1.22.19 \
        YARN_SHA256=666cc8c015bb9e36236fc355816711fbc88bbba97ce8344d3ea2a36debcf7424 \
      ; \
      curl --fail -Lo yarn.deb https://github.com/yarnpkg/yarn/releases/download/v${YARN_VERSION}/yarn_${YARN_VERSION}_all.deb; \
      echo "${YARN_SHA256} *yarn.deb" | sha256sum -c - >/dev/null 2>&1; \
      dpkg --install yarn.deb; \
      rm -f yarn.deb; \
    }; \
    # smoke tests
    [ "$(command -v node)" = '/usr/bin/node' ]; \
    [ "$(command -v yarn)" = '/usr/bin/yarn' ]; \
    node --version; \
    yarn --version

# ---
# 7. Install other development utilities
#
# TODO: Support arch other than x86_64
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/log \
    set -eux; \
    cd /tmp; \
    # ---
    # Database clients (PostgreSQL, MariaDB/MySQL)
    { \
        apt-get update; \
        apt-get install --no-install-recommends -y \
            mariadb-client \
            postgresql-client \
        ; \
    }; \
    # ---
    # Composer (needs 7z, unzip)
    { \
        apt-get update; \
        apt-get install --no-install-recommends -y \
            p7zip-full \
            unzip \
        ; \
        export \
            COMPOSER_VERSION=1.10.26 \
            COMPOSER_SHA256=cbfe1f85276c57abe464d934503d935aa213494ac286275c8dfabfa91e3dbdc4; \
        curl --fail -Lo composer.phar https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar; \
        echo "${COMPOSER_SHA256} *composer.phar" | sha256sum -c - >/dev/null 2>&1; \
        chmod +x composer.phar; \
        mv composer.phar /usr/local/bin/composer; \
    }; \
    # ---
    # Overmind (needs tmux)
    { \
        apt-get update; \
        apt-get install --no-install-recommends -y \
            tmux \
        ; \
        export \
            OVERMIND_VERSION=2.3.0 \
            OVERMIND_SHA256=d6a715c0810ceb39c94bf61843befebe04a83a0469b53d6af0a52e2fea4e2ab3; \
        curl --fail -Lo overmind.gz https://github.com/DarthSim/overmind/releases/download/v${OVERMIND_VERSION}/overmind-v${OVERMIND_VERSION}-linux-amd64.gz; \
        echo "${OVERMIND_SHA256} *overmind.gz" | sha256sum -c - >/dev/null 2>&1; \
        gunzip overmind.gz; \
        chmod +x overmind; \
        mv overmind /usr/local/bin/; \
    }; \
    # ---
    # Watchexec
    { \
        export \
            WATCHEXEC_VERSION=1.20.5 \
            WATCHEXEC_SHA256=33e091870736833b77b103a8e7268c0ae66d756b8d71203405353eb9d40774f2; \
        curl --fail -Lo watchexec.tar.xz https://github.com/watchexec/watchexec/releases/download/cli-v${WATCHEXEC_VERSION}/watchexec-${WATCHEXEC_VERSION}-x86_64-unknown-linux-musl.tar.xz; \
        echo "${WATCHEXEC_SHA256} *watchexec.tar.xz" | sha256sum -c - >/dev/null 2>&1; \
        tar -xf watchexec.tar.xz; \
        mv watchexec-${WATCHEXEC_VERSION}-x86_64-unknown-linux-musl/watchexec /usr/local/bin/; \
        rm -rf watchexec.tar.xz watchexec-${WATCHEXEC_VERSION}-x86_64-unknown-linux-musl; \
    }; \
    # smoke tests
    [ "$(command -v composer)" = '/usr/local/bin/composer' ]; \
    [ "$(command -v overmind)" = '/usr/local/bin/overmind' ]; \
    [ "$(command -v watchexec)" = '/usr/local/bin/watchexec' ]; \
    composer --version; \
    overmind --version; \
    watchexec --version
