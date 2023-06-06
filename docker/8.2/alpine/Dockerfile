# syntax = docker/dockerfile:1.3

# ---
# 1. Use Alpine version of PHP (CLI)
FROM php:8.2.6-cli-alpine3.18 AS base

# ---
# 2. Upgrade system and installed dependencies for security patches
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    set -eux; \
    apk upgrade

# ---
# 3. Setup non-root user (fixuid)
#
# TODO: detect arch other than x86_64
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    export \
        USERNAME=user \
    ; \
    # create non-root user & give passwordless sudo
    { \
        apk add sudo; \
        addgroup -g 1000 ${USERNAME}; \
        adduser -u 1000 -G user -h /home/${USERNAME} -s /bin/sh -D ${USERNAME}; \
        mkdir -p /etc/sudoers.d; \
        echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}; \
        # cleanup backup copies
        rm /etc/group- /etc/passwd- /etc/shadow-; \
    }; \
    # Install fixuid
    { \
        cd /tmp; \
        export \
            FIXUID_VERSION=0.5.1 \
            FIXUID_SHA256=1077e7af13596e6e3902230d7260290fe21b2ee4fffcea1eb548e5c465a34800 \
        ; \
        wget -q -O fixuid.tar.gz https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-amd64.tar.gz; \
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
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    apk add \
        curl \
        git \
        openssh-client-default \
        tzdata \
    ;

# ---
# 5. Install PHP extensions and tweak configuration
#
# TODO: enable opcache for CLI
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
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
    # Use `IPE_GD_WITHOUTAVIF=1` to disable gd AVIF support
    #
    # Ref: https://github.com/mlocati/docker-php-extension-installer
    export \
        PHP_EXT_INSTALLER_VERSION=2.1.28 \
        PHP_EXT_INSTALLER_SHA256SUM=dd01cac46b0ad7afbb2f3f4fa2a16ea3140492608f3dfdb52b0ce37891fcc7e5 \
        IPE_GD_WITHOUTAVIF=1 \
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
# 6. Copy NodeJS LTS from official image and Install Yarn
FROM node:18.16.0-alpine3.18 AS nodejs

FROM base
COPY --from=nodejs /usr/local/bin /usr/local/bin/
COPY --from=nodejs /usr/local/include /usr/local/include/
COPY --from=nodejs /usr/local/lib /usr/local/lib/
COPY --from=nodejs /usr/local/share /usr/local/share/

RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
     set -eux; \
     # Install NodeJS dependencies
     { \
        nodeDeps=$( \
            scanelf --needed --nobanner --format '%n#p' /usr/local/bin/node \
                | tr ',' '\n' \
                | sort -u \
                | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        ); \
        apk add --virtual .nodejs-rundeps $nodeDeps; \
     }; \
     # ---
     # pnpm
     { \
        export \
            PNPM_VERSION=7.18.1 \
            PNPM_SHA256=29a51178a23c08c526f05991e23b883134e0c09f043d48ae7a7127bc3f4448d2 \
        ; \
        curl --fail -Lo pnpm-linuxstatic https://github.com/pnpm/pnpm/releases/download/v${PNPM_VERSION}/pnpm-linuxstatic-x64; \
        echo "${PNPM_SHA256} *pnpm-linuxstatic" | sha256sum -c - >/dev/null 2>&1; \
        chmod +x pnpm-linuxstatic; \
        mv pnpm-linuxstatic /usr/local/bin/pnpm; \
     }; \
     # ---
     # Yarn
     { \
        export \
            YARN_VERSION=1.22.19 \
            YARN_SHA256=732620bac8b1690d507274f025f3c6cfdc3627a84d9642e38a07452cc00e0f2e \
        ; \
        curl --fail -Lo yarn.tar.gz https://yarnpkg.com/downloads/${YARN_VERSION}/yarn-v${YARN_VERSION}.tar.gz; \
        echo "${YARN_SHA256} *yarn.tar.gz" | sha256sum -c - >/dev/null 2>&1; \
        tar -xf yarn.tar.gz; \
        mv yarn-v${YARN_VERSION} /usr/local/yarn; \
        ln -sf /usr/local/yarn/bin/yarn /usr/local/bin/yarn; \
        ln -sf /usr/local/yarn/bin/yarnpkg /usr/local/bin/yarnpkg; \
        rm -f yarn.tar.gz; \
     }; \
     # smoke tests
     [ "$(command -v node)" = '/usr/local/bin/node' ]; \
     [ "$(command -v pnpm)" = '/usr/local/bin/pnpm' ]; \
     [ "$(command -v yarn)" = '/usr/local/bin/yarn' ]; \
     node --version; \
     pnpm --version; \
     yarn --version

# ---
# 7. Install other development utilities
#
# TODO: Support arch other than x86_64
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    cd /tmp; \
    # ---
    # Database clients (PostgreSQL, MariaDB/MySQL)
    { \
        apk add \
            mariadb-client \
            postgresql-client \
        ; \
    }; \
    # ---
    # Composer (needs 7z, unzip)
    { \
        apk add \
            7zip \
            unzip \
        ; \
        export \
            COMPOSER_VERSION=2.4.4 \
            COMPOSER_SHA256=c252c2a2219956f88089ffc242b42c8cb9300a368fd3890d63940e4fc9652345; \
        curl --fail -Lo composer.phar https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar; \
        echo "${COMPOSER_SHA256} *composer.phar" | sha256sum -c - >/dev/null 2>&1; \
        chmod +x composer.phar; \
        mv composer.phar /usr/local/bin/composer; \
    }; \
    # ---
    # Overmind (needs tmux)
    { \
        apk add \
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
            WATCHEXEC_VERSION=1.20.6 \
            WATCHEXEC_SHA256=6e746704b61d4a2a467546930a837ceef3a4003fc568e574cf6f43a798a4ab00; \
        curl --fail -Lo watchexec.tar.xz https://github.com/watchexec/watchexec/releases/download/v${WATCHEXEC_VERSION}/watchexec-${WATCHEXEC_VERSION}-x86_64-unknown-linux-musl.tar.xz; \
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
