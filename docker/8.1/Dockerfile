# syntax = docker/dockerfile:1.3

# ---
# 0. Version of NodeJS to use
FROM node:16.18.1-alpine3.16 AS nodejs

# ---
# 1. Use Alpine version of PHP (CLI)
FROM php:8.1.12-cli-alpine3.16 AS base

# ---
# 2. Upgrade system and installed dependencies for security patches
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    set -eux; \
    apk upgrade

# ---
# 4. Setup non-root user (fixuid)
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    # create non-root user & give passwordless sudo
    { \
        apk add sudo; \
        addgroup -g 1000 user; \
        adduser -u 1000 -G user -h /home/user -s /bin/sh -D user; \
        mkdir -p /etc/sudoers.d; \
        echo "user ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user; \
        # cleanup backup copies
        rm /etc/group- /etc/passwd- /etc/shadow-; \
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
        wget -q -O fixuid.tar.gz https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-${FIXUID_ARCH}.tar.gz; \
        echo "${FIXUID_SHA256} *fixuid.tar.gz" | sha256sum -c - >/dev/null 2>&1; \
        tar -xf fixuid.tar.gz; \
        mv fixuid /usr/local/bin/; \
        chmod u+s /usr/local/bin/fixuid; \
        rm fixuid.tar.gz; \
    }; \
    # Generate fixuid config
    mkdir -p /etc/fixuid; \
    { \
        echo "user: user"; \
        echo "group: user"; \
    } | tee /etc/fixuid/config.yml

# Adjust ENTRYPOINT
ENTRYPOINT [ "/usr/local/bin/fixuid", "-q" ]
CMD [ "/bin/sh" ]

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
      PHP_EXT_INSTALLER_VERSION=1.5.46 \
      PHP_EXT_INSTALLER_SHA256SUM=471423f98535ea97b5108100c3096a3546019311e3fc8be58bec834329e723cb \
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
# 6. Copy NodeJS LTS and install Yarn
#

COPY --from=nodejs /usr/local/bin /usr/local/bin/
COPY --from=nodejs /usr/local/include /usr/local/include/
COPY --from=nodejs /usr/local/lib /usr/local/lib/
COPY --from=nodejs /usr/local/share /usr/local/share/

RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    # ---
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
    [ "$(command -v yarn)" = '/usr/local/bin/yarn' ]; \
    node --version; \
    yarn --version

# TODO: Support arch other than x86_64
# RUN --mount=type=cache,sharing=private,target=/var/cache/apt \
#     --mount=type=cache,sharing=private,target=/var/lib/apt \
#     --mount=type=tmpfs,target=/var/log \
#     set -eux; \
#     cd /tmp; \
#     # ---
#     # NodeJS (needs python3 for installing extensions)
#     #
#     # Use NodeSource debian package directly from their repository
#     # Ref: https://deb.nodesource.com/node_16.x/pool/main/n/nodejs/
#     { \
#       apt-get update; \
#       apt-get install --no-install-recommends -y \
#           python3-minimal \
#       ; \
#       export \
#         NODEJS_MAJOR=16 \
#         NODEJS_VERSION=16.18.1 \
#         NODEJS_SHA256=abf9b58c57192127614f6ff46bb8ca842e78d8b9d14b3247d0d34871dcc8aa0c \
#       ; \
#       curl --fail -Lo nodejs.deb https://deb.nodesource.com/node_${NODEJS_MAJOR}.x/pool/main/n/nodejs/nodejs_${NODEJS_VERSION}-deb-1nodesource1_amd64.deb; \
#       echo "${NODEJS_SHA256} *nodejs.deb" | sha256sum -c - >/dev/null 2>&1; \
#       dpkg --install nodejs.deb; \
#       rm -f nodejs.deb; \
#     }; \
#     # ---
#     # Yarn
#     { \
#       export \
#         YARN_VERSION=1.22.19 \
#         YARN_SHA256=666cc8c015bb9e36236fc355816711fbc88bbba97ce8344d3ea2a36debcf7424 \
#       ; \
#       curl --fail -Lo yarn.deb https://github.com/yarnpkg/yarn/releases/download/v${YARN_VERSION}/yarn_${YARN_VERSION}_all.deb; \
#       echo "${YARN_SHA256} *yarn.deb" | sha256sum -c - >/dev/null 2>&1; \
#       dpkg --install yarn.deb; \
#       rm -f yarn.deb; \
#     }; \
#     # smoke tests
#     [ "$(command -v node)" = '/usr/bin/node' ]; \
#     [ "$(command -v yarn)" = '/usr/bin/yarn' ]; \
#     node --version; \
#     yarn --version

# ---
# 7. Install development utilities and common dependencies
#
# TODO: composer
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    cd /tmp; \
    # ---
    # 1. Common dependencies
    # 2. Database clients (PostgreSQL, MariaDB/MySQL)
    { \
        apk add \
            git \
            mariadb-client \
            openssh-client \
            postgresql-client \
            tzdata \
        ; \
    }; \
    # ---
    # Composer (needs 7z, unzip)
    { \
        apk add \
            p7zip \
            unzip \
        ; \
        export \
            COMPOSER_VERSION=2.4.0 \
            COMPOSER_SHA256=1cdc74f74965908d0e98d00feeca37c23b86da51170a3a11a1538d89ff44d4dd; \
        curl --fail -Lo composer.phar https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar; \
        echo "${COMPOSER_SHA256} *composer.phar" | sha256sum -c - >/dev/null 2>&1; \
        chmod +x composer.phar; \
        mv composer.phar /usr/local/bin/composer; \
    }; \
    # ---
    # Overmind (needs tmux)
    { \
        export OVERMIND_VERSION=2.3.0; \
        case "$(arch)" in \
        x86_64) \
            export \
                OVERMIND_ARCH=amd64 \
                OVERMIND_SHA256=d6a715c0810ceb39c94bf61843befebe04a83a0469b53d6af0a52e2fea4e2ab3 \
            ; \
            ;; \
        aarch64) \
            export \
                OVERMIND_ARCH=arm64 \
                OVERMIND_SHA256=ac6bed32200963977e9e14e2b5228c3b1ecd25be3279bfa41c44cdbf555f1217 \
            ; \
            ;; \
        esac; \
        apk add \
            tmux \
        ; \
        curl --fail -Lo overmind.gz https://github.com/DarthSim/overmind/releases/download/v${OVERMIND_VERSION}/overmind-v${OVERMIND_VERSION}-linux-${OVERMIND_ARCH}.gz; \
        echo "${OVERMIND_SHA256} *overmind.gz" | sha256sum -c - >/dev/null 2>&1; \
        gunzip overmind.gz; \
        chmod +x overmind; \
        mv overmind /usr/local/bin/; \
    }; \
    # ---
    # Watchexec
    { \
        export WATCHEXEC_VERSION=1.20.6; \
        case "$(arch)" in \
        x86_64) \
            export \
                WATCHEXEC_ARCH=x86_64 \
                WATCHEXEC_SHA256=6e746704b61d4a2a467546930a837ceef3a4003fc568e574cf6f43a798a4ab00 \
            ; \
            ;; \
        aarch64) \
            export \
                WATCHEXEC_ARCH=aarch64 \
                WATCHEXEC_SHA256=0c9fd0f8013d30330ba0116dd8a4f77060cb55277825ebcc1b2f63aca3dc5d36 \
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
    [ "$(command -v overmind)" = '/usr/local/bin/overmind' ]; \
    [ "$(command -v watchexec)" = '/usr/local/bin/watchexec' ]; \
    overmind --version; \
    watchexec --version
