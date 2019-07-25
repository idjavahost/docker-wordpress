FROM    php:5.6-fpm-alpine

LABEL	maintainer="Rizal Fauzie Ridwan <rizal@fauzie.my.id>"

ENV     VIRTUAL_HOST=$DOCKER_HOST \
        HOME=/var/www \
        TZ=Asia/Jakarta \
        PHP_MEMORY_LIMIT=128M \
        REAL_IP_FROM=172.17.0.0/16 \
        SSH_PORT=2222 \
        HTTPS=off \
        USERNAME=wordpress \
        USERGROUP=wordpress \
        INSTALL_YARN=0

RUN     apk add --update --no-cache openssh bash nano htop nginx supervisor nodejs \
        nginx-mod-http-fancyindex nginx-mod-http-headers-more wget git mysql-client \
        curl wget libmcrypt libpng libjpeg-turbo icu-libs gettext libintl && \
        rm /etc/nginx/conf.d/*

RUN     apk add --virtual .build-deps freetype libxml2-dev libpng-dev libjpeg-turbo-dev libwebp-dev zlib-dev \
        libzip-dev gettext-dev icu-dev libxpm-dev libmcrypt-dev make gcc g++ autoconf && \
        docker-php-source extract && \
        echo no | pecl install channel://pecl.php.net/redis-2.2.8 && \
        pecl install xdebug-2.4.1 && \
        docker-php-source delete && \
        docker-php-ext-configure opcache --enable-opcache && \
        docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr && \
        docker-php-ext-install -j$(nproc) gd intl gettext mysqli pdo_mysql soap opcache zip

COPY    /files /

RUN     chmod +x /entrypoint.sh && \
        apk del .build-deps && \
        rm -rf /tmp/*

ENTRYPOINT /entrypoint.sh
