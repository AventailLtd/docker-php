# for newest, check: https://hub.docker.com/_/php?tab=tags
#FROM php:8.3.2-fpm-bookworm - még nem megy 2024-01-30
FROM php:8.2.23-fpm-bookworm

# log to stdout -> TODO: to nginx too - this is not intentional, but fine for now
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.conf

# Disable access logs.
RUN echo "access.log = /dev/null" >> /usr/local/etc/php-fpm.d/www.conf

ENV DEBIAN_FRONTEND noninteractive
# mssql dpkg - https://github.com/microsoft/mssql-docker/issues/199
ENV ACCEPT_EULA Y

# for apt-key to work!
RUN apt-get update && apt-get install -y -q --no-install-recommends gnupg2 && apt-get clean

# temporary
COPY mssql_pin /etc/apt/preferences.d/microsoft

# pcov.ini
COPY pcov.ini.disabled /usr/local/etc/php/conf.d/pcov.ini.disabled

# sqlsrv - https://laravel-news.com/install-microsoft-sql-drivers-php-7-docker
# msodbcsql18 - https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16#debian18
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    #   && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && curl https://packages.microsoft.com/config/ubuntu/22.10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y -q --no-install-recommends \
    # gosu: run final command as www-data if needed
        gosu \
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
        libwebp-dev \
        libgmp-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
        libzip-dev \
        libmagickwand-dev \
        libxml2-dev \
        libldap-dev \
        libltdl-dev \
        libpq-dev \
        unixodbc-dev \
        msodbcsql18 \
        openssh-client \
        locales \
        libfcgi-bin \
        strace \
        wget \
        # since each run statement creates a new layer, cleaning the cache inside
        # each layer can help reduce image size.
    && apt-get clean

# ffmpeg multimedia package install (https://www.deb-multimedia.org/) - for example the default ffmpeg lib is not containts zscale
RUN echo "deb https://www.deb-multimedia.org bookworm main non-free" >> /etc/apt/sources.list
RUN wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
RUN dpkg -i deb-multimedia-keyring_2016.8.1_all.deb
RUN rm deb-multimedia-keyring_2016.8.1_all.deb
RUN apt update && \
    apt install -y ffmpeg && \
    apt-get clean

# https://stackoverflow.com/questions/27931668/encoding-problems-when-running-an-app-in-docker-python-java-ruby-with-u/27931669
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen && apt-get clean && rm -r /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8

# redis: https://stackoverflow.com/questions/31369867/how-to-install-php-redis-extension-using-the-official-php-docker-image-approach
RUN pecl install sqlsrv pdo_sqlsrv redis imagick pcov && rm -rf /tmp/pear

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    && docker-php-ext-configure gd \
        --with-freetype=/usr/include/ \
        --with-jpeg=/usr/include/ \
        --with-webp=/usr/include/ \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install -j5 ftp iconv pdo_mysql pdo_pgsql zip gmp mysqli gd soap exif intl sockets bcmath ldap pcntl opcache

RUN docker-php-ext-enable sqlsrv pdo_sqlsrv redis imagick

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN pecl install xdebug \
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
RUN usermod -u "$wwwdatauid" www-data

# for componser cache
RUN chown "$wwwdatauid":"$wwwdatauid" /var/www

COPY docker-php-entrypoint /usr/local/bin/docker-php-entrypoint
COPY check_env.sh /usr/local/bin/check_env.sh

# Enable php fpm status page
RUN echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.conf

# Copy healthcheck script
COPY ./php-fpm-healthcheck /usr/local/bin/
