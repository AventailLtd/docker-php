#!/bin/bash

# change settings before startup based on ENV
if [ "${XDEBUG_ENABLE}" == "1" ]; then
  mv /usr/local/etc/php/conf.d/xdebug.ini.disable /usr/local/etc/php/conf.d/xdebug.ini
fi

if [ "${PHP_PRODUCTION}" == "1" ]; then
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
else
    mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
fi

set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
        set -- php-fpm "$@"
fi

exec "$@"
