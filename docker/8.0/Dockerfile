# syntax = docker/dockerfile:1.3

# ---
# 1. Use Debian 11 (bullseye) version of PHP
FROM php:8.0.30-cli-bullseye AS base

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
        export FIXUID_VERSION=0.5.1; \
        case "$(arch)" in \
        x86_64) \
            export \
                FIXUID_ARCH=amd64 \
                FIXUID_SHA256=1077e7af13596e6e3902230d7260290fe21b2ee4fffcea1eb548e5c465a34800 \
            ; \
            ;; \
        aarch64) \
            export \
                FIXUID_ARCH=arm64 \
                FIXUID_SHA256=7993a03876f5151c450e68a49706ef4c80d6b0ab755679eb47282df7f162fd82 \
            ; \
            ;; \
        esac; \
        curl --fail -Lo fixuid.tar.gz https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-${FIXUID_ARCH}.tar.gz; \
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
# TODO: enable opcache for CLI
RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
    --mount=type=cache,sharing=private,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/log \
    set -eux; \
    # ---
    # Configure PHP in development mode
    cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"; \
    # ---
    # Additional tweaks for development
    { \
        echo "memory_limit=512M"; \
    } | tee $PHP_INI_DIR/conf.d/zz-hydrofoil-tweaks.ini; \
    # ---
    # Use `docker-php-ext-install` to ease installation of PHP
    # extensions
    #
    # Ref: https://github.com/mlocati/docker-php-extension-installer
    export \
      PHP_EXT_INSTALLER_VERSION=2.1.55 \
      PHP_EXT_INSTALLER_SHA256SUM=97eca1e1efb1c19bc74ebf12737cebab1c789b83e2051aaee7e90b2636c4b075 \
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
      redis-5.3.7 \
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
          python3 \
      ; \
      export \
        NODEJS_MAJOR=18 \
        NODEJS_VERSION=18.18.0 \
      ; \
      case "$(arch)" in \
      x86_64) \
          export \
              NODEJS_ARCH=amd64 \
              NODEJS_SHA256=e9c392f8dc3513b6a700f8e01fcf522ca8c1d4edc121c7c0b06206799d0dbe93 \
          ; \
          ;; \
      aarch64) \
          export \
              NODEJS_ARCH=arm64 \
              NODEJS_SHA256=4deeaedecbc44d1b4c1bb013017cc02e0daca9caa1cf2ad8e9288548d95e6621 \
          ; \
          ;; \
      esac; \
      curl --fail -Lo nodejs.deb https://deb.nodesource.com/node_${NODEJS_MAJOR}.x/pool/main/n/nodejs/nodejs_${NODEJS_VERSION}-1nodesource1_${NODEJS_ARCH}.deb; \
      echo "${NODEJS_SHA256} *nodejs.deb" | sha256sum -c - >/dev/null 2>&1; \
      dpkg --install nodejs.deb; \
      rm -f nodejs.deb; \
    }; \
    # ---
    # pnpm
    { \
      export \
        PNPM_VERSION=7.33.3 \
      ; \
      case "$(arch)" in \
      x86_64) \
          export \
              PNPM_ARCH=x64 \
              PNPM_SHA256=23bbc4c73d88ce7c73937be927c15f0ea64cd925d149ddf77fb83602cc242e13 \
          ; \
          ;; \
      aarch64) \
          export \
              PNPM_ARCH=arm64 \
              PNPM_SHA256=ae17a95dfa70ab0fe0151d8626081e768892fd19652d4c5173cf1764edaf26d4 \
          ; \
          ;; \
      esac; \
      curl --fail -Lo pnpm-linuxstatic https://github.com/pnpm/pnpm/releases/download/v${PNPM_VERSION}/pnpm-linuxstatic-${PNPM_ARCH}; \
      echo "${PNPM_SHA256} *pnpm-linuxstatic" | sha256sum -c - >/dev/null 2>&1; \
      chmod +x pnpm-linuxstatic; \
      mv pnpm-linuxstatic /usr/local/bin/pnpm; \
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
    [ "$(command -v pnpm)" = '/usr/local/bin/pnpm' ]; \
    [ "$(command -v yarn)" = '/usr/bin/yarn' ]; \
    node --version; \
    pnpm --version; \
    yarn --version

# ---
# 7. Install other development utilities
#
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
            COMPOSER_VERSION=2.5.8 \
            COMPOSER_SHA256=f07934fad44f9048c0dc875a506cca31cc2794d6aebfc1867f3b1fbf48dce2c5; \
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
            OVERMIND_VERSION=2.4.0 \
        ; \
        case "$(arch)" in \
        x86_64) \
            export \
                OVERMIND_ARCH=amd64 \
                OVERMIND_SHA256=1f7cac289b550a71bebf4a29139e58831b39003d9831be59eed3e39a9097311c \
            ; \
            ;; \
        aarch64) \
            export \
                OVERMIND_ARCH=arm64 \
                OVERMIND_SHA256=94a3e8393bd718ae9ec1b6cc21740bffa52da20710eaf020a7aa679cdc926104 \
            ; \
            ;; \
        esac; \
        curl --fail -Lo overmind.gz https://github.com/DarthSim/overmind/releases/download/v${OVERMIND_VERSION}/overmind-v${OVERMIND_VERSION}-linux-${OVERMIND_ARCH}.gz; \
        echo "${OVERMIND_SHA256} *overmind.gz" | sha256sum -c - >/dev/null 2>&1; \
        gunzip overmind.gz; \
        chmod +x overmind; \
        mv overmind /usr/local/bin/; \
    }; \
    # ---
    # Watchexec
    { \
        export \
            WATCHEXEC_VERSION=1.21.1 \
        ; \
        case "$(arch)" in \
        x86_64) \
            export \
                WATCHEXEC_ARCH=x86_64 \
                WATCHEXEC_SHA256=807c05bf02dbe77b19e2acbfa9860ccbfcc0a3972fbf984f5b664b1ba5ef4f98 \
            ; \
            ;; \
        aarch64) \
            export \
                WATCHEXEC_ARCH=aarch64 \
                WATCHEXEC_SHA256=ebd3c97178eda2806e0e02149503269179cec09b95bdd2700de10a4eea54852b \
            ; \
            ;; \
        esac; \
        curl --fail -Lo watchexec.tar.xz https://github.com/watchexec/watchexec/releases/download/v${WATCHEXEC_VERSION}/watchexec-${WATCHEXEC_VERSION}-${WATCHEXEC_ARCH}-unknown-linux-musl.tar.xz; \
        echo "${WATCHEXEC_SHA256} *watchexec.tar.xz" | sha256sum -c - >/dev/null 2>&1; \
        tar -xf watchexec.tar.xz; \
        mv watchexec-${WATCHEXEC_VERSION}-${WATCHEXEC_ARCH}-unknown-linux-musl/watchexec /usr/local/bin/; \
        rm -rf watchexec.tar.xz watchexec-${WATCHEXEC_VERSION}-${WATCHEXEC_ARCH}-unknown-linux-musl; \
    }; \
    # smoke tests
    [ "$(command -v composer)" = '/usr/local/bin/composer' ]; \
    [ "$(command -v overmind)" = '/usr/local/bin/overmind' ]; \
    [ "$(command -v watchexec)" = '/usr/local/bin/watchexec' ]; \
    composer --version; \
    overmind --version; \
    watchexec --version
