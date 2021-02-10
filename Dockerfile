#FROM php:7.0-fpm
FROM php:5.6.40-fpm-stretch

# log to stdout -> TODO: to nginx too - this is not intentional, but fine for now
RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.conf

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y -q --no-install-recommends \
		git \
		ssmtp \
#		php5-mysql \
		mysql-client \
		curl \
		imagemagick \
		zlib1g-dev \
                libpng-dev libjpeg62-turbo-dev libgd-dev \
		locales \
		libgmp-dev

# https://stackoverflow.com/questions/27931668/encoding-problems-when-running-an-app-in-docker-python-java-ruby-with-u/27931669
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen && apt-get clean && rm -r /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8

RUN ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h && \
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
  docker-php-ext-install -j3 pdo_mysql mysql zip gmp gd mysqli

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#RUN echo "FromLineOverride=YES\n\
#mailhub=mail.icts.hu:465\n\
##hostname=php-fpm.yourdomain.tld\n\
#AuthUser=ysas@asdasdasd\n\
#AuthPass=aaaa\n\
#AuthMethod=LOGIN\n\
#UseTLS=YES\n\
#UseSTARTTLS=YES\n" > /etc/ssmtp/ssmtp.conf
RUN echo "FromLineOverride=YES\nmailhub=smtp\n" > /etc/ssmtp/ssmtp.conf

COPY ssmtp.conf /usr/local/etc/php/conf.d/mail.ini

#ARG wwwdatauid=1000
#RUN usermod -u $wwwdatauid www-data
