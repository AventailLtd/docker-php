To enable xdebug

set env PHPSTORM_IP_ADDRESS
set env XDEBUG_ENABLE=1

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
