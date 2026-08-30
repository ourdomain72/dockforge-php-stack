ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-apache

# Extensions required by the application and Apache modules used by .htaccess.
RUN if ! php -m | grep -qi '^mysqli$'; then docker-php-ext-install mysqli; fi \
    && a2enmod rewrite headers \
    && sed -ri 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf \
    && echo 'ServerName localhost' > /etc/apache2/conf-available/server-name.conf \
    && a2enconf server-name

WORKDIR /var/www/html
