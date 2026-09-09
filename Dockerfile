# for newest, check: https://hub.docker.com/_/php?tab=tags
FROM php:7.4.33-fpm-bullseye

# log to stdout -> TODO: to nginx too - this is not intentional, but fine for now
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.conf

# Disable access logs.
RUN echo "access.log = /dev/null" >> /usr/local/etc/php-fpm.d/www.conf

ENV DEBIAN_FRONTEND noninteractive
# mssql dpkg - https://github.com/microsoft/mssql-docker/issues/199
ENV ACCEPT_EULA Y

# A bullseye (és a bullseye-security) LTS 2026-08-31-én lejárt: a security pool épp ürül
# (404-ek), a Release fájlok Valid-Until-ja lejárt -> az apt az immutable
# archive.debian.org-ról megy, a lejárat-ellenőrzés kikapcsolva.
RUN set -eux; \
    printf '%s\n' \
      'deb http://archive.debian.org/debian bullseye main' \
      'deb http://archive.debian.org/debian bullseye-updates main' \
      > /etc/apt/sources.list; \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

# Friss CA store + openssl: a bullseye main-ben csak a 2021-es (129 root) ca-certificates
# van, a 20250419-es (2025-04-i Mozilla store, 150 root) az arch-független trixie
# csomagból jön. Az upgrade hozza az openssl 1.1.1n -> 1.1.1w-t is.
RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y -q; \
    apt-get install -y -q --no-install-recommends ca-certificates; \
    curl -fsSL https://deb.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20250419_all.deb \
      -o /tmp/ca-certificates.deb; \
    dpkg -i /tmp/ca-certificates.deb; \
    rm /tmp/ca-certificates.deb; \
    update-ca-certificates --fresh

# for apt-key to work!
RUN apt-get update && apt-get install -y -q --no-install-recommends gnupg2

# sqlsrv - https://laravel-news.com/install-microsoft-sql-drivers-php-7-docker
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update

# a libltdl-dev a pecl sqlsrv buildhez kell
RUN apt-get install -y -q --no-install-recommends \
    cron \
    nano \
    procps \
    iputils-ping \
    ffmpeg \
    rsync \
    less \
    pv \
    git \
    msmtp \
    default-mysql-client \
    curl \
    imagemagick \
    zlib1g-dev \
    libpng-dev \
    libgmp-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libmagickwand-dev \
    libxml2-dev \
    libldap-dev \
    libpq-dev \
    libltdl-dev \
    unixodbc-dev \
    msodbcsql18 \
    mssql-tools \
    odbcinst \
    openssh-client \
    locales \
    libfcgi-bin


# https://stackoverflow.com/questions/27931668/encoding-problems-when-running-an-app-in-docker-python-java-ruby-with-u/27931669
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen && apt-get clean && rm -r /var/lib/apt/lists/*

# prestashop elvárja, hogy legyen sendmail command ilyen címen.
RUN ln -s /usr/bin/msmtp /usr/sbin/sendmail

ENV LC_ALL=en_US.UTF-8

# redis: https://stackoverflow.com/questions/31369867/how-to-install-php-redis-extension-using-the-official-php-docker-image-approach
# Verziók pinelve: a pecl "latest" már PHP 8+-t kér és nem esik vissza kompatibilis
# kiadásra, illetve így reprodukálható a dátumos tag.
RUN pecl install redis-6.3.0 imagick-3.8.1

# libltdl.la hiányára workaround
#RUN ln -s /usr/lib/x86_64-linux-gnu/libltdl.so /usr/lib/x86_64-linux-gnu/libltdl.la

RUN pecl install sqlsrv-5.10.1 pdo_sqlsrv-5.10.1 && rm -rf /tmp/pear

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
    docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-configure opcache --enable-opcache && \
    docker-php-ext-install -j5 iconv pdo_mysql pdo_pgsql zip gmp mysqli gd soap exif intl sockets bcmath ldap pcntl opcache

RUN docker-php-ext-enable sqlsrv pdo_sqlsrv redis imagick

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN pecl install xdebug-3.1.6 \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini.disabled \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini.disabled \
    && echo "xdebug.default_enable=0" >> /usr/local/etc/php/conf.d/xdebug.ini.disabled \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini.disabled

#RUN echo "FromLineOverride=YES\n\
#mailhub=mail.icts.hu:465\n\
##hostname=php-fpm.yourdomain.tld\n\
#AuthUser=ysas@asdasdasd\n\
#AuthPass=aaaa\n\
#AuthMethod=LOGIN\n\
#UseTLS=YES\n\
#UseSTARTTLS=YES\n" > /etc/ssmtp/ssmtp.conf
RUN echo "host smtp\nport 25\nadd_missing_from_header on\nfrom dev@dblaci.hu\n" > /etc/msmtprc

COPY msmtp.conf /usr/local/etc/php/conf.d/mail.ini

ARG wwwdatauid=1000
RUN usermod -u $wwwdatauid www-data

# for componser cache
RUN chown 1000:1000 /var/www

COPY docker-php-entrypoint /usr/local/bin/docker-php-entrypoint
COPY check_env.sh /usr/local/bin/check_env.sh

# Enable php fpm status page
RUN echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.conf

# Copy healtcheck script
COPY ./php-fpm-healthcheck /usr/local/bin/
