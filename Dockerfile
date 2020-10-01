# for newest, check: https://hub.docker.com/_/php?tab=tags
FROM php:7.4.10-fpm-buster

# log to stdout -> TODO: to nginx too - this is not intentional, but fine for now
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.conf

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y -q --no-install-recommends \
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
		libxml2-dev \
		openssh-client
RUN apt-get clean && rm -r /var/lib/apt/lists/*

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
    docker-php-ext-install -j3 iconv pdo_mysql zip gmp mysqli gd soap exif intl

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.default_enable=0" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

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
