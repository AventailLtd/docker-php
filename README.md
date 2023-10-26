To enable xdebug

set env PHPSTORM_IP_ADDRESS
set env XDEBUG_ENABLE=1


# php production or developemnt php.ini:

    PHP_PRODUCTION=0

or

    PHP_PRODUCTION=1

Note: it is optional. If you don't set it, no php.ini will be copied (and php defaults will be used)

# Usage:


docker-compose.yml

```
  php:
    image: aventailltd/docker-php:7.4-20211210
    environment:
      XDEBUG_CONFIG: remote_host=${PHPSTORM_IP_ADDRESS}
    expose:
      - 9000
    volumes:
      - "${PROJECT_ROOT}:/var/www/html"
    networks:
      - database
      - server
```

```
docker build -t aventailltd/docker-php:7.4-20211210 .
docker login
...
docker push aventailltd/docker-php:7.4-20211210
```
