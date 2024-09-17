#!/bin/bash
# change settings before startup based on ENV
# Note: this file is only reasonable with the php-fpm, not the docker run/docker exec mode. So it is running only if the user is root!

if [ "${XDEBUG_ENABLE}" == "1" ]; then
    mv /usr/local/etc/php/conf.d/xdebug.ini.disabled /usr/local/etc/php/conf.d/xdebug.ini
fi

if [ "${PCOV_ENABLE}" == "1" ]; then
    mv /usr/local/etc/php/conf.d/pcov.ini.disabled /usr/local/etc/php/conf.d/pcov.ini
fi

if [ "${PHP_PRODUCTION}" == "1" ]; then
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
elif [ "${PHP_PRODUCTION}" == "0" ]; then
    mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
fi
