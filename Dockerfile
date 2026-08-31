ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-apache

# Extensions required by the application and Apache modules used by .htaccess.
RUN docker-php-ext-install mysqli opcache \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && a2enmod rewrite headers \
    && sed -ri 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
    && echo 'ServerName localhost' > /etc/apache2/conf-available/server-name.conf \
    && a2enconf server-name

COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini

WORKDIR /var/www/html
