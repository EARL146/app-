FROM php:8.2-cli-alpine

RUN apk add --no-cache oniguruma \
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS oniguruma-dev \
    && docker-php-ext-install pdo_mysql mbstring \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

WORKDIR /app
COPY . /app
USER www-data
EXPOSE 8081
CMD ["php", "-S", "0.0.0.0:8081", "-t", "public", "public/index.php"]
