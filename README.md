For xdebug set env PHPSTORM_IP_ADDRESS

docker-compose.yml

```
  php:
    image: dblaci/nginx-php-dev:7.2-20190125
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
docker build -t dblaci/nginx-php-dev:temp .
docker login
...
docker push dblaci/nginx-php-dev:7.2-20190125
```
